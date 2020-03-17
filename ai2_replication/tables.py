from bq import create_client, read_sql, query

DATASET = 'ai2_replication'
client = create_client()


def make_table(table, **kw):
    sql = read_sql(f'../ai2_replication/{table}.sql')
    job = query(sql, table, dataset=DATASET, truncate=True, **kw)
    return job.result()


make_table('institutions')
make_table('paper_authors_w_countries')
make_table('language')
make_table('ai_papers_any_author')
make_table('paper_author_institution')
make_table('oecd_comparison')
