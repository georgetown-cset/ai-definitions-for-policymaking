with predictions as (
    select distinct(merged_id)          as cset_id,
                   elsevier.elsevier_ai as elsevier_hit
    from gcp_cset_links_v2.article_links links
             -- Restrict to CSET IDs included in analysis
             inner join oecd.cset_ids corpus_ids on corpus_ids.cset_id = links.merged_id
             left join oecd_for_james.all_final_elsevier_predictions elsevier on links.orig_id = elsevier.id
)
select *
from predictions
