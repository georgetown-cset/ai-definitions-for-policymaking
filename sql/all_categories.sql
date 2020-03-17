with ids as (
    -- Create wide table of IDs
    select cset_id,
           string_agg(if(source_dataset = 'wos', source_id, null)) wos_id,
           string_agg(if(source_dataset = 'ds', source_id, null))  ds_id,
           string_agg(if(source_dataset = 'mag', source_id, null)) mag_id
    from oecd.cset_ids
    group by 1
),
     wos_subjects as (
         select en_2010_2020.id,
                wos.subject
         from oecd.en_2010_2020 en_2010_2020
                  left join oecd.wos_subjects_20200219 wos on wos.id = en_2010_2020.id
         where en_2010_2020.dataset = 'wos'
           and wos.subject_id = '1'
     ),
     ds_subjects as (
         select en_2010_2020.id,
                ds.subject
         from oecd.en_2010_2020 en_2010_2020
                  inner join oecd.ds_arxiv_categories ds on ds.id = en_2010_2020.id
         where en_2010_2020.dataset = 'ds'
     ),
     mag_subjects as (
         select en_2010_2020.id,
                mag.field
         from oecd.en_2010_2020 en_2010_2020
                  inner join oecd.mag_arxiv_categories mag on cast(mag.source_id as string) = en_2010_2020.id
         where en_2010_2020.dataset = 'mag'
     ),
     subjects as (
         select ids.cset_id,
                ids.wos_id,
                ids.ds_id,
                ids.mag_id,
                wos.subject                          wos_subject,
                if(ds.subject is null or array_length(ds.subject) = 0, null,
                   array_to_string(ds.subject, ';')) ds_subject,
                mag.field                            mag_subject

         from ids
                  left join wos_subjects wos on wos.id = ids.wos_id
                  left join ds_subjects ds on ds.id = ids.ds_id
                  left join mag_subjects mag on mag.id = ids.mag_id
     )
-- We expect uniqueness on cset_id in the source tables, but ensure it here
select cset_id,
       wos_id,
       ds_id,
       mag_id,
       wos_subject,
       ds_subject,
       mag_subject
from (
         select *,
                row_number() over (partition by cset_id) rn
         from subjects
     ) t
where rn = 1
