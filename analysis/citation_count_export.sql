/*
Our goal is to summarize the differences between citation counts across datasets, when a paper appears in more than one
dataset.
*/
select cset_id,
       ds_id,
       mag_id,
       wos_id,
       ds_times_cited,
       mag_times_cited,
       wos_times_cited
from oecd.all_citation_counts
