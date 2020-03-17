/*
As in ``overlap_by_mag_category``, our goal here is to understand the overlap and divergence between alternative
methods/models. Here instead of top-level MAG subject categories (FieldsOfStudy), we're using MAG's lower-level subject
categories.

Also, we now know per email with Kuansan that the Score is a cosine similarity, so when summarizing over papers in terms
of categories, we don't want to consider all categories with Score > 0 to 'belong' to a category, as we did in
``overlap_by_mag_category``. Averaging over cosine similarity scores would make more sense, with the result
interpretable as the average distance between the embedding of a paper in a group and the topic embedding (centroid?).
Unfortunately, the cosine similarity score is truncated at zero, so we only observe positive scores. This means we're
excluding from the average papers that are particularly dissimilar from a topic.
*/
-- Get the CSET ID + MAG ID of papers in the analysis
with mag_ids as (
    select any_value(ids.cset_id) cset_id,
           ids.source_id
    from oecd.cset_ids ids
    where ids.source_dataset = 'mag'
    -- This should be unnecessary, but really don't have any duplicate MAG IDs
    group by ids.source_id
),
-- Get level-0 field IDs and names along with the IDs of their level-1 child fields
level0 as (
  select fs.FieldOfStudyId level0_id,
    fs.DisplayName level0_name,
    fsc.ChildFieldOfStudyId level1_id,
  from gcp_cset_mag.FieldsOfStudy fs
  left join gcp_cset_mag.FieldOfStudyChildren fsc on fs.FieldOfStudyId = fsc.FieldOfStudyId
  where fs.Level = 0
),
-- Get level-0 and level-1 field names together as {level-0} / {level-1}, e.g., 'Computer Science / Artificial
--   Intelligence'
level1 as (
    select l0.level0_id,
        l0.level0_name,
        l0.level1_id,
        fs.DisplayName level1_name,
        l0.level0_name || ' / ' || fs.DisplayName as level0_level1_name
    from level0 l0
    left join gcp_cset_mag.FieldsOfStudy fs on fs.FieldOfStudyId = l0.level1_id
),
-- Join our analysis papers with their level-0 / level-1 field names by MAG ID
source_scores as (
    select mag_ids.cset_id,
      mag_ids.source_id,
      level1.*,
      pfs.Score score,
    from mag_ids
    -- TODO: snapshot these MAG tables for replicability
    -- PaperFieldsOfStudy links paper IDs to field of study IDs
    left join gcp_cset_mag.PaperFieldsOfStudy pfs on cast(pfs.PaperId as string) = mag_ids.source_id
    -- TODO: do we have at least one level-1 field for each paper, or for some do we only have level-0 IDs? If so, we'll
    --   lose those papers with this inner join. Check the counts.
    inner join level1 on level1.level1_id = pfs.FieldOfStudyId
    order by cset_id
)
-- We joined papers with their fields on MAG ID (source_id) above. Often enough more than one MAG paper is associated
-- with a CSET ID. We'll define each field score of a deduplicated paper as the average over its duplicates
select cset_id,
    level0_id,
    level0_name,
    level1_id,
    level1_name,
    level0_level1_name,
    avg(score) score
from source_scores
group by 1, 2, 3, 4, 5, 6
