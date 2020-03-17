/*
We could do this with or without the records that we can't find affiliation countries for ... to make the records
counts the same, we would exclude them here.

'The top 1% of publications' by citation is defined for the positive predictions of each method or model, not across all
publications. When comparing overlap between positive predictions, this isn't intuitive. Does a publication predicted
positive by both keywords and Elsevier need to be in the top percentile of both groups, or just at least one? Below, we
include in the overlap calculations articles that are predicted positive by _any_ of the methods or models.
*/
with comparison as (
    select arxiv_coverage,
           keyword_hit,
           subject_hit,
           elsevier_hit,
           arxiv_scibert_hit,
           arxiv_scibert_cl_hit,
           arxiv_scibert_cv_hit,
           arxiv_scibert_ro_hit,
           (times_cited >= p100.min_keyword_times_cited)              keyword_percentile_100,
           (times_cited >= p100.min_elsevier_times_cited)             elsevier_percentile_100,
           (times_cited >= p100.min_subject_times_cited)              subject_percentile_100,
           (times_cited >= p100.min_scibert_times_cited)              scibert_percentile_100,
           (times_cited >= p100.min_scibert_cv_times_cited)           scibert_cv_percentile_100,
           (times_cited >= p100.min_scibert_cl_times_cited)           scibert_cl_percentile_100,
           (times_cited >= p100.min_scibert_ro_times_cited)           scibert_ro_percentile_100,
           (times_cited >= p100.min_scibert_not_cv_times_cited)       scibert_not_cv_percentile_100,
           (times_cited >= p100.min_arxiv_scibert_times_cited)        arxiv_scibert_percentile_100,
           (times_cited >= p100.min_arxiv_scibert_cv_times_cited)     arxiv_scibert_cv_percentile_100,
           (times_cited >= p100.min_arxiv_scibert_cl_times_cited)     arxiv_scibert_cl_percentile_100,
           (times_cited >= p100.min_arxiv_scibert_ro_times_cited)     arxiv_scibert_ro_percentile_100,
           (times_cited >= p100.min_arxiv_scibert_not_cv_times_cited) arxiv_scibert_not_cv_percentile_100
    from oecd.comparison
             left join (select *
                        from oecd.min_percentiles
                        where min_percentiles.percentile = 100) p100
                       on comparison.year = p100.year
)
select keyword_hit,
       elsevier_hit,
       subject_hit,
       arxiv_scibert_hit,
       arxiv_scibert_cl_hit,
       arxiv_scibert_cv_hit,
       arxiv_scibert_ro_hit,
       count(*) count
from comparison
where keyword_percentile_100 is true
   or elsevier_percentile_100 is true
   or subject_percentile_100 is true
   or arxiv_scibert_percentile_100 is true
   or arxiv_scibert_cl_percentile_100 is true
   or arxiv_scibert_cv_percentile_100 is true
   or arxiv_scibert_ro_percentile_100 is true
group by 1, 2, 3, 4, 5, 6, 7
order by 1, 2, 3, 4, 5, 6, 7
