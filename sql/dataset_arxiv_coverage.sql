/*
We want to report how many arXiv articles are in each other dataset.
Give the arXiv ID, if any, for each publication in the analysis.
*/
with arxiv_ids as (
    select distinct(links.merged_id) as cset_id,
                   meta.id           as source_id
    from gcp_cset_links_v2.all_metadata_with_cld2_lid meta
             inner join gcp_cset_links_v2.article_links links
                        on meta.id = links.orig_id
    where cast(meta.year as int64) >= 2010
      and meta.dataset = 'arxiv'
)
select in_wos,
       in_mag,
       in_dim,
       count(*) as count
from (
         select analysis.cset_id,
                max(analysis.source_dataset = 'wos') as in_wos,
                max(analysis.source_dataset = 'mag') as in_mag,
                max(analysis.source_dataset = 'ds')  as in_dim
         from oecd.cset_ids analysis
                  inner join arxiv_ids on arxiv_ids.cset_id = analysis.cset_id
         group by 1
     ) t
group by 1, 2, 3
