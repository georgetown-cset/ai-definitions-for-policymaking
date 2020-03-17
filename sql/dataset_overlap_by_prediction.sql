/*
Get overlap across datasets for articles in our analysis, only for AI-relevant articles.

As predicted by SciBERT.
*/
select wos_id is not null as in_wos,
       ds_id is not null  as in_ds,
       mag_id is not null as in_mag,
       arxiv_scibert_hit  as scibert_hit,
       count(*)           as count
from oecd.comparison
group by 1, 2, 3, 4
order by 1, 2, 3, 4
