/*
Get overlap across datasets for articles in our analysis.

This is a standalone descriptive check.
*/
select wos_id is not null as in_wos,
       ds_id is not null  as in_ds,
       mag_id is not null as in_mag,
       count(*)              count
from oecd.wide_ids
group by 1, 2, 3
order by 1, 2, 3
