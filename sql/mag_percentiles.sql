select all_predictions.cset_id,
       all_years.year,
       mag_times_cited,
       ntile(100) over (partition by year order by mag_times_cited asc) as mag_percentile,
       if(keyword_hit is true,
          ntile(100) over (partition by year, keyword_hit order by mag_times_cited asc),
          null)                                                         as mag_keyword_percentile,
       if(elsevier_hit is true,
          ntile(100) over (partition by year, elsevier_hit order by mag_times_cited asc),
          null)                                                         as mag_elsevier_percentile,
       if(subject_hit is true,
          ntile(100) over (partition by year, subject_hit order by mag_times_cited asc),
          null)                                                         as mag_subject_percentile,
       if(scibert_hit is true,
          ntile(100) over (partition by year, scibert_hit order by mag_times_cited asc),
          null)                                                         as mag_scibert_percentile,
       if(scibert_cv_hit is true,
          ntile(100) over (partition by year, scibert_cv_hit order by mag_times_cited asc),
          null)                                                         as mag_scibert_cv_percentile,
       if(scibert_cl_hit is true,
          ntile(100) over (partition by year, scibert_cl_hit order by mag_times_cited asc),
          null)                                                         as mag_scibert_cl_percentile,
       if(scibert_ro_hit is true,
          ntile(100) over (partition by year, scibert_ro_hit order by mag_times_cited asc),
          null)                                                         as mag_scibert_ro_percentile,
       if(scibert_not_cv_hit is true,
          ntile(100) over (partition by year, scibert_not_cv_hit order by mag_times_cited asc),
          null)                                                         as mag_scibert_not_cv_percentile,
       if(arxiv_scibert_hit is true,
          ntile(100) over (partition by year, arxiv_scibert_hit order by mag_times_cited asc),
          null)                                                         as mag_arxiv_scibert_percentile,
       if(arxiv_scibert_cv_hit is true,
          ntile(100) over (partition by year, arxiv_scibert_cv_hit order by mag_times_cited asc),
          null)                                                         as mag_arxiv_scibert_cv_percentile,
       if(arxiv_scibert_cl_hit is true,
          ntile(100) over (partition by year, arxiv_scibert_cl_hit order by mag_times_cited asc),
          null)                                                         as mag_arxiv_scibert_cl_percentile,
       if(arxiv_scibert_ro_hit is true,
          ntile(100) over (partition by year, arxiv_scibert_ro_hit order by mag_times_cited asc),
          null)                                                         as mag_arxiv_scibert_ro_percentile,
       if(arxiv_scibert_not_cv_hit is true,
          ntile(100)
          over (partition by year, arxiv_scibert_not_cv_hit order by mag_times_cited asc),
          null)                                                         as mag_arxiv_scibert_not_cv_percentile
from oecd.all_predictions
         left join oecd.all_citation_counts cites
                   on cites.cset_id = all_predictions.cset_id
         left join oecd.all_years on all_years.cset_id = all_predictions.cset_id
where cites.mag_id is not null
