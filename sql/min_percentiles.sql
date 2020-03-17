/*
Calculate the fewest citations in a threshold percentile; we'll include all publications with that many or more, even if
because of arbitrary-tie-breaking they fall below the threshold percentile.
*/
with keywords as (
    select year,
           keyword_percentile percentile,
           min(times_cited)   min_keyword_times_cited
    from oecd.percentiles
    where keyword_percentile in (50, 75, 80, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100)
    group by 1, 2
),
     elsevier as (
         select year,
                elsevier_percentile percentile,
                min(times_cited)    min_elsevier_times_cited
         from oecd.percentiles
         where elsevier_percentile in (50, 75, 80, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100)
         group by 1, 2
     ),
     subject as (
         select year,
                subject_percentile percentile,
                min(times_cited)   min_subject_times_cited
         from oecd.percentiles
         where subject_percentile in (50, 75, 80, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100)
         group by 1, 2
     ),
     scibert as (
         select year,
                scibert_percentile percentile,
                min(times_cited)   min_scibert_times_cited
         from oecd.percentiles
         where scibert_percentile in (50, 75, 80, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100)
         group by 1, 2
     ),
     scibert_cv as (
         select year,
                scibert_cv_percentile percentile,
                min(times_cited)      min_scibert_cv_times_cited
         from oecd.percentiles
         where scibert_cv_percentile in (50, 75, 80, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100)
         group by 1, 2
     ),
     scibert_cl as (
         select year,
                scibert_cl_percentile percentile,
                min(times_cited)      min_scibert_cl_times_cited
         from oecd.percentiles
         where scibert_cl_percentile in (50, 75, 80, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100)
         group by 1, 2
     ),
     scibert_ro as (
         select year,
                scibert_ro_percentile percentile,
                min(times_cited)      min_scibert_ro_times_cited
         from oecd.percentiles
         where scibert_ro_percentile in (50, 75, 80, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100)
         group by 1, 2
     ),
     scibert_not_cv as (
         select year,
                scibert_not_cv_percentile percentile,
                min(times_cited)          min_scibert_not_cv_times_cited
         from oecd.percentiles
         where scibert_not_cv_percentile in (50, 75, 80, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100)
         group by 1, 2
     ),
     arxiv_scibert as (
         select year,
                arxiv_scibert_percentile percentile,
                min(times_cited)         min_arxiv_scibert_times_cited
         from oecd.percentiles
         where arxiv_scibert_percentile in (50, 75, 80, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100)
         group by 1, 2
     ),
     arxiv_scibert_cv as (
         select year,
                arxiv_scibert_cv_percentile percentile,
                min(times_cited)            min_arxiv_scibert_cv_times_cited
         from oecd.percentiles
         where arxiv_scibert_cv_percentile in (50, 75, 80, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100)
         group by 1, 2
     ),
     arxiv_scibert_cl as (
         select year,
                arxiv_scibert_cl_percentile percentile,
                min(times_cited)            min_arxiv_scibert_cl_times_cited
         from oecd.percentiles
         where arxiv_scibert_cl_percentile in (50, 75, 80, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100)
         group by 1, 2
     ),
     arxiv_scibert_ro as (
         select year,
                arxiv_scibert_ro_percentile percentile,
                min(times_cited)            min_arxiv_scibert_ro_times_cited
         from oecd.percentiles
         where arxiv_scibert_ro_percentile in (50, 75, 80, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100)
         group by 1, 2
     ),
     arxiv_scibert_not_cv as (
         select year,
                arxiv_scibert_not_cv_percentile percentile,
                min(times_cited)                min_arxiv_scibert_not_cv_times_cited
         from oecd.percentiles
         where arxiv_scibert_not_cv_percentile in (50, 75, 80, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100)
         group by 1, 2
     )
select keywords.year,
       keywords.percentile,
       keywords.min_keyword_times_cited,
       elsevier.min_elsevier_times_cited,
       subject.min_subject_times_cited,
       scibert.min_scibert_times_cited,
       scibert_cv.min_scibert_cv_times_cited,
       scibert_cl.min_scibert_cl_times_cited,
       scibert_ro.min_scibert_ro_times_cited,
       scibert_not_cv.min_scibert_not_cv_times_cited,
       arxiv_scibert.min_arxiv_scibert_times_cited,
       arxiv_scibert_cv.min_arxiv_scibert_cv_times_cited,
       arxiv_scibert_cl.min_arxiv_scibert_cl_times_cited,
       arxiv_scibert_ro.min_arxiv_scibert_ro_times_cited,
       arxiv_scibert_not_cv.min_arxiv_scibert_not_cv_times_cited
from keywords
         left join elsevier on keywords.year = elsevier.year and keywords.percentile = elsevier.percentile
         left join subject on keywords.year = subject.year and keywords.percentile = subject.percentile
         left join scibert on keywords.year = scibert.year and keywords.percentile = scibert.percentile
         left join scibert_cv on keywords.year = scibert_cv.year and keywords.percentile = scibert_cv.percentile
         left join scibert_cl on keywords.year = scibert_cl.year and keywords.percentile = scibert_cl.percentile
         left join scibert_ro on keywords.year = scibert_ro.year and keywords.percentile = scibert_ro.percentile
         left join scibert_not_cv
                   on keywords.year = scibert_not_cv.year and keywords.percentile = scibert_not_cv.percentile
         left join arxiv_scibert
                   on keywords.year = arxiv_scibert.year and keywords.percentile = arxiv_scibert.percentile
         left join arxiv_scibert_cv
                   on keywords.year = arxiv_scibert_cv.year and keywords.percentile = arxiv_scibert_cv.percentile
         left join arxiv_scibert_cl
                   on keywords.year = arxiv_scibert_cl.year and keywords.percentile = arxiv_scibert_cl.percentile
         left join arxiv_scibert_ro
                   on keywords.year = arxiv_scibert_ro.year and keywords.percentile = arxiv_scibert_ro.percentile
         left join arxiv_scibert_not_cv on keywords.year = arxiv_scibert_not_cv.year and
                                           keywords.percentile = arxiv_scibert_not_cv.percentile
