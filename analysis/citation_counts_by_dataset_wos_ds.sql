/*
Do citation counts tend to be higher in any of the datasets?

This is a standalone descriptive query.
*/
select coalesce(ds_times_cited, 0) = 0 zero_wos,
       coalesce(mag_times_cited, 0) = 0 zero_ds,
       count(*) count
from oecd.all_citation_counts
where wos_id is not null
  and ds_id is not null
group by 1, 2
