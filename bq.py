"""Some wrappers around the BQ client for Python.

Reference: https://googleapis.dev/python/bigquery/latest/index.html
"""
import os
import warnings
from pathlib import Path
from typing import Union, Optional

import google.auth
from google.cloud import bigquery
from google.cloud.bigquery import ScalarQueryParameter
from google.cloud.bigquery.job import QueryJob

from settings import PROJECT_ID, SQL_DIR, DATASET

os.putenv('GOOGLE_CLOUD_PROJECT', PROJECT_ID)

_client = None
_credentials = None


def create_client() -> bigquery.Client:
    """Create BQ API Client.

    :return: BQ API Client.
    """
    global _client, _credentials
    with warnings.catch_warnings():
        warnings.filterwarnings('ignore', message='Your application has authenticated using end user credentials')
        if _credentials is None:
            _credentials, _ = google.auth.default()
        if _client is None:
            _client = bigquery.Client(project=PROJECT_ID)
    return _client


def query(sql: Union[str, Path],
          table: str,
          dataset=DATASET,
          truncate=False,
          **config_kw) -> QueryJob:
    """Run a query and write the result to a BigQuery table.

    :param sql: Query SQL as text or a :class:`pathlib.Path` to a SQL file.
    :param table: Destination table.
    :param dataset: Destination dataset.
    :param truncate: If ``True``, overwrite the destination table if it exists.
    :param config_kw: Passed to :class:`bigquery.QueryJobConfig`.
    :return: Completed QueryJob.
    :raises: :class:`google.api_core.exceptions.GoogleAPICallError` if the request is unsuccessful .
    """
    if isinstance(sql, Path):
        sql = sql.read_text()
    _client = create_client()
    destination_id = f'{PROJECT_ID}.{dataset}.{table}'
    print(f'Writing {dataset}.{table}')
    config = bigquery.QueryJobConfig(destination=destination_id,
                                     write_disposition='WRITE_TRUNCATE' if truncate else 'WRITE_EMPTY',
                                     use_legacy_sql=False,
                                     **config_kw)
    job = _client.query(sql, job_config=config)
    # Wait for job to finish, or raise an error if unsuccessful
    _ = job.result()
    return job


def read_sql(filename: Union[str, Path]) -> str:
    """
    Read SQL file from the `./sql` directory.

    :param filename: Filename.
    :return: File text.
    """
    return Path(SQL_DIR, filename).with_suffix('.sql').read_text()


def make_table(table: str, truncate=False, **kw) -> QueryJob:
    """
    Run a query defined in a SQL file, and write the result to a BQ table of the same name as the SQL file.

    :param table: Table name.
    :param truncate: If ``True``, overwrite the table if it exists.
    :return: Completed QueryJob.
    """
    job = query(read_sql(table), table, truncate=truncate, **kw)
    return job


def make_ntile_table(ntiles: int = 100,
                     truncate=False,
                     sql_path: Union[str, Path] = None,
                     table_suffix: Optional[str] = None) -> QueryJob:
    """
    Create a table describing country share output for publications above the nth citation count percentile.

    The result has  a name like ``country_share_99th`` or ``country_share_99th_arxiv``.

    :param ntiles: Included publications will have a citation percentile greater than this number, in the range 1-100
        inclusive.
    :param truncate: If ``True``, replace the table if it exists.
    :param sql_path: Override the default SQL template.
    :param table_suffix: Append the table name with a given suffix.
    :return: Completed QueryJob.
    """
    params = [
        ScalarQueryParameter('ntiles', 'INT64', ntiles),
        ScalarQueryParameter('gt_ntile', 'INT64', ntiles - 1),
    ]
    if sql_path is None:
        sql = read_sql('country_share_template')
    else:
        sql = read_sql(sql_path)
    job = query(sql, f'country_share_{ntiles - 1}th{table_suffix if table_suffix else ""}', truncate=truncate,
                query_parameters=params)
    return job
