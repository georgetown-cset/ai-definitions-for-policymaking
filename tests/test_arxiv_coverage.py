import pandas as pd

from settings import DATASET


def test_nonmissing():
    for prefix in ['ds', 'mag', 'wos', 'all']:
        df = pd.read_gbq(f'select distinct arxiv_coverage from {DATASET}.{prefix}_arxiv_categories',
                         project_id='gcp-cset-projects')
        assert df['arxiv_coverage'].isin([True, False]).all()
