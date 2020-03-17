import time

import pandas as pd
import pytest

from analysis import write_latest


@pytest.fixture
def csv_path(tmp_path):
    return tmp_path / 'test.csv'


@pytest.fixture
def df():
    return pd.DataFrame({'a': [1, 2], 'b': [3, 4]})


@pytest.fixture
def df_prime():
    return pd.DataFrame({'a': [2, 1], 'b': [3, 4]})


@pytest.fixture
def df_floats():
    return pd.DataFrame({'a': [.1, .2], 'b': [.3, .4]})


def test_write_latest(df, csv_path):
    write_latest(df, csv_path)
    output_paths = list(csv_path.parent.glob('*.csv'))
    # Expect 2 output files
    assert len(output_paths) == 2
    # Expect 1 timestamped CSV and 1 suffixed "_latest.csv"
    assert len([x for x in output_paths if x.name.endswith('test_latest.csv')]) == 1


def test_overwrite(df, csv_path, capsys):
    write_latest(df, csv_path)
    time.sleep(1)
    write_latest(df, csv_path)
    captured = capsys.readouterr()
    assert captured.out.startswith('Replacing existing test_latest.csv\n')
    # Expect 3 outputs on the disk, 2 timestamped and 1 suffixed _latest
    assert len(list(csv_path.parent.glob('*.csv'))) == 3


def test_diff(df, df_prime, csv_path, capsys):
    write_latest(df, csv_path)
    time.sleep(1)
    write_latest(df_prime, csv_path)
    captured = capsys.readouterr()
    assert captured.out.startswith('Replacing existing test_latest.csv\n')
    assert '1 column(s) with non-zero differences' in captured.out
    assert 'Wrote diff to' in captured.out
    # If the overwrite is different we should get a 4th output, the diff
    assert len(list(csv_path.parent.glob('*.csv'))) == 4
