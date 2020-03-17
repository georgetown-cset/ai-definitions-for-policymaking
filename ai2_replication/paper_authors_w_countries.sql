-- All author/paper pairs, along with country heuristics for the author
select PaperId,
       AuthorId,
       -- US
       logical_or(dotcom)     as dotcom,
       logical_or(dotedu)     as dotedu,
       -- China
       logical_or(dotcn)      as dotcn,
       logical_or(dothk)      as dothk,
       logical_or(china_name) as china_name,
       logical_or(china_city) as china_city
from gcp_cset_mag.PaperAuthorAffiliations paa
         left outer join ai2_replication.institutions i
                         on paa.AffiliationId = cast(i.AffiliationId as string)
group by AuthorId, PaperId

