/*
How many citation counts are zero, in each dataset?
*/
select 'ds'                            dataset,
       coalesce(ds_times_cited, 0) = 0 has_zero_citations,
       count(*)                        count
from oecd.all_citation_counts
where ds_id is not null
group by 1, 2
union all
select 'mag'                           dataset,
       coalesce(ds_times_cited, 0) = 0 has_zero_citations,
       count(*)                        count
from oecd.all_citation_counts
where mag_id is not null
group by 1, 2
union all
select 'wos'                           dataset,
       coalesce(ds_times_cited, 0) = 0 has_zero_citations,
       count(*)                        count
from oecd.all_citation_counts
where wos_id is not null
group by 1, 2

