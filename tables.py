"""
Create tables for analysis.

Each table is defined by a SQL file in the `sql` directory.

Requires GCP credentials, either user or application default. First try configuring nothing, and if you see
``UserWarning: Your application has authenticated using end user credentials from Google Cloud SDK``, you're all set. We
aren't making enough API requests for user credentials to be an issue.
"""
import argparse

import pandas as pd

from bq import create_client, make_table, make_ntile_table
from settings import DATASET, CITATION_PERCENTILES

client = create_client()


def make_country_tables(truncate=False):
    """Make tables giving author affiliation countries.

    We do this for each data source independently (DS, WOS, and MAG), then combine the results in an
    ``all_countries`` table.

    :param truncate: If True, overwrite tables that exist.
    :return: None
    """
    # Load manual country labels for DS
    ds_country_codes = pd.read_csv('data/input/ds-country-codings.csv')
    ds_country_codes.to_gbq(f'{DATASET}.ds_country_codings', if_exists='replace', project_id=client.project)
    make_table('ds_countries', truncate)
    make_table('wos_countries', truncate)
    make_table('mag_countries', truncate)
    make_table('all_countries', truncate)


def make_arxiv_tables(truncate=False):
    """Make arXiv subject coverage tables.

    By arXiv subject coverage, we mean whether arXiv includes any papers about a subject defined by a dataset.

    We do this for each data source independently (DS, WOS, and MAG), then combine the results in an
    ``all_arxiv_categories`` table.

    :param truncate: If True, overwrite tables that exist.
    :return: None
    """
    make_table('wos_arxiv_categories', truncate)
    make_table('ds_arxiv_categories', truncate)
    make_table('mag_arxiv_categories', truncate)
    make_table('all_arxiv_categories', truncate)


def make_result_tables(truncate=False):
    """Make tables giving results from alternative methods/models.

    There are three methods: CSET keywords, Elsevier's keyword-classifier hybrid, and CSET's SciBERT models. There
    are four SciBERT models: any-subject / all AI, CV, NLP, and robotics.

    For each SciBERT models, we report two results: with and without a requirement that only papers with a subject we
    consider covered by arXiv (see ``make_arxiv_tables``) can be predicted relevant.

    :param truncate: If True, overwrite tables that exist.
    :return: None
    """
    make_table('keyword_results', truncate)
    make_table('elsevier_results', truncate)
    make_table('scibert_results', truncate)
    make_table('category_results', truncate)
    make_table('mag_ai', truncate)
    make_table('all_predictions', truncate)


def make_overlap_tables(truncate=False):
    """Make final overlap tables.

    These tables describe overlap between positive/negative predictions by method/model, for Venn diagrams in analysis.

    :param truncate: If True, overwrite tables that exist.
    :return: None
    """
    make_table('summary', truncate)
    # The same, but for publications in the top percentile - see comments in SQL for implementation notes
    make_table('summary_1pct', truncate)
    make_table('summary_arxiv_1pct', truncate)
    make_table('summary_arxiv_1pct_min', truncate)


def make_country_share_tables(truncate=False):
    """Make final country share tables.

    The ``country_share_`` tables describe the proportion of articles produced by country-affiliated authors for the
    EU, US, or China (exclusively), vs. any other country/countries. Restricted by citation percentile.

    :param truncate: If True, overwrite tables that exist.
    :return: None
    """
    for x in CITATION_PERCENTILES:
        make_ntile_table(x, truncate)
        make_ntile_table(x, truncate, sql_path='country_share_arxiv_coverage_template', table_suffix='_arxiv')
    make_ntile_table(100, truncate, sql_path='country_share_min_percentile_template', table_suffix='_arxiv_min')
    for dataset in ['ds', 'mag', 'wos']:
        make_ntile_table(100, truncate, sql_path=f'country_share_template_{dataset}', table_suffix=f'_{dataset}')
    make_table('country_shares', truncate)


def make_comparison_table(truncate=False):
    """Make (publication) comparison table.

    The ``comparison`` table gives for each publication in the analysis the results from each alternative method/model.

    :param truncate: If True, overwrite table that exists.
    :return: None
    """
    make_table('comparison', truncate)


def make_ancillary_tables(truncate=False):
    """Make ancillary tables addressing questions we have about the data or validity.

    :param truncate: If True, overwrite tables that exist.
    :return: None.
    """
    # What is each dataset's coverage of arXiv?
    make_table('dataset_arxiv_coverage', truncate)
    # Which/how many publications do we observe only in MAG? For affiliation country availability (see analysis folder)
    make_table('mag_only', truncate)
    # Which papers in MAG have AI-plausible subject categories?
    make_table('dataset_overlap', truncate)
    make_table('dataset_overlap_by_prediction', truncate)
    make_table('citations_by_dataset', truncate)
    make_table('mag_subfield_scores', truncate)
    make_table('mag_replication', truncate)


def make_citation_count_tables(truncate=False) -> None:
    """Make citation count tables.

    :param truncate: If True, overwrite tables that exist.
    :return: None.
    """
    make_table('wos_citation_counts', truncate)
    make_table('ds_citation_counts', truncate)
    make_table('mag_citation_counts', truncate)
    make_table('all_citation_counts', truncate)


def make_all(truncate=False) -> None:
    """Write query results to tables.

    :param truncate: If True, overwrite tables that exist.
    """
    make_table('en_2010_2020', truncate)
    make_table('cset_ids', truncate)
    make_table('wide_ids', truncate)
    make_citation_count_tables(truncate)
    make_country_tables(truncate)
    make_arxiv_tables(truncate)
    make_table('all_years', truncate)
    make_result_tables(truncate)
    make_table('ds_percentiles', truncate)
    make_table('mag_percentiles', truncate)
    make_table('wos_percentiles', truncate)
    make_table('percentiles', truncate)
    make_table('min_percentiles', truncate)
    make_table('all_categories', truncate)
    make_table('category_results', truncate)
    make_comparison_table(truncate)
    make_country_share_tables(truncate)
    make_overlap_tables(truncate)
    make_ancillary_tables(truncate)
    make_table('mag_ai_fields_of_study', truncate)
    make_table('mag_ai_fields_overlap', truncate)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--truncate', '-t', action='store_true')
    args = parser.parse_args()
    make_all(truncate=args.truncate)
