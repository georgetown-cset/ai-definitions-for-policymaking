"""
Our goal here is to understand the overlap and divergence between alternative methods/models using MAG subject
categories, which are available for ~80% of publications.

Result is in Google Sheets:
https://docs.google.com/spreadsheets/d/1ihlvsjrFzIcQpV_lOtEFkuQRyDfZvpUZw0jRYihB9cY/edit#gid=1076167948
"""
from itertools import combinations
from typing import Dict

import pandas as pd

from bq import read_sql

# These are columns in the ``comparison`` table giving predictions as True/False
HIT_COLS = [
    'keyword_hit', 'elsevier_hit', 'arxiv_scibert_hit', 'arxiv_scibert_cl_hit', 'arxiv_scibert_cv_hit',
    'arxiv_scibert_ro_hit', 'arxiv_scibert_not_cv_hit'
]


def compare_all() -> Dict[str, pd.DataFrame]:
    """Compare prediction overlap and divergence between models/methods.
    """
    df = pd.read_gbq(read_sql('../analysis/overlap_by_mag_category.sql'))
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
    df = df.groupby(['mag_subject', a, b], as_index=False).agg({'count': 'sum'})
    comparison = {
        f'{a} and {b}': df.loc[(df[a] == True) & (df[b] == True)].sort_values('count', ascending=False),
        f'{a} not {b}': df.loc[(df[a] == True) & ~(df[b] == True)].sort_values('count', ascending=False),
        f'{b} not {a}': df.loc[(df[b] == True) & ~(df[a] == True)].sort_values('count', ascending=False),
    }
    for k, v in comparison.items():
        comparison[k] = add_percent_col(v)
    return comparison


def add_percent_col(df):
    df['percent'] = (df['count'] / df['count'].sum()).round(3)
    return df


if __name__ == '__main__':
    comparisons = compare_all()
    # Write out to an Excel file for easy upload into Google Sheets
    with pd.ExcelWriter('analysis/overlap_by_mag_category.xlsx') as writer:
        for k, v in comparisons.items():
            # Avoid 'name longer than 31 characters' warning
            sheet_name = k.replace('arxiv_', '')
            v.to_excel(writer, sheet_name=sheet_name, index=False)
