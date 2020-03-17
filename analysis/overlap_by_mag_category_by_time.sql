/*
As in ``overlap_by_mag_category``, our goal here is to understand the overlap and divergence between alternative
methods/models using MAG subject categories, which are available for ~80% of publications.

Here, we do this assessment over time, and we focus on keywords and SciBERT.
*/
select year,
       mag_subject,
       keyword_hit,
       arxiv_scibert_hit,
       count(*) count
from oecd.comparison
group by 1, 2, 3, 4
order by 1, 2, 3, 4
