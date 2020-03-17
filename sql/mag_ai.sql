select papers.PaperId,
       Year,
       DocType,
       PaperTitle,
       paper_fields.Score
from gcp_cset_mag.FieldsOfStudy fields
         inner join gcp_cset_mag.PaperFieldsOfStudy paper_fields
                    on paper_fields.FieldOfStudyId = fields.FieldOfStudyId
         inner join gcp_cset_mag.PapersWithAbstracts papers on papers.PaperId = paper_fields.PaperId
where (NormalizedName = 'artificial intelligence'
    or NormalizedName = 'applications of artificial intelligence'
    or NormalizedName = 'artificial intelligence system')
  and DocType != 'Dataset'
  and DocType != 'Patent'
  and DocType != 'Repository'
  and DocType is not null
  and DocType != ''
  and cast(Year as int64) >= 2010
  and Score > .1
