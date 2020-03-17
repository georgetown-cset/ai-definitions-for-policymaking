/*
Citation counts for each source publication, from WOS, DIM, and MAG.

If we don't observe any citations for a given publication, we impute 0 citations.
*/
with ids as (
    -- Create wide table of IDs
    select cset_id,
           string_agg(if(source_dataset = 'wos', source_id, null)) wos_id,
           string_agg(if(source_dataset = 'ds', source_id, null))  ds_id,
           string_agg(if(source_dataset = 'mag', source_id, null)) mag_id
    from oecd.cset_ids
    group by 1
)
select ids.cset_id,
       ids.wos_id,
       ids.ds_id,
       ids.mag_id,
       wos.times_cited                                                                                   wos_times_cited,
       ds.times_cited                                                                                    ds_times_cited,
       mag.times_cited                                                                                   mag_times_cited,
       greatest(coalesce(wos.times_cited, 0), coalesce(ds.times_cited, 0), coalesce(mag.times_cited, 0)) times_cited,
       least(coalesce(wos.times_cited, 0), coalesce(ds.times_cited, 0), coalesce(mag.times_cited, 0))    min_times_cited
from ids
         left join oecd.wos_citation_counts wos on wos.id = ids.wos_id
         left join oecd.ds_citation_counts ds on ds.id = ids.ds_id
         left join oecd.mag_citation_counts mag on mag.id = ids.mag_id
