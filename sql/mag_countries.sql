/*
Create a table with indicators `eu_affiliation`, `us_affiliation`, and `china_affiliation`, for whether `country` of
any author affiliation is an EU member, the US, or China, per GRID. If an author affiliation doesn't have a GRID ID
associated with it, we will depend on linked publications in WOS or DIM providing affiliation country.
*/
select paa.PaperId,
       max(coalesce(mcc.eu, false))    as eu_affiliation,
       max(coalesce(mcc.usa, false))   as us_affiliation,
       max(coalesce(mcc.china, false)) as china_affiliation,
       count(*)                        as n_affiliation,
       count(distinct grid.country)    as n_distinct_country
from oecd.cset_ids cset_ids
         left join gcp_cset_mag.PaperAuthorAffiliations paa on cast(paa.PaperId as string) = cset_ids.source_id
         left join gcp_cset_mag.Affiliations a on cast(a.AffiliationId as string) = paa.AffiliationId
         left join oecd.grid_20200316 grid on grid.id = a.GridId
         left join oecd.mag_country_codings mcc on mcc.country = grid.country
where cset_ids.source_dataset = 'mag'
group by 1
