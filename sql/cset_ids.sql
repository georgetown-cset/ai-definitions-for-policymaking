select
    links.merged_id as cset_id,
    corpus.id as source_id,
    corpus.dataset as source_dataset
from oecd.en_2010_2020 corpus
         inner join gcp_cset_links_v2.article_links links
                    on corpus.id = links.orig_id
