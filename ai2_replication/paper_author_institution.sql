select p.PaperId,
       cast(p.EstimatedCitation as int64) as EstimatedCitationCount,
       pa.AuthorId,
       i.AffiliationId,
       i.DisplayName,
       i.OfficialPage
from ai2_replication.ai_papers_any_author p
         join gcp_cset_mag.PaperAuthorAffiliations pa
              on p.PaperId = pa.PaperId
         join ai2_replication.institutions i
              on pa.AffiliationId = cast(i.AffiliationId as string);
