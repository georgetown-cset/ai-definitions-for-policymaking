import pandas as pd


def none_null(table, column):
    df = pd.read_gbq(f'select logical_and({column} is not null) from {table}', project_id='gcp-cset-projects')
    return df.iloc[0, 0]


def is_unique(table, column):
    df = pd.read_gbq(f'select count(distinct({column})) , count({column}) from {table}', project_id='gcp-cset-projects')
    return df.iloc[0, 0] == df.iloc[0, 1]
