from tests.util import is_unique
from settings import DATASET


def test_unique():
    # Each row gives a cset_id, source_id pair, and we expect the source_ids to be unique
    assert is_unique(f'{DATASET}.cset_ids', 'source_id')
    assert is_unique(f'{DATASET}.wide_ids', 'cset_id')

