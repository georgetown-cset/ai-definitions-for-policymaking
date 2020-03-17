import pytest
from google.api_core.exceptions import NotFound
from google.cloud import bigquery

from bq import query, create_client
from settings import DATASET, PROJECT_ID

TOY_QUERY = """select * from unnest(array<struct<x int64, y string>>[(1, 'foo'), (3, 'bar')])"""
ALT_TOY_QUERY = """select * from unnest(array<struct<x int64, y string>>[(2, 'baz'), (4, 'bam')])"""


@pytest.fixture
def cleanup_test_table():
    yield
    client = create_client()
    try:
        client.delete_table(f'{DATASET}.test', not_found_ok=True)
    except NotFound:
        pass


@pytest.fixture
def client():
    return create_client()


def test_create_client():
    # We shouldn't get a UserWarning about using GCP user credentials
    with pytest.warns(None) as warnings:
        client = create_client()
    assert len(warnings) == 0
    assert client.project == PROJECT_ID


def test_create_table(cleanup_test_table, client):
    result = query(TOY_QUERY, table='test', dataset=DATASET)
    assert result.errors is None
    # Check the result
    job = client.query(TOY_QUERY)
    assert isinstance(job, bigquery.QueryJob)
    job_result = job.result()
    assert isinstance(job_result, bigquery.table.RowIterator)
    rows = [row for row in job_result]
    assert len(rows) == 2
    assert list(rows[0].keys()) == ['x', 'y']


def test_recreate_table(cleanup_test_table, client):
    """If the cleanup fixture works, creating the test table a second time won't raise NotFound.

    Keep this test below test_create_table().
    """
    # Create the test table a second time
    job_2 = query(TOY_QUERY, table='test', dataset=DATASET)
    assert job_2.state == 'DONE'
    table_2_rows = [row for row in job_2.result()]
    assert table_2_rows[0]['x'] == 1 and table_2_rows[0]['y'] == 'foo'
    table_2 = client.get_table(f'{DATASET}.test')
    # Trying to create the table a third time and passing truncate=True should replace the contents of the table
    job_3 = query(ALT_TOY_QUERY, table='test', dataset=DATASET, truncate=True)
    assert job_3.state == 'DONE'
    table_3 = client.get_table(f'{DATASET}.test')
    # The table isn't recreated
    assert table_3.created == table_2.created
    # Its contents are replaced
    assert table_3.modified > table_2.created
    table_3_rows = [row for row in job_3.result()]
    assert table_3_rows[0]['x'] == 2 and table_3_rows[0]['y'] == 'baz'
