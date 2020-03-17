with wos_categories as (
    select distinct(all_meta.id),
                   wos.arxiv_coverage
    from oecd.en_2010_2020 all_meta
             inner join oecd.wos_arxiv_categories wos on wos.id = all_meta.id
    where all_meta.dataset = 'wos'
),
     ds_categories as (
         select distinct(all_meta.id),
                        ds.arxiv_coverage
         from oecd.en_2010_2020 all_meta
                  inner join oecd.ds_arxiv_categories ds on ds.id = all_meta.id
         where all_meta.dataset = 'ds'
     ),
     mag_categories as (
         select distinct(all_meta.id),
                        mag.arxiv_coverage
         from oecd.en_2010_2020 all_meta
                  inner join oecd.mag_arxiv_categories mag on cast(mag.source_id as string) = all_meta.id
         where all_meta.dataset = 'mag'
     )
select cset_id,
       wos.id                                        wos_id,
       ds.id                                         ds_id,
       mag.id                                        mag_id,
       wos.arxiv_coverage                            wos_arxiv_coverage,
       ds.arxiv_coverage                             ds_arxiv_coverage,
       mag.arxiv_coverage                            mag_arxiv_coverage,
       -- Did we code any of the source dataset categories associated with the publication as arXiv-covered?
       greatest(coalesce(wos.arxiv_coverage, false), coalesce(ds.arxiv_coverage, false),
                coalesce(mag.arxiv_coverage, false)) arxiv_coverage
from oecd.cset_ids cset_ids
         left join wos_categories wos on wos.id = cset_ids.source_id
         left join ds_categories ds on ds.id = cset_ids.source_id
         left join mag_categories mag on mag.id = cset_ids.source_id
