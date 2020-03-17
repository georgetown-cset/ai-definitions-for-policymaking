import pandas as pd

from settings import PROJECT_ID, DATASET
from tests.util import is_unique, none_null


def test_unique():
    # Each row gives a cset_id, source_id pair, and we expect the source_ids to be unique
    assert is_unique(f'{DATASET}.percentiles', 'cset_id')
    assert none_null(f'{DATASET}.percentiles', 'cset_id')
    assert none_null(f'{DATASET}.percentiles', 'year')


def test_bins():
    df = pd.read_gbq(f"""\
        select year, 
            scibert_percentile, 
            min(times_cited) min_times_cited, 
            max(times_cited) max_times_cited 
            from {DATASET}.percentiles 
            group by 1, 2 
            order by 1, 2""", project_id=PROJECT_ID)
    assert (df['min_times_cited'] <= df['max_times_cited']).all()
