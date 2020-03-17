select cset_id,
       count(*) = 1 as             single_source,
       max(source_dataset = 'mag') has_mag
from oecd.cset_ids
group by 1
