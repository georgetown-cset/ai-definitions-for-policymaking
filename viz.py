"""
Minimal viz code for peeking at the results. Most of it we did in Sheets.
"""
import datetime
from pathlib import Path

import pandas as pd
import plotly.express as px


def plot_country_shares(df, path):
    df = reshape(df)
    timestamp = datetime.datetime.now().strftime('%Y-%m-%d-%H.%M.%S')
    fig = px.line(df.query(f'year < 2020'), x='year', y='share', color='country', range_y=(0, .5), facet_col='method',
                  facet_col_wrap=3)
    if not isinstance(path, Path):
        path = Path(path)
    ts_path = path.parent / f'{path.stem}_{timestamp}{path.suffix}'
    print(f'Plotting to {ts_path.name}')
    fig.write_image(str(ts_path))


def reshape(df):
    long = df.melt(id_vars='year', var_name='series')
    long['country'] = long['series'].str.replace('_.*', '')
    long['measure'] = long['series'].str.replace('.*_', '')
    long['series'] = long['series'].str.split('_', 1).apply(lambda x: x[1])
    long['series'] = long['series'].str.split('_').apply(lambda x: x[:-1]).apply(lambda x: '_'.join(x))
    df = pd.merge(long.query("measure == 'count'").rename(columns={'value': 'count'}),
                  long.query("measure == 'share'").rename(columns={'value': 'share'}),
                  on=['year', 'series', 'country']).drop(columns=['measure_x', 'measure_y'])
    df = df.rename(columns={'series': 'method'})
    return df
