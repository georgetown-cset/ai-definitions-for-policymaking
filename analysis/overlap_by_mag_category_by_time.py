import pandas as pd

from bq import read_sql

df = pd.read_gbq(read_sql('../analysis/overlap_by_mag_category_by_time.sql'))
df

df = df.groupby(['year', 'mag_subject', 'keyword_hit', 'arxiv_scibert_hit'], as_index=False).agg({'count': 'sum'})
df = df.loc[df['keyword_hit'].isin([True, False]) & df['arxiv_scibert_hit'].isin([True, False])]
df = df[~((df['keyword_hit'] == True) & (df['arxiv_scibert_hit'] == True))]
df = df[~((df['keyword_hit'] == False) & (df['arxiv_scibert_hit'] == False))]
df['hit'] = 'scibert'
df.loc[df['keyword_hit'] == True, 'hit'] = 'keyword'

wide = pd.pivot_table(df.sort_values('count', ascending=False), values='count', index=['mag_subject', 'hit'],
                      columns='year')
wide.to_excel('analysis/overlap_over_time.xlsx')
