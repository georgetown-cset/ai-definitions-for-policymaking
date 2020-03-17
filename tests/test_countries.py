from pathlib import Path

import pandas as pd
import pytest

from settings import DATASET


@pytest.fixture
def ds_count() -> int:
    df = pd.read_gbq(f"""\
        select count(distinct source_id) as n
        from {DATASET}.cset_ids
        where source_dataset = 'ds'
        """, project_id='gcp-cset-projects')
    return df['n'].values[0]


@pytest.fixture
def ds_coding_csv() -> pd.DataFrame:
    path = Path(__file__).parent / '../data/input/ds-country-codings.csv'
    _ds_codings = pd.read_csv(path)
    return _ds_codings


@pytest.fixture
def ds_coding() -> pd.DataFrame:
    coding = pd.read_gbq(
        f"""\
        select *
        from {DATASET}.ds_country_codings 
        """, project_id='gcp-cset-projects')
    return coding


@pytest.fixture
def ds_countries() -> pd.DataFrame:
    _ds_countries = pd.read_gbq(
        f"""\
        select distinct country 
        from {DATASET}.cset_gold_all_dimensions_publications_20200224 
        where country is not null
        order by 1
        """, project_id='gcp-cset-projects')
    return _ds_countries


@pytest.fixture
def ds_country_counts() -> pd.DataFrame:
    df = pd.read_gbq(
        f"""\
        select us_affiliation, china_affiliation, eu_affiliation, count(*) as n
        from {DATASET}.ds_countries 
        group by 1, 2, 3
        """, project_id='gcp-cset-projects')
    return df


def test_distinct():
    df = pd.read_gbq(
        f"""\
        select 
            count(*) as count,
            count(distinct id) as count_distinct
        from {DATASET}.ds_countries 
        """, project_id='gcp-cset-projects')
    assert df.loc[0, 'count'] == df.loc[0, 'count_distinct']


def test_ds_coding_schema(ds_coding_csv) -> None:
    assert (ds_coding_csv.columns == ['country', 'eu', 'usa', 'china']).all()
    assert ds_coding_csv.country.dtype == 'O'
    for col in ['eu', 'usa', 'china']:
        assert ds_coding_csv[col].dtype == 'bool'


def test_ds_country_coverage(ds_countries, ds_coding_csv) -> None:
    """All non-null countries in DS should appear in the DS country coding table."""
    assert ds_countries['country'].isin(ds_coding_csv['country']).all()


def test_ds_codings(ds_countries, ds_coding_csv) -> None:
    # The 27 EU countries should be coded as EU countries in the country coding table
    assert ds_coding_csv.loc[ds_coding_csv['eu'], 'country'].shape[0] == 27
    # Values are already canonicalized so there's only 1 USA-coded or China-coded value. Unlike in WOS,
    # where everything is a mess
    assert (ds_coding_csv.loc[ds_coding_csv['usa'], 'country'] == 'United States').all()
    assert (ds_coding_csv.loc[ds_coding_csv['china'], 'country'] == 'China').all()


def test_ds_counts(ds_country_counts, ds_count) -> None:
    # DS articles are associated with an expected country affiliation value
    for col in ['us_affiliation', 'china_affiliation', 'eu_affiliation']:
        assert ds_country_counts[col].isin([True, False]).all()
    assert ds_country_counts['n'].sum() == ds_count


def test_country_agreement():
    pass
