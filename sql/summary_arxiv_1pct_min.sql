/*
We could do this with or without the records that we can't find affiliation countries for ... to make the records
counts the same, we would exclude them here.

'The top 1% of publications' by citation is defined for the positive predictions of each method or model, not across all
publications. When comparing overlap between positive predictions, this isn't intuitive. Does a publication predicted
positive by both keywords and Elsevier need to be in the top percentile of both groups, or just at least one? Below, we
include in the overlap calculations articles that are predicted positive by _any_ of the methods or models.
*/
select arxiv_coverage,
       keyword_hit,
       elsevier_hit,
       subject_hit,
       arxiv_scibert_hit as scibert_hit,
       count(*)          as count
from oecd.comparison
where keyword_min_percentile = 100
   or elsevier_min_percentile = 100
   -- fixme: we don't have a subject_min_percentile yet
   or arxiv_scibert_min_percentile = 100
group by 1, 2, 3, 4, 5
order by 1, 2, 3, 4, 5
