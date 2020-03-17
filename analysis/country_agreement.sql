select in_wos,
       in_ds,
       wos_us_affiliation = ds_us_affiliation       as agree_us,
       wos_china_affiliation = ds_china_affiliation as agree_china,
       wos_eu_affiliation = ds_eu_affiliation       as agree_eu,
       wos_n_affiliation = ds_n_affiliation         as agree_n,
       wos_n_affiliation > 0                        as has_wos_affiliation,
       ds_n_affiliation > 0                         as has_ds_affiliation,
       count(*)
from (
         select cset_ids.cset_id,
                max(source_dataset = 'wos') in_wos,
                max(source_dataset = 'ds')  in_ds,
                max(source_dataset = 'mag') in_mag,
                max(wos.us_affiliation)     wos_us_affiliation,
                max(wos.china_affiliation)  wos_china_affiliation,
                max(wos.eu_affiliation)     wos_eu_affiliation,
                max(wos.n_affiliation)      wos_n_affiliation,
                max(ds.us_affiliation)      ds_us_affiliation,
                max(ds.china_affiliation)   ds_china_affiliation,
                max(ds.eu_affiliation)      ds_eu_affiliation,
                max(ds.n_affiliation)       ds_n_affiliation
         from oecd.cset_ids cset_ids
                  left join oecd.wos_countries wos on wos.id = cset_ids.source_id
                  left join oecd.ds_countries ds on ds.id = cset_ids.source_id
         left join oecd.comparison comparison on comparison.cset_id = cset_ids.cset_id
         where comparison.scibert_hit is true
         group by 1
     ) t
group by 1, 2, 3, 4, 5, 6, 7, 8

