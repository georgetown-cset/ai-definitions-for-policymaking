select cset_id,
       source_id,
       title_cld2_lid_first_result_short_code    title_code,
       abstract_cld2_lid_first_result_short_code abstract_code
from gcp_cset_links_v2.all_metadata_with_cld2_lid lid
         inner join oecd.cset_ids ids on ids.source_id = lid.id
where title_cld2_lid_success is true
  and title_cld2_lid_is_reliable is true
  and abstract_cld2_lid_success is true
  and abstract_cld2_lid_is_reliable
