with preds as (
    select cset_ids.cset_id,
           max(arxiv.arxiv_coverage)                                               arxiv_coverage,
           max(keyword_results.keyword_hit)                                        keyword_hit,
           max(elsevier_results.elsevier_hit)                                      elsevier_hit,
           max(scibert_results.scibert_hit)                                        scibert_hit,
           max(scibert_results.scibert_cl_hit)                                     scibert_cl_hit,
           max(scibert_results.scibert_cv_hit)                                     scibert_cv_hit,
           max(scibert_results.scibert_ro_hit)                                     scibert_ro_hit,
           max(scibert_results.scibert_hit and not scibert_results.scibert_cv_hit) scibert_not_cv_hit
    from oecd.cset_ids cset_ids
             inner join oecd.en_2010_2020 en_2010_2020 on en_2010_2020.id = cset_ids.source_id
             left join oecd.keyword_results keyword_results on keyword_results.id = en_2010_2020.id
             left join oecd.scibert_results scibert_results on scibert_results.cset_id = cset_ids.cset_id
             left join oecd.elsevier_results elsevier_results on elsevier_results.cset_id = cset_ids.cset_id
             left join oecd.all_countries all_countries on all_countries.cset_id = cset_ids.cset_id
             left join oecd.all_arxiv_categories arxiv on arxiv.cset_id = cset_ids.cset_id
    group by 1
)
select preds.*,
       arxiv_coverage and scibert_hit        as   arxiv_scibert_hit,
       arxiv_coverage and scibert_cl_hit     as   arxiv_scibert_cl_hit,
       arxiv_coverage and scibert_cv_hit     as   arxiv_scibert_cv_hit,
       arxiv_coverage and scibert_ro_hit     as   arxiv_scibert_ro_hit,
       arxiv_coverage and scibert_not_cv_hit as   arxiv_scibert_not_cv_hit,
       greatest(coalesce(wos_subject_hit, false),
                coalesce(ds_subject_hit, false),
                coalesce(mag_subject_hit, false)) subject_hit
from preds
         left join oecd.category_results category_results on category_results.cset_id = preds.cset_id
