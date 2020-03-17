/*
As in ``overlap_by_mag_category``, our goal here is to understand the overlap and divergence between alternative
methods/models. Here instead of top-level MAG subject categories (FieldsOfStudy), we're using MAG's lower-level subject
categories.

See ``sql/mag_subfield_scores.sql``.
*/
select keyword_hit,
       elsevier_hit,
       arxiv_scibert_hit,
       arxiv_scibert_cl_hit,
       arxiv_scibert_cv_hit,
       arxiv_scibert_ro_hit,
       arxiv_scibert_not_cv_hit,
       level0_level1_name,
       count(*)   count,
       avg(score) average_score
from oecd.comparison c
         left join oecd.mag_subfield_scores mss on mss.cset_id = c.cset_id
group by 1, 2, 3, 4, 5, 6, 7, 8
order by 1, 2, 3, 4, 5, 6, 7, 8
