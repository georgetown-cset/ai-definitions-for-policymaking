select cset_ids.cset_id,
       pf.PaperId                                                      as source_id,
       string_agg(distinct f.DisplayName, '; ' order by f.DisplayName) as field,
       min(pf.Score)                                                   as min_field_score,
       max(pf.Score)                                                   as max_field_score,
       max(coverage.arxiv_coverage)                                       arxiv_coverage
from oecd.cset_ids cset_ids
         inner join gcp_cset_mag.PapersWithAbstracts p on cast(p.PaperId as string) = cset_ids.source_id
         left join gcp_cset_mag.PaperFieldsOfStudy pf on p.PaperId = pf.PaperId
         left join gcp_cset_mag.FieldsOfStudy f on f.FieldOfStudyId = pf.FieldOfStudyId
         left join oecd.arxiv_mag_coverage coverage on lower(coverage.field) = lower(f.DisplayName)
where f.Level = 0
  and cset_ids.source_dataset = 'mag'
group by 1, 2
