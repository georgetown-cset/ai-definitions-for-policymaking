/*
Create a table with indicators `eu_affiliation`, `us_affiliation`, and `china_affiliation`, for whether `country` of
any author affiliation is an EU member, the US, or China.
*/
with countries as (
    select ds.id,
           ds.country                        country,
           coalesce(codings.eu, false)    as eu_affiliation,
           coalesce(codings.usa, false)   as us_affiliation,
           coalesce(codings.china, false) as china_affiliation
    from oecd.cset_gold_all_dimensions_publications_20200224 ds
             left join oecd.ds_country_codings codings on ds.country = codings.country
             inner join oecd.cset_ids cset_ids on cset_ids.source_id = ds.id
    where cset_ids.source_dataset = 'ds'
)
select id,
       max(if(country = 'United States' or us_affiliation, true, false)) as us_affiliation,
       max(if(country = 'China' or china_affiliation, true, false))      as china_affiliation,
       max(eu_affiliation)                                               as eu_affiliation,
       count(*)                                                          as n_affiliation,
       count(distinct country)                                           as n_distinct_country
from countries
group by 1
