from settings import DATASET
from tests.util import is_unique, none_null


def test_unique():
    assert is_unique(f'{DATASET}.wos_citation_counts', 'id')
    assert is_unique(f'{DATASET}.ds_citation_counts', 'id')
    assert is_unique(f'{DATASET}.mag_citation_counts', 'id')
    assert is_unique(f'{DATASET}.all_citation_counts', 'cset_id')


def test_null():
    assert none_null(f'{DATASET}.all_citation_counts', 'cset_id')
    assert none_null(f'{DATASET}.all_citation_counts', 'times_cited')
    assert none_null(f'{DATASET}.all_citation_counts', 'min_times_cited')
