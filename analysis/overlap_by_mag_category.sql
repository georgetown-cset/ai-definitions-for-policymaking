/*
Our goal here is to understand the overlap and divergence between alternative methods/models using MAG subject
categories, which are available for ~80% of publications.
*/
select mag_subject,
       keyword_hit,
       elsevier_hit,
       arxiv_scibert_hit,
       arxiv_scibert_cl_hit,
       arxiv_scibert_cv_hit,
       arxiv_scibert_ro_hit,
       arxiv_scibert_not_cv_hit,
       count(*) count
from oecd.comparison
group by 1, 2, 3, 4, 5, 6, 7, 8
order by 1, 2, 3, 4, 5, 6, 7, 8
