/*
Create a table with indicators `eu_affiliation`, `us_affiliation`, and `china_affiliation`, for whether `country` of
any author affiliation is an EU member, the US, or China.

The country text in `oecd.cset_gold_all_wos_20200219` is very messy. `oecd.country_codings` hand-codes observed values
for affiliation countries as referring to an EU member, the US, or China.
*/
with countries as (
    select wos.id,
           pubyear,
           wos.country                       as country,
           coalesce(eu, 0)                   as eu_affiliation,
           coalesce(usa, 0)                  as us_affiliation,
           coalesce(cast(china as int64), 0) as china_affiliation
    from oecd.cset_gold_all_wos_20200219 wos
             left join oecd.country_codings countries
                       on wos.country = countries.country
             inner join oecd.cset_ids cset_ids on cset_ids.source_id = wos.id
    where cset_ids.source_dataset = 'wos'
)
select id,
       pubyear,
       max(if(country = 'United States' or us_affiliation = 1, true, false)) as us_affiliation,
       max(if(country = 'China' or china_affiliation = 1, true, false))      as china_affiliation,
       max(if(eu_affiliation = 1, true, false))                              as eu_affiliation,
       count(*)                                                              as n_affiliation,
       count(distinct country)                                               as n_distinct_country
from countries
group by 1, 2
