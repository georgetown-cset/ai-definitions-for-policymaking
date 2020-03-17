from settings import DATASET
from tests.util import is_unique


def test_unique_ds():
    assert is_unique(f'{DATASET}.ds_arxiv_categories', 'id')


def test_unique_mag():
    assert is_unique(f'{DATASET}.mag_arxiv_categories', 'cset_id')


def test_unique_wos():
    assert is_unique(f'{DATASET}.wos_arxiv_categories', 'id')


def test_unique_arxiv():
    assert is_unique(f'{DATASET}.all_arxiv_categories', 'cset_id')


def test_unique_all():
    assert is_unique(f'{DATASET}.all_categories', 'cset_id')
