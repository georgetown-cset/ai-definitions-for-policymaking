/*
In the prediction tables, we have source dataset IDs rather than CSET IDs.
For each CSET ID that we want to include in our analysis, we have one linked prediction.
We start by joining all the predictions with CSET IDs on their source-dataset IDs.
*/
with sparse_predictions as (
    select merged_id                             as cset_id,
           scibert.class_probs[ordinal(2)] >= .5 as scibert_hit,
           cl.class_probs[ordinal(2)] >= .5      as scibert_cl_hit,
           cv.class_probs[ordinal(2)] >= .5      as scibert_cv_hit,
           ro.class_probs[ordinal(2)] >= .5      as scibert_ro_hit
    from gcp_cset_links_v2.article_links links
             left join oecd_for_james.all_final_ai_predictions scibert on links.orig_id = scibert.id
             left join oecd_for_james.all_final_cl_predictions cl on links.orig_id = cl.id
             left join oecd_for_james.all_final_cv_predictions cv on links.orig_id = cv.id
             left join oecd_for_james.all_final_ro_predictions ro on links.orig_id = ro.id
),
/*
The result is sparse because for, say, a CSET ID representing an article that appears in WoS, DIM, and MAG, we'll have a prediction for only one of the three linked records.
We take whichever prediction is non-missing.
*/
     predictions as (
         select sparse_predictions.cset_id,
                max(scibert_hit)    scibert_hit,
                max(scibert_cl_hit) scibert_cl_hit,
                max(scibert_cv_hit) scibert_cv_hit,
                max(scibert_ro_hit) scibert_ro_hit
         from oecd.cset_ids corpus_ids
                  inner join sparse_predictions on corpus_ids.cset_id = sparse_predictions.cset_id
         group by 1
     )
/*
There's now a single row for each CSET ID:

-- select count(*),
--        count(scibert_hit),
--        count(scibert_cl_hit),
--        count(scibert_cv_hit),
--        count(scibert_ro_hit)
-- from predictions
-- --> 40428485 39908474 39908474 39908474 39908474

520011 of the scibert_results rows have missing predictions
*/
select *
from predictions
