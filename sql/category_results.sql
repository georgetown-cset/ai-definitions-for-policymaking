with ids as (
    -- Create wide table of IDs
    select cset_id,
           string_agg(if(source_dataset = 'wos', source_id, null)) wos_id,
           string_agg(if(source_dataset = 'ds', source_id, null))  ds_id,
           string_agg(if(source_dataset = 'mag', source_id, null)) mag_id
    from oecd.cset_ids
    group by 1
),
     mag as (
         select distinct cast(PaperId as string) as id
         from oecd.mag_ai
     ),
     ds as (
         select distinct id
         from oecd.cset_gold_all_dimensions_publications_20200224
         where ds_subject = 'Artificial Intelligence and Image Processing'
     ),
     wos as (
         select distinct id
         from oecd.wos_subjects_20200219 subjects
         where subject = 'Computer Science, Artificial Intelligence'
     )
select ids.cset_id,
       ids.wos_id,
       ids.ds_id,
       ids.mag_id,
       wos.id is not null as wos_subject_hit,
       ds.id is not null  as ds_subject_hit,
       mag.id is not null as mag_subject_hit
from ids
         left join wos on wos.id = ids.wos_id
         left join ds on ds.id = ids.ds_id
         left join mag on mag.id = ids.mag_id

