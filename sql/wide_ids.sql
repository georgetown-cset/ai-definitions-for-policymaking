-- Create wide table of IDs
select cset_id,
       string_agg(if(source_dataset = 'wos', source_id, null)) wos_id,
       string_agg(if(source_dataset = 'ds', source_id, null))  ds_id,
       string_agg(if(source_dataset = 'mag', source_id, null)) mag_id
from oecd.cset_ids
group by 1
