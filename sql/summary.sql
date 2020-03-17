/*
We could do this with or without the records that we can't find affiliation countries for ... to make the records
counts the same, we would exclude them here.
*/
select keyword_hit,
       elsevier_hit,
       subject_hit,
       arxiv_scibert_hit,
       arxiv_scibert_cv_hit,
       arxiv_scibert_cl_hit,
       arxiv_scibert_ro_hit,
       count(*) as count
from ai_relevant_papers.definitions_brief_latest
group by 1, 2, 3, 4, 5, 6, 7
order by 1, 2, 3, 4, 5, 6, 7
