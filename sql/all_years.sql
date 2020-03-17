select cset_ids.cset_id,
       max(cast(en_2010_2020.year as int64)) year
from oecd.cset_ids cset_ids
         left join oecd.en_2010_2020 on en_2010_2020.id = cset_ids.source_id
group by 1
