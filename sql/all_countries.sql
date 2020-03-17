/*
Gather the affiliation countries from WOS, DIM, and MAG.

In the case where a publication appears more than once within or across these sources, we `max()` across the affiliation
indicators, so a deduplicated paper takes a value of `true` for `eu_affiliation` if the indicator is true in one or more
of sources.

See the `analysis` folder for some investigation
*/
with countries as (
    select cset_ids.cset_id,
           cset_ids.source_id,
           wos.us_affiliation,
           wos.china_affiliation,
           wos.eu_affiliation
    from oecd.cset_ids cset_ids
             inner join oecd.wos_countries wos on wos.id = cset_ids.source_id
    where cset_ids.source_dataset = 'wos'
    union all
    select cset_ids.cset_id,
           cset_ids.source_id,
           ds.us_affiliation,
           ds.china_affiliation,
           ds.eu_affiliation
    from oecd.cset_ids cset_ids
             inner join oecd.ds_countries ds on ds.id = cset_ids.source_id
    where cset_ids.source_dataset = 'ds'
    union all
    select cset_ids.cset_id,
           cset_ids.source_id,
           mag.us_affiliation,
           mag.china_affiliation,
           mag.eu_affiliation
    from oecd.cset_ids cset_ids
             inner join oecd.mag_countries mag on cast(mag.PaperId as string) = cset_ids.source_id
    where cset_ids.source_dataset = 'mag'
),
     affiliations as (
         select cset_id,
                max(us_affiliation)    as us_affiliation,
                max(china_affiliation) as china_affiliation,
                max(eu_affiliation)    as eu_affiliation
         from countries
         group by 1
     )
select cset_id,
       (case
            when (us_affiliation is true and china_affiliation is false and eu_affiliation is false)
                then 'United States'
            when (us_affiliation is false and china_affiliation is true and eu_affiliation is false) then 'China'
            when (us_affiliation is false and china_affiliation is false and eu_affiliation is true) then 'EU'
            when (us_affiliation is true and china_affiliation is true and eu_affiliation is false) then 'US-China'
            when (us_affiliation is true and china_affiliation is false and eu_affiliation is true) then 'EU-US'
            when (us_affiliation is false and china_affiliation is true and eu_affiliation is true) then 'EU-China'
            when (us_affiliation is true and china_affiliation is true and eu_affiliation is true) then 'China-EU-US'
            when (us_affiliation is false and china_affiliation is false and eu_affiliation is false) then 'Other'
            else 'Unexpected' end) as country
from affiliations
