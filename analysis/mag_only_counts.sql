/*
How many of the documents in our analysis are only available from MAG?
11.2M out of 38.6M. Without MAG-only documents, there are 27.4M documents.
*/
select (single_source is true and has_mag is true) as only_mag,
       count(*)                                    as n
from (
         select cset_id,
                count(*) = 1 as             single_source,
                max(source_dataset = 'mag') has_mag
         from oecd.cset_ids
         group by 1) src_summary
group by 1
