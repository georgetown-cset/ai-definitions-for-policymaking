"""
As in ``overlap_by_mag_category``, our goal here is to understand the overlap and divergence between alternative
methods/models. Here instead of top-level MAG subject categories (FieldsOfStudy), we're using MAG's lower-level subject
categories.

Result is in Google Sheets.
"""
from itertools import combinations
from pathlib import Path
from typing import Dict

import pandas as pd

from bq import read_sql
from settings import PROJECT_ID, DATASET

# These are columns in the ``comparison`` table giving predictions as True/False
# HIT_COLS = [
#     'keyword_hit', 'elsevier_hit', 'arxiv_scibert_hit', 'arxiv_scibert_cl_hit', 'arxiv_scibert_cv_hit',
#     'arxiv_scibert_ro_hit', 'arxiv_scibert_not_cv_hit'
# ]

HIT_COLS = [
    'keyword', 'elsevier', 'scibert', 'scibert_cl', 'scibert_cv', 'scibert_ro', 'scibert_not_cv'
]


def abbreviate_columns(df):
    df = df.rename(columns=lambda x: x.replace('_hit', ''))
    df = df.rename(columns=lambda x: x.replace('arxiv_', ''))
    return df


ANALYSIS_DIR = Path(__file__).parent


def compare_all(df) -> Dict[str, pd.DataFrame]:
    """Compare prediction overlap and divergence between models/methods.
    """
    comparisons = {}
    for a, b in combinations(HIT_COLS, 2):
        comparisons.update(**compare_hits(df, a, b))
    return comparisons


def compare_hits(df: pd.DataFrame, a: str, b: str):
    """Compare prediction overlap and divergence between models/methods.

    :param df: DataFrame giving MAG category frequencies grouped by model/method hit (True/False).
    :param a: Column in ``df`` indicating True/False for hits.
    :param b: Column in ``df`` indicating True/False for hits.
    :return: MAG category frequency tables for each of A and B, A not B, and B not A.
    """
    df = df.copy()
    # We want the average score for each subfield, but have the average score by subfield and prediction combination, so
    # take the count-weighted average over prediction combinations to get the average subfield score.
    df = df.groupby(['level0_level1_name', a, b], as_index=False).apply(_weight_average)
    df = df.reset_index()
    comparison = {
        f'{a} and {b}': df.loc[(df[a] == True) & (df[b] == True)].sort_values('count', ascending=False),
        f'{a} not {b}': df.loc[(df[a] == True) & ~(df[b] == True)].sort_values('count', ascending=False),
        f'{b} not {a}': df.loc[(df[b] == True) & ~(df[a] == True)].sort_values('count', ascending=False),
    }
    for k, v in comparison.items():
        comparison[k] = v.sort_values('count', ascending=False)
    return comparison


def summarize_predictions(df: pd.DataFrame) -> Dict[str, pd.DataFrame]:
    """For each model/method, for each MAG subfield, give the article count and average article score by whether the
    prediction was positive or negative.
    """
    summaries = {}
    df = df.copy()
    for col in HIT_COLS:
        hit_summary = df.groupby(['level0_level1_name', col], as_index=False).apply(_weight_average)
        hit_summary = hit_summary.reset_index()
        hit_summary = hit_summary.pivot_table(index='level0_level1_name', columns=col,
                                              values=['average_score', 'count'])
        for pred in [True, False]:
            hit_summary[('count', pred)] = hit_summary[('count', pred)].fillna(0.0).astype(int)
        hit_summary = hit_summary.sort_values(('count', True), ascending=False)
        summaries[col] = hit_summary
    return summaries


def _weight_average(x):
    """Take the weighted average of scores.
    https://stackoverflow.com/a/54807274
    """
    names = {
        'average_score': ((x['average_score'] * x['count']).sum() / x['count'].sum()).round(4),
        'count': x['count'].sum()
    }
    return pd.Series(names, index=['average_score', 'count'])


def adjust_column_width(sheet_df: pd.DataFrame, _writer, _sheet_name: str, index=True) -> None:
    """Adjust the width of the first column in the sheet to fit its largest value.
    https://stackoverflow.com/a/40535454
    """
    worksheet = _writer.sheets[_sheet_name]
    if index:
        width = sheet_df.index.astype(str).map(len).max()
    else:
        width = sheet_df.iloc[:, 0].astype(str).map(len).max()
    # worksheet.set_column(0, 0, width + 1)
    workbook = _writer.book
    format_left = workbook.add_format({'align': 'left', 'bold': False})
    worksheet.set_column(0, 0, width=width + 1, cell_format=format_left)


if __name__ == '__main__':
    subfield_n = pd.read_gbq(
        f'select level0_level1_name, count(*) subfield_size from {DATASET}.mag_subfield_scores group by 1',
        project_id=PROJECT_ID)
    # read_sql() paths are relative to SQL_DIR. Assume here that SQL_DIR is a sibling of ANALYSIS_DIR
    df = pd.read_gbq(read_sql(Path('..') / ANALYSIS_DIR / 'predictions_by_mag_subfield.sql'), project_id=PROJECT_ID)
    df = abbreviate_columns(df)
    # Add to comparison tables the proportion of all the articles (in our analysis scope) in a subfield that each count
    # represents
    comparisons = compare_all(df)
    for k, v in comparisons.items():
        v = pd.merge(v, subfield_n, on='level0_level1_name', how='inner')
        v['subfield_proportion'] = (v['count'] / v['subfield_size']).round(4)
        comparisons[k] = v
    summaries = summarize_predictions(df)
    # Do the same for summary tables, for the proportion of all articles in a subfield that the positive predictions
    # represent. Summary dataframes have a two-level column index, so we adjust the subfield_n dataframe to match
    # https://stackoverflow.com/a/43223675
    subfield_n = subfield_n.set_index('level0_level1_name')
    subfield_n.columns = pd.MultiIndex.from_product([['count'], subfield_n.columns])
    for k, v in summaries.items():
        v = pd.merge(v, subfield_n, left_on='level0_level1_name', right_index=True, how='inner')
        v['subfield_proportion_true'] = (v[('count', True)] / v[('count', 'subfield_size')]).round(4)
        summaries[k] = v
    # Write out to an Excel file for easy upload into Google Sheets
    with pd.ExcelWriter(ANALYSIS_DIR / 'predictions_by_mag_subfield.xlsx', engine='xlsxwriter') as writer:
        for k, v in summaries.items():
            # Try to avoid 'name longer than 31 characters' warning
            sheet_name = k.replace('arxiv_scibert_', '')
            v.to_excel(writer, sheet_name=sheet_name, index=True)
            adjust_column_width(v, writer, sheet_name, index=True)
        for k, v in comparisons.items():
            sheet_name = k.replace('arxiv_scibert_', '')
            v.to_excel(writer, sheet_name=sheet_name, index=False)
            adjust_column_width(v, writer, sheet_name, index=False)
