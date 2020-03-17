import pandas as pd
import pytest

from settings import DATASET
from tests.util import is_unique

START_YEAR = 2010
END_YEAR = 2020
YEARS = range(START_YEAR, END_YEAR + 1)


@pytest.fixture
def counts():
    df = pd.read_gbq(f"""\
        select 
            year, 
            country, 
            arxiv_coverage, 
            count(*) 
        from {DATASET}.comparison
        group by 1, 2, 3
    """, project_id='gcp-cset-projects')
    return df


def test_unique_id():
    is_unique(f'{DATASET}.comparison', 'cset_id')


def test_years(counts):
    assert counts['year'].isin(YEARS).all()
    for year in YEARS:
        assert year in set(counts['year'])


def test_arxiv_coverage(counts):
    assert counts['arxiv_coverage'].isin([True, False]).all()
    counts['arxiv_coverage'] = counts['arxiv_coverage'].fillna('NULL')
    counts = counts.groupby('arxiv_coverage').agg({'f0_': sum}).rename(columns={'f0_': 'count'})
    counts


def test_countries(counts):
    assert not counts['country'].isna().any()
    counts['country'] = counts['country'].fillna('NULL')
    country_counts = counts.groupby('country').agg({'f0_': sum}).rename(columns={'f0_': 'count'})
    country_counts['count'].sum()
