-- Compare MAG/OECD definition of AI relevance with SciBERT predictions
-- See mag_ai_fields_of_study.sql
with ai_papers as (
    -- This gives us the PaperIds for all papers with positive field cosine similarity scores (pretty low bar)
    select distinct pfos.PaperId,
                    true as mag_ai_hit
    from oecd.mag_ai_fields_of_study fos
             inner join gcp_cset_mag.PaperFieldsOfStudy pfos on fos.FieldOfStudyId = pfos.FieldOfStudyId
    where pfos.Score > 0
),
mag_scibert_comparison as (
    select cset_id,
           logical_or(mag_id is not null)                           has_mag_id,
           logical_or(coalesce(mag_ai_hit, false))                  mag_ai_hit,
           logical_or(coalesce(arxiv_scibert_hit, false))           arxiv_scibert_hit
    from oecd.comparison
    left join ai_papers on comparison.mag_id = cast(ai_papers.PaperId as string)
    group by cset_id
)
select
    has_mag_id,
    mag_ai_hit,
    arxiv_scibert_hit,
    count(*) count
from mag_scibert_comparison
group by 1, 2, 3
order by 1, 2, 3
