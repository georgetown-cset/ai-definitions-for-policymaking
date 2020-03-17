import pandas as pd
from settings import PROJECT_ID

counts = pd.read_gbq("""\
    SELECT 
      countif(arxiv_scibert_hit is true) arxiv_scibert,
      countif(arxiv_scibert_cl_hit is true) arxiv_scibert_cl,
      countif(arxiv_scibert_cv_hit is true) arxiv_scibert_cv,
      countif(arxiv_scibert_ro_hit is true) arxiv_scibert_ro,
    FROM ai_relevant_papers.definitions_brief_latest
    """, project_id=PROJECT_ID)

counts.to_csv('analysis/prediction_counts.csv', index=False)
