/*
We need affiliation country information for publications that appear only in MAG.
This query shows that for 2,944,743 of these publications, we have a GRID ID, so we can find the country in GRID.
For the remaining 8,898,304 publications, we have no GRID ID, and nothing else particularly useful.
`Latitude` and `Longitude` looked promising briefly, but we only observe them where we already have a GRID ID.
For some ~6M publications of the 8.9M, we observe no country affiliation text at all, so there's not much we can do.
*/
with mag_only as (
    select cset_ids.*
    from (
             select cset_id,
                    count(*) = 1 as             single_source,
                    max(source_dataset = 'mag') has_mag
             from oecd.cset_ids
             group by 1) src_summary
             inner join oecd.cset_ids cset_ids on cset_ids.cset_id = src_summary.cset_id
    where (single_source is true and has_mag is true)
),
     mag_affiliations as (
         select paa.PaperId,
                paa.AffiliationId,
                a.NormalizedName,
                a.WikiPage,
                a.GridId,
                a.Longitude,
                a.Latitude,
                paa.OriginalAffiliation
         from mag_only
                  left join gcp_cset_mag.PaperAuthorAffiliations paa on cast(paa.PaperId as string) = mag_only.source_id
                  left join gcp_cset_mag.Affiliations a on cast(a.AffiliationId as string) = paa.AffiliationId
     )
select GridId is not null                                    as has_grid_id,
       (Latitude is not null and Longitude is not null)      as has_coords,
       (NormalizedName is not null and NormalizedName != '') as has_affiliation_name,
       (WikiPage is not null and WikiPage != '')             as has_wiki_page,
       count(distinct PaperId)                               as paper_count,
       count(distinct AffiliationId)                         as affiliation_count,
       count(distinct OriginalAffiliation)                   as original_affiliation_count
from mag_affiliations
group by 1, 2, 3, 4
