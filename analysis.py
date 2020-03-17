"""
Run analysis.

Requires:
    1. GCP credentials, either user or application default;
    2. First running `tables.py` to create the BQ tables the analysis code uses.

Each output is written to the `analysis` folder twice: suffixed with a timestamp and with `_latest`.
"""

import datetime
from itertools import combinations
from pathlib import Path
from typing import Union

import numpy as np
import pandas as pd

from settings import DATASET, OUTPUT_DIR, PROJECT_ID, CITATION_PERCENTILES
from viz import plot_country_shares


def main() -> None:
    """Run queries to produce the analysis.
    """
    # What is each dataset's coverage of arXiv?
    arxiv = pd.read_gbq(f'select * from {DATASET}.dataset_arxiv_coverage', project_id='gcp-cset-projects')
    write_latest(arxiv, OUTPUT_DIR / 'arxiv_coverage.csv')

    for x in CITATION_PERCENTILES:
        for arxiv_only in [True, False]:
            table = f'country_share_{x - 1}th{"_arxiv" if arxiv_only else ""}'
            df = pd.read_gbq(f'select * from {DATASET}.{table}', project_id='gcp-cset-projects')
            write_latest(df, OUTPUT_DIR / f'{table}.csv')
            plot_country_shares(df, OUTPUT_DIR / f'{table}.png')
    country_share_min = pd.read_gbq(f'select * from {DATASET}.country_share_99th_arxiv_min',
                                    project_id='gcp-cset-projects')
    write_latest(country_share_min, OUTPUT_DIR / f'country_share_99th_arxiv_min.csv')
    plot_country_shares(country_share_min, OUTPUT_DIR / f'country_share_99th_arxiv_min.png')
    # Without any citation threshold for inclusion
    country_shares = pd.read_gbq(f'select * from {DATASET}.country_shares', project_id='gcp-cset-projects')
    write_latest(country_shares, OUTPUT_DIR / f'country_shares.csv')
    plot_country_shares(country_shares, OUTPUT_DIR / f'country_shares.png')
    # DS/MAG/WOS only
    for dataset in ['ds', 'mag', 'wos']:
        dataset_country_shares = pd.read_gbq(f'select * from {DATASET}.country_share_99th_{dataset}',
                                             project_id=PROJECT_ID)
        write_latest(dataset_country_shares, OUTPUT_DIR / f'country_shares_{dataset}.csv')
        plot_country_shares(dataset_country_shares, OUTPUT_DIR / f'country_shares_{dataset}.png')

    df = pd.read_gbq(f'select * from {DATASET}.mag_replication', project_id='gcp-cset-projects')
    df = df.query('country != "Other"')
    import plotly.express as px
    fig = px.line(df, x='Year', y='proportion', color='country', range_y=(0, .5))
    fig.show()

    # Summarize overlap between predictions by method
    overlap_counts = calculate_overlap('summary')
    write_latest(overlap_counts, OUTPUT_DIR / 'overlap_counts.csv')
    overlap_1pct_counts = calculate_overlap('summary_1pct', columns=[
        'keyword_hit', 'elsevier_hit', 'subject_hit', 'arxiv_scibert_hit', 'arxiv_scibert_cl_hit',
        'arxiv_scibert_cv_hit', 'arxiv_scibert_ro_hit'])
    write_latest(overlap_1pct_counts, OUTPUT_DIR / 'overlap_arxiv_99th_counts.csv')
    overlap_arxiv_1pct_min_counts = calculate_overlap('summary_arxiv_1pct_min')
    write_latest(overlap_arxiv_1pct_min_counts, OUTPUT_DIR / 'overlap_arxiv_99th_min_counts.csv')

    # Assess divergence between methods/models by subject
    # Keyword hits alone
    kw_only_subjects = pd.read_gbq(f'select wos_subject, ds_subject, mag_subject, count(*) as count '
                                   f'from {DATASET}.comparison '
                                   f'where keyword_hit is true and elsevier_hit is false and scibert_hit is false '
                                   f'group by 1, 2, 3 '
                                   f'order by 4 desc',
                                   project_id='gcp-cset-projects')
    write_latest(kw_only_subjects, OUTPUT_DIR / 'divergence_subjects_keywords.csv')
    # Elsevier alone
    elsevier_only_subjects = pd.read_gbq(f'select wos_subject, ds_subject, mag_subject, count(*) as count '
                                         f'from {DATASET}.comparison '
                                         f'where keyword_hit is false and elsevier_hit is true and scibert_hit is false '
                                         f'group by 1, 2, 3 '
                                         f'order by 4 desc',
                                         project_id='gcp-cset-projects')
    write_latest(elsevier_only_subjects, OUTPUT_DIR / 'divergence_subjects_elsevier.csv')
    # SciBERT hits alone
    scibert_only_subjects = pd.read_gbq(f'select wos_subject, ds_subject, mag_subject, count(*) as count '
                                        f'from {DATASET}.comparison '
                                        f'where keyword_hit is false and elsevier_hit is false and scibert_hit is true '
                                        f'group by 1, 2, 3 '
                                        f'order by 4 desc',
                                        project_id='gcp-cset-projects')
    write_latest(scibert_only_subjects, OUTPUT_DIR / 'divergence_subjects_scibert.csv')
    # SciBERT hits alone with arXiv coverage
    arxiv_scibert_only_subjects = pd.read_gbq(f'select wos_subject, ds_subject, mag_subject, count(*) as count '
                                              f'from {DATASET}.comparison '
                                              f'where keyword_hit is false and elsevier_hit is false and arxiv_scibert_hit is true '
                                              f'group by 1, 2, 3 '
                                              f'order by 4 desc',
                                              project_id='gcp-cset-projects')
    write_latest(arxiv_scibert_only_subjects, OUTPUT_DIR / 'divergence_subjects_arxiv_scibert.csv')

    mag_ai = calculate_overlap('mag_ai_fields_overlap', columns=['has_mag_id', 'mag_ai_hit', 'arxiv_scibert_hit'])
    mag_ai['label'] = mag_ai['label'].str.replace('Has_Mag_Id', 'MAG')
    mag_ai['label'] = mag_ai['label'].str.replace('Mag_Ai', 'MAG AI')
    mag_ai['label'] = mag_ai['label'].str.replace('Arxiv_Scibert', 'SciBERT')
    write_latest(mag_ai, OUTPUT_DIR / 'mag_ai_overlap.csv')

    # Ancillary table: summarize overlap across datasets
    dataset_overlap = calculate_overlap('dataset_overlap', columns=['in_wos', 'in_ds', 'in_mag'])
    dataset_overlap['label'] = dataset_overlap['label'].str.replace('In_', '').str.upper()
    write_latest(dataset_overlap, OUTPUT_DIR / 'dataset_overlap.csv')

    # Summarize overlap across datasets, by whether articles were predicted positive by SciBERT
    do_scibert = calculate_overlap('dataset_overlap_by_prediction',
                                   columns=['scibert_hit', 'in_wos', 'in_ds', 'in_mag'])
    # This requires some cleanup, because calculate_overlap wasn't written to do overlap + group-by
    do_scibert['label'] = do_scibert['label'].str.replace('In_', '').str.upper()
    do_scibert['label'] = do_scibert['label'].str.replace('SCIBERT . ', '').str.upper()
    do_scibert = do_scibert.query("label != 'SCIBERT'")
    do_scibert = do_scibert.pivot_table(index=['label', 'in_ds', 'in_wos', 'in_mag'], columns='scibert_hit')
    do_scibert = do_scibert.sort_values(['in_wos', 'in_ds', 'in_mag'])
    # Recalculate percentages calculate_overlap did cell count / n, but we want column percentages for easy comparison
    # of overlap between positive and negative predictions
    for pred in [True, False]:
        do_scibert[('Pct', pred)] = do_scibert[('Count', pred)] / do_scibert[('Count', pred)].sum()
    write_latest(do_scibert, OUTPUT_DIR / 'dataset_overlap_by_prediction.csv', index=True)


