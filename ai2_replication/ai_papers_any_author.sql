select p.*,
       dotcom,
       dotedu,
       dotcn,
       dothk,
       china_name,
       china_city,
       (langs.PaperId is not null) as china_language
-- Only look at conference or journal papers
from (select *,
             (case
                  when trim(Year) = '' then null
                  when regexp_contains(Year, '^[0-9]{4}$') then cast(Year as int64)
                 end) as yr
      from gcp_cset_mag.PapersWithAbstracts
      where DocType in ('Conference', 'Journal')
     ) p
-- Only look at AI papers
         join (
    select PaperId
    from gcp_cset_mag.PaperFieldsOfStudy pfs
    where pfs.FieldOfStudyId = 154945302
) pfos
              on p.PaperId = pfos.PaperId
-- Author affiliation-based country heuristics.  True if ANY author has heauristic
         join (
    select PaperId,
           logical_or(dotcom)     as dotcom,
           logical_or(dotedu)     as dotedu,
           logical_or(dotcn)      as dotcn,
           logical_or(dothk)      as dothk,
           logical_or(china_name) as china_name,
           logical_or(china_city) as china_city
    from ai2_replication.paper_authors_w_countries
    group by PaperId
) auths
              on p.PaperId = auths.PaperId
         left outer join (
    select distinct cast(source_id as int64) as PaperId
    from ai2_replication.language
    where title_code like 'zh%'
      and abstract_code like 'zh%'
) langs
                         on p.PaperId = langs.PaperId
