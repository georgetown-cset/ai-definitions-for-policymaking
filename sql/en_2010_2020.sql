select id,
       -- In the event year differs across within-dataset duplicates, take the most recent year
       max(year)          year,
       -- We expect IDs to be unique within datasets, so this should do nothing
       any_value(dataset) dataset
from gcp_cset_links_v2.all_metadata_with_cld2_lid
where cast(year as int64) >= 2010
  and (title is not null
    and title != ''
    and title_cld2_lid_success is true
    and title_cld2_lid_is_reliable is true
    and title_cld2_lid_first_result_short_code = 'en')
  and (abstract is not null
    and abstract != ''
    and abstract_cld2_lid_success is true
    and abstract_cld2_lid_is_reliable is true
    and abstract_cld2_lid_first_result_short_code = 'en')
  and dataset in ('wos', 'ds', 'mag')
  -- WOS ids must start with WOS, i.e., be Common Core articles
  and (dataset != 'wos' or substr(id, 1, 3) = 'WOS')
group by 1