def calculate_overlap(table: str, dataset=DATASET,
                      columns=('keyword_hit', 'elsevier_hit', 'scibert_hit', 'subject_hit')) -> pd.DataFrame:
    """
    Calculate overlap across methods/models from a ``summary`` table.

    :param table: Summary table name.
    :param dataset: Summary table dataset.
    :return: DataFrame of counts.
    """
    df = pd.read_gbq(f'select * from {dataset}.{table}', project_id=PROJECT_ID)
    df = df[list(columns) + ['count']].groupby(list(columns), as_index=False).agg({'count': 'sum'})
    counts = []
    # Chose each 1 to all from the columns at a time
    for i in range(1, len(columns) + 1):
        for true_cols in combinations(columns, i):
            q = " and ".join(true_cols)
            false_cols = set(columns) - set(true_cols)
            if false_cols:
                q += " and not " + " and not ".join(false_cols)
            # Clean up the column names for labels
            counts.append(dict(label=" ∩ ".join([col.replace('_hit', '').title() for col in true_cols]),
                               **{k: True for k in true_cols},
                               **{k: False for k in false_cols},
                               Count=df.query(q)['count'].sum()))
    df = pd.DataFrame(counts)
    df['Pct'] = df['Count'] / df['Count'].sum()
    return df


def write_latest(df: pd.DataFrame, path: Union[str, Path], index=False) -> None:
    if not isinstance(path, Path):
        path = Path(path)
    timestamp = datetime.datetime.now().strftime('%Y-%m-%d-%H.%M.%S')
    latest_path = path.parent / f'{path.stem}_latest{path.suffix}'
    ts_path = path.parent / f'{path.stem}_{timestamp}{path.suffix}'
    df.to_csv(ts_path, index=index)
    if latest_path.exists():
        print(f'Replacing existing {latest_path.name}')
        last = pd.read_csv(latest_path)
        df_numeric = df.select_dtypes(include=np.number)
        last_numeric = last.select_dtypes(include=np.number)
        if df.shape[0] == last.shape[0] and df.shape[1] == last.shape[1]:
            diff = df_numeric - last_numeric
            diff_cols = diff[[col for col in diff.columns if not np.allclose(diff[col], 0)]]
            if diff_cols.shape[1] > 0:
                print(f'{diff_cols.shape[1]} column(s) with non-zero differences')
                diff_path = ts_path.parent / f'{ts_path.stem}_diff{ts_path.suffix}'
                diff_cols.to_csv(diff_path, index=index)
                print(f'Wrote diff to {diff_path.name}')
        else:
            print(f'Last file has different shape {last.shape} than replacement {df.shape}')
    df.to_csv(latest_path, index=index)


if __name__ == '__main__':
    main()
