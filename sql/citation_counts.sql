/*
Deprecated. Switched to all_citation_counts (from wos_citation_counts, ds_citation_counts, mag_citation_counts)

Citation counts for each source publication, from WOS, DIM, and MAG.

If we don't observe any citations for a given publication, we impute 0 citations.
*/
with ids as (
    -- Create wide table of IDs
    select cset_id,
           string_agg(if(source_dataset = 'wos', source_id, null)) wos_id,
           string_agg(if(source_dataset = 'mag', source_id, null)) mag_id,
           string_agg(if(source_dataset = 'ds', source_id, null))  ds_id
    from oecd.cset_ids
    group by 1
),
     wos as (
         select distinct(en_2010_2020.id),
                        wos.times_cited
         from oecd.en_2010_2020 en_2010_2020
                  inner join oecd.cset_gold_all_wos_20200219 wos on wos.id = en_2010_2020.id
         where en_2010_2020.dataset = 'wos'
     ),
     ds as (
         select distinct(en_2010_2020.id),
                        ds.times_cited
         from oecd.en_2010_2020 en_2010_2020
                  inner join analysis_friendly.cset_gold_all_dimensions_publications ds on ds.id = en_2010_2020.id
         where en_2010_2020.dataset = 'ds'
     ),
     mag as (
         select cast(mag.PaperReferenceId as string) as id,
                count(*)                             as times_cited
         from oecd.en_2010_2020 en_2010_2020
                  inner join gcp_cset_mag.PaperReferences mag on cast(mag.PaperReferenceId as string) = en_2010_2020.id
         where en_2010_2020.dataset = 'mag'
         group by 1
     )
select ids.cset_id,
       ids.wos_id,
       ids.ds_id,
       ids.mag_id,
       wos.times_cited                                                                                   wos_times_cited,
       ds.times_cited                                                                                    ds_times_cited,
       mag.times_cited                                                                                   mag_times_cited,
       greatest(coalesce(wos.times_cited, 0), coalesce(ds.times_cited, 0), coalesce(mag.times_cited, 0)) times_cited
from oecd.en_2010_2020 en_2010_2020
         left join wos on wos.id = ids.wos_id
         left join ds on ds.id = ids.ds_id
         left join mag on mag.id = ids.mag_id
