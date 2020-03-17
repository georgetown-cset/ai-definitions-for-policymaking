/*
`FieldOfStudy` is based on author-selected keywords, and inferred by MAG.

https://www.microsoft.com/en-us/research/project/academic/articles/microsoft-academic-increases-power-semantic-search-adding-fields-study/

There can be a dozen of them or more for a given article, and there's an associated score.

Examine how many Fields are associated with the MAG publications in our analysis.
*/
select count,
       count(*)
from (
         select cset_id,
                count(*) as count
         from oecd.cset_ids cset_ids
                  left join gcp_cset_mag.PaperFieldsOfStudy pf on cast(pf.PaperId as string) = cset_ids.source_id
         where cset_ids.source_dataset = 'mag'
         group by 1
     ) papers
group by 1
order by 2 desc;
