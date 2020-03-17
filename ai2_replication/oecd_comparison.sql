-- How/why do the predictions from the OECD/definitions brief analysis differ from those in the MAG analysis?

with ai2 as (
    select cast(PaperId as string) as mag_id,
           -- The following copied from all_countries.sql
           case
               when us is true and china is false then 'United States'
               when us is false and china is true then 'China'
               when us is false and china is false then 'Other'
               when us is true and china is true then 'US-China'
               else 'Unexpected' end as ai2_country,
           citation_count as ai2_times_cited,
           top_hundredth as ai2_top_percentile
    from ai2_replication.analysis
    where yr >= 2010
      and yr < 2020
)
select c.cset_id,
       c.mag_id,
       ai2_country,
       c.country,
       c.times_cited,
       ai2.ai2_times_cited,
       ai2.ai2_top_percentile,
       c.arxiv_scibert_hit,
       ai2.ai2_top_percentile is not null as ai2_hit,
       c.arxiv_scibert_percentile
from oecd.comparison c
full join ai2 on c.mag_id = ai2.mag_id
where c.mag_id is not null
