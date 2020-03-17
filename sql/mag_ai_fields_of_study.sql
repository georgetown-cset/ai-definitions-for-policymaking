-- Identify fields of study in MAG/OECD definition of AI relevance
--
-- Kuansan Wang email 3/3: "I spent an extra day in OECD to go over the AI classification with the team. I feel their
--   current choice, selecting the core AI (MAG ID: 154945302), machine learning (MAG ID: 119857082) and their subfields,
--   seems to be a good one. It’ll exclude traditional control theory and signal processing (as Japanese wanted), but
--   can still capture the new neural representation and deep learning based work."

with l2_ids as (
    -- Starting from the level-1 nodes AI and ML with given IDs: get the IDs of their children
    select fos.FieldOfStudyId,
           fosc.ChildFieldOfStudyId
    from gcp_cset_mag.FieldsOfStudy fos
             left join gcp_cset_mag.FieldOfStudyChildren fosc on fos.FieldOfStudyId = fosc.FieldOfStudyId
    where fos.FieldOfStudyId in (154945302, 119857082)
),
l3_ids as (
    select l2_ids.ChildFieldOfStudyId as FieldOfStudyId,
        fosc.ChildFieldOfStudyId
    from l2_ids
          left join gcp_cset_mag.FieldOfStudyChildren fosc on l2_ids.ChildFieldOfStudyId = fosc.FieldOfStudyId
),
l4_ids as (
    select l3_ids.ChildFieldOfStudyId as FieldOfStudyId,
           fosc.ChildFieldOfStudyId
    from l3_ids
             left join gcp_cset_mag.FieldOfStudyChildren fosc on l3_ids.ChildFieldOfStudyId = fosc.FieldOfStudyId
),
l5_ids as (
    select l4_ids.ChildFieldOfStudyId as FieldOfStudyId,
           fosc.ChildFieldOfStudyId
    from l4_ids
             left join gcp_cset_mag.FieldOfStudyChildren fosc on l4_ids.ChildFieldOfStudyId = fosc.FieldOfStudyId
),
all_ids as (
    select FieldOfStudyId from l2_ids
    union all
    select ChildFieldOfStudyId from l2_ids
    union all
    select FieldOfStudyId from l3_ids
    union all
    select ChildFieldOfStudyId from l3_ids
    union all
    select FieldOfStudyId from l4_ids
    union all
    select ChildFieldOfStudyId from l4_ids
    union all
    select FieldOfStudyId from l5_ids
    union all
    select ChildFieldOfStudyId from l5_ids
)
select distinct
    fos.Level,
    fos.FieldOfStudyId,
    fos.NormalizedName,
    fos.DisplayName,
    fos.PaperCount
from all_ids
left join gcp_cset_mag.FieldsOfStudy fos on fos.FieldOfStudyId = all_ids.FieldOfStudyId
where all_ids.FieldOfStudyId is not null
order by fos.Level, fos.DisplayName
