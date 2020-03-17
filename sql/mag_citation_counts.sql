select cast(mag.PaperReferenceId as string) as id,
       count(*)                             as times_cited
from oecd.en_2010_2020 en_2010_2020
         inner join gcp_cset_mag.PaperReferences mag on cast(mag.PaperReferenceId as string) = en_2010_2020.id
where en_2010_2020.dataset = 'mag'
group by 1
