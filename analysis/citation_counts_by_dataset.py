"""
How do citation counts differ across datasets, when a paper appears in more than one dataset?

And how many citation counts are zero, by dataset?

Our motivation is understanding how dataset choice (or aggregation choice) might affect results.
"""
from itertools import permutations
from pathlib import Path

import numpy as np
import pandas as pd

from analysis import write_latest
from bq import read_sql
from settings import PROJECT_ID, DATASET

CITATION_EXPORT_PATH = Path(__file__).parent / 'citation_counts.pkl.gz'
PREDICTION_EXPORT_PATH = Path(__file__).parent / 'predictions.pkl.gz'
DATASET_ABBR = ['mag', 'ds', 'wos']


def summarize_zero_citation_counts() -> None:
    df = pd.read_gbq(read_sql('../analysis/zero_citation_counts_by_dataset.sql'), project_id=PROJECT_ID)
    df['Pct'] = df.groupby('dataset', as_index=False).apply(lambda x: x['count'] / x['count'].sum()).reset_index(
        drop=True)
    df = df.pivot_table(index='has_zero_citations', columns='dataset')
    write_latest(df, 'analysis/zero_citation_counts_by_dataset.csv', index=True)


def summarize_citation_count_differences() -> None:
    if CITATION_EXPORT_PATH.exists():
        df = pd.read_pickle(CITATION_EXPORT_PATH, compression='gzip')
    else:
        df = pd.read_gbq(read_sql('../analysis/citation_count_export.sql'), project_id=PROJECT_ID)
        df.to_pickle(CITATION_EXPORT_PATH, compression='gzip')

    # Join in SciBERT predictions
    if PREDICTION_EXPORT_PATH.exists():
        hits = pd.read_pickle(PREDICTION_EXPORT_PATH, compression='gzip')
    else:
        hits = pd.read_gbq(f'select cset_id from {DATASET}.comparison where arxiv_scibert_hit is true', project_id=PROJECT_ID)
        hits.to_pickle(PREDICTION_EXPORT_PATH, compression='gzip')
    hits['scibert_hit'] = True
    assert not hits['cset_id'].duplicated().any()
    assert not df['cset_id'].duplicated().any()
    df = pd.merge(df, hits, on='cset_id', how='left')
    df['scibert_hit'] = df['scibert_hit'].fillna(False)

    for a, b in permutations(DATASET_ABBR, 2):
        df[f'{a}_{b}_diff'] = df[f'{a}_times_cited'] - df[f'{b}_times_cited']
        df[f'{a}_{b}_diff_pct'] = df[f'{a}_{b}_diff'] / df[f'{b}_times_cited']
    percentiles = calculate_percentiles(df)
    write_latest(percentiles, 'analysis/citation_count_pct_diff_quantiles.csv', index=True)
    zero_diff_counts = count_zeroes(df)
    write_latest(zero_diff_counts, 'analysis/citation_zero_diff_counts.csv', index=True)
    ai_percentiles = calculate_percentiles(df.query('scibert_hit == True'))
    write_latest(ai_percentiles, 'analysis/ai_citation_count_pct_diff_quantiles.csv', index=True)
    ai_zero_diff_counts = count_zeroes(df.query('scibert_hit == True'))
    write_latest(ai_zero_diff_counts, 'analysis/ai_citation_zero_diff_counts.csv', index=True)
    ai_percent_greater = calculate_percent_greater(df.query('scibert_hit == True'))
    write_latest(ai_percent_greater, 'analysis/ai_citation_percent_greater_counts.csv', index=False)


def iter_diff_pct_cols():
    for a, b in permutations(DATASET_ABBR, 2):
        yield f'{a}_{b}_diff_pct'


def calculate_percent_greater(df):
    pct_greater = {}
    for k in ['mag_ds_diff', 'mag_wos_diff', 'ds_wos_diff']:
        # Drop null differences to restrict to papers for which we observe citation counts in both datasets
        is_positive = df[k].dropna() > 0
        counts = is_positive.value_counts()
        pct_greater[k] = \
        pd.DataFrame({'count_greater': counts, 'pct': counts / counts.sum(), 'total': counts.sum()}).loc[True]
    pct_greater = pd.concat(pct_greater).reset_index()
    pct_greater = pct_greater.pivot_table(index='level_0', columns='level_1').reset_index()
    pct_greater.columns = ['datasets', 'count_greater', 'pct_greater', 'total']
    pct_greater['datasets'] = pct_greater['datasets'].str.replace('_diff', '').str.replace('_', ' > ').str.upper()
    for k in ['count_greater', 'total']:
        pct_greater[k] = pct_greater[k].astype(int)
    return pct_greater


def calculate_percentiles(df, q=(.05, .25, .5, .75, .95)):
    df = pd.DataFrame({k: df[k].abs().replace([np.inf, -np.inf], np.nan).quantile(q) for k in iter_diff_pct_cols()})
    df = df.transpose()
    return df


def count_zeroes(df):
    zeroes = {}
    for k in ['mag_ds_diff', 'mag_wos_diff', 'ds_wos_diff']:
        counts = (df[k] == 0).value_counts().astype(float)
        zeroes[k] = (counts / counts.sum())[True].astype(float)
    return pd.DataFrame.from_dict(zeroes, orient='index').rename(columns={0: 'pct'})


if __name__ == '__main__':
    summarize_zero_citation_counts()
    summarize_citation_count_differences()
