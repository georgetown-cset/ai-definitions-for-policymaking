with ntile_comparison as (
    select cset_id,
           comparison.year,
           country,
           times_cited,
           cast(keyword_hit as int64)                        keyword_hit,
           cast(elsevier_hit as int64)                       elsevier_hit,
           cast(scibert_hit as int64)                        scibert_hit,
           cast(scibert_cl_hit as int64)                     scibert_cl_hit,
           cast(scibert_cv_hit as int64)                     scibert_cv_hit,
           cast(scibert_ro_hit as int64)                     scibert_ro_hit,
           cast(scibert_hit and not scibert_cv_hit as int64) scibert_not_cv_hit,
           cast(subject_hit as int64)                        subject_hit,
           -- Add within-method citation percentiles
           comparison.percentile,
           keyword_percentile,
           elsevier_percentile,
           subject_percentile,
           scibert_percentile,
           scibert_cl_percentile,
           scibert_cv_percentile,
           scibert_ro_percentile,
           scibert_not_cv_percentile,
           min_percentiles.min_keyword_times_cited,
           min_percentiles.min_elsevier_times_cited,
           min_percentiles.min_subject_times_cited,
           min_percentiles.min_scibert_times_cited,
           min_percentiles.min_scibert_cv_times_cited,
           min_percentiles.min_scibert_cl_times_cited,
           min_percentiles.min_scibert_ro_times_cited,
           min_percentiles.min_scibert_not_cv_times_cited,
           min_percentiles.min_arxiv_scibert_times_cited,
           min_percentiles.min_arxiv_scibert_cv_times_cited,
           min_percentiles.min_arxiv_scibert_cl_times_cited,
           min_percentiles.min_arxiv_scibert_ro_times_cited,
           min_percentiles.min_arxiv_scibert_not_cv_times_cited
    from oecd.comparison
             left join oecd.min_percentiles on comparison.year = min_percentiles.year
    where min_percentiles.percentile = @gt_ntile + 1
),
     yearly_keyword_counts as (
         -- counts of relevant articles (per keyword hit) by country-year
         select year,
                country,
                sum(keyword_hit) as keyword_count
         from ntile_comparison
         where times_cited >= min_keyword_times_cited
         group by year, country
     ),
     yearly_elsevier_counts as (
         -- same thing but for elsevier
         select year,
                country,
                sum(elsevier_hit) as elsevier_count
         from ntile_comparison
         where times_cited >= min_elsevier_times_cited
         group by year, country
     ),
     yearly_scibert_counts as (
         select year,
                country,
                sum(scibert_hit) as scibert_count
         from ntile_comparison
         where times_cited >= min_scibert_times_cited
         group by year, country
     ),
     yearly_scibert_cl_counts as (
         select year,
                country,
                sum(scibert_cl_hit) as scibert_cl_count
         from ntile_comparison
         where times_cited >= min_scibert_cl_times_cited
         group by year, country
     ),
     yearly_scibert_cv_counts as (
         select year,
                country,
                sum(scibert_cv_hit) as scibert_cv_count
         from ntile_comparison
         where times_cited >= min_scibert_cv_times_cited
         group by year, country
     ),
     yearly_scibert_ro_counts as (
         select year,
                country,
                sum(scibert_ro_hit) as scibert_ro_count
         from ntile_comparison
         where times_cited >= min_scibert_ro_times_cited
         group by year, country
     ),
     yearly_scibert_not_cv_counts as (
         select year,
                country,
                sum(scibert_not_cv_hit) as scibert_not_cv_count
         from ntile_comparison
         where times_cited >= min_scibert_not_cv_times_cited
         group by year, country
     ),
     yearly_subject_counts as (
         select year,
                country,
                sum(subject_hit) as subject_count
         from ntile_comparison
         where times_cited >= min_subject_times_cited
         group by year, country
     ),
     long_results as (
         -- calculate shares
         select keywords.country,
                keywords.year,
                -- keyword share + count
                (0.0 + keyword_count) / sum(keyword_count) over (partition by keywords.year) as keyword_share,
                keywords.keyword_count,
                -- elsevier share + count
                (0.0 + elsevier_count) /
                sum(elsevier_count) over (partition by elsevier.year)                        as elsevier_share,
                elsevier.elsevier_count,
                -- subject share + count
                (0.0 + subject_count) /
                sum(subject_count) over (partition by subjects.year)                         as subject_share,
                subjects.subject_count,
                -- scibert share + count
                (0.0 + scibert_count) /
                sum(scibert_count) over (partition by scibert.year)                          as scibert_share,
                scibert.scibert_count,
                -- scibert_cl share + count
                (0.0 + scibert_cl_count) /
                sum(scibert_cl_count) over (partition by scibert_cl.year)                    as scibert_cl_share,
                scibert_cl.scibert_cl_count,
                -- scibert_cv share + count
                (0.0 + scibert_cv_count) /
                sum(scibert_cv_count) over (partition by scibert_cv.year)                    as scibert_cv_share,
                scibert_cv.scibert_cv_count,
                -- scibert_ro share + count
                (0.0 + scibert_ro_count) /
                sum(scibert_ro_count) over (partition by scibert_ro.year)                    as scibert_ro_share,
                scibert_ro.scibert_ro_count,
                -- scibert_not_cv share + count
                (0.0 + scibert_not_cv_count) /
                sum(scibert_not_cv_count) over (partition by scibert_not_cv.year)            as scibert_not_cv_share,
                scibert_not_cv.scibert_not_cv_count
         from yearly_keyword_counts keywords
                  left join yearly_elsevier_counts elsevier
                            on (keywords.year = elsevier.year and keywords.country = elsevier.country)
                  left join yearly_subject_counts subjects
                            on (keywords.year = subjects.year and keywords.country = subjects.country)
                  left join yearly_scibert_counts scibert
                            on (keywords.year = scibert.year and keywords.country = scibert.country)
                  left join yearly_scibert_cl_counts scibert_cl
                            on (keywords.year = scibert_cl.year and keywords.country = scibert_cl.country)
                  left join yearly_scibert_cv_counts scibert_cv
                            on (keywords.year = scibert_cv.year and keywords.country = scibert_cv.country)
                  left join yearly_scibert_ro_counts scibert_ro
                            on (keywords.year = scibert_ro.year and keywords.country = scibert_ro.country)
                  left join yearly_scibert_not_cv_counts scibert_not_cv
                            on (keywords.year = scibert_not_cv.year and keywords.country = scibert_not_cv.country)
         order by year, country
     )
-- Pivot wide
select year,
       -- keywords
       sum(if(country = 'China', keyword_share, null))                as china_keyword_share,
       sum(if(country = 'United States', keyword_share, null))        as us_keyword_share,
       sum(if(country = 'EU', keyword_share, null))                   as eu_keyword_share,
       -- scibert
       sum(if(country = 'China', scibert_share, null))                as china_scibert_share,
       sum(if(country = 'United States', scibert_share, null))        as us_scibert_share,
       sum(if(country = 'EU', scibert_share, null))                   as eu_scibert_share,
       -- scibert_cl
       sum(if(country = 'China', scibert_cl_share, null))             as china_scibert_cl_share,
       sum(if(country = 'United States', scibert_cl_share, null))     as us_scibert_cl_share,
       sum(if(country = 'EU', scibert_cl_share, null))                as eu_scibert_cl_share,
       -- scibert_cv
       sum(if(country = 'China', scibert_cv_share, null))             as china_scibert_cv_share,
       sum(if(country = 'United States', scibert_cv_share, null))     as us_scibert_cv_share,
       sum(if(country = 'EU', scibert_cv_share, null))                as eu_scibert_cv_share,
       -- scibert_ro
       sum(if(country = 'China', scibert_ro_share, null))             as china_scibert_ro_share,
       sum(if(country = 'United States', scibert_ro_share, null))     as us_scibert_ro_share,
       sum(if(country = 'EU', scibert_ro_share, null))                as eu_scibert_ro_share,
       -- elsevier
       sum(if(country = 'China', elsevier_share, null))               as china_elsevier_share,
       sum(if(country = 'United States', elsevier_share, null))       as us_elsevier_share,
       sum(if(country = 'EU', elsevier_share, null))                  as eu_elsevier_share,
       -- subjects
       sum(if(country = 'China', subject_count, null))                as china_subject_count,
       sum(if(country = 'United States', subject_count, null))        as us_subject_count,
       sum(if(country = 'EU', subject_count, null))                   as eu_subject_count,
       -- scibert_not_cv
       sum(if(country = 'China', scibert_not_cv_share, null))         as china_scibert_not_cv_share,
       sum(if(country = 'United States', scibert_not_cv_share, null)) as us_scibert_not_cv_share,
       sum(if(country = 'EU', scibert_not_cv_share, null))            as eu_scibert_not_cv_share,
       -- keywords
       sum(if(country = 'China', keyword_count, null))                as china_keyword_count,
       sum(if(country = 'United States', keyword_count, null))        as us_keyword_count,
       sum(if(country = 'EU', keyword_count, null))                   as eu_keyword_count,
       -- scibert
       sum(if(country = 'China', scibert_count, null))                as china_scibert_count,
       sum(if(country = 'United States', scibert_count, null))        as us_scibert_count,
       sum(if(country = 'EU', scibert_count, null))                   as eu_scibert_count,
       -- scibert_cl
       sum(if(country = 'China', scibert_cl_count, null))             as china_scibert_cl_count,
       sum(if(country = 'United States', scibert_cl_count, null))     as us_scibert_cl_count,
       sum(if(country = 'EU', scibert_cl_count, null))                as eu_scibert_cl_count,
       -- scibert_cv
       sum(if(country = 'China', scibert_cv_count, null))             as china_scibert_cv_count,
       sum(if(country = 'United States', scibert_cv_count, null))     as us_scibert_cv_count,
       sum(if(country = 'EU', scibert_cv_count, null))                as eu_scibert_cv_count,
       -- scibert_ro
       sum(if(country = 'China', scibert_ro_count, null))             as china_scibert_ro_count,
       sum(if(country = 'United States', scibert_ro_count, null))     as us_scibert_ro_count,
       sum(if(country = 'EU', scibert_ro_count, null))                as eu_scibert_ro_count,
       -- elsevier
       sum(if(country = 'China', elsevier_count, null))               as china_elsevier_count,
       sum(if(country = 'United States', elsevier_count, null))       as us_elsevier_count,
       sum(if(country = 'EU', elsevier_count, null))                  as eu_elsevier_count,
       -- scibert_not_cv
       sum(if(country = 'China', scibert_not_cv_count, null))         as china_scibert_not_cv_count,
       sum(if(country = 'United States', scibert_not_cv_count, null)) as us_scibert_not_cv_count,
       sum(if(country = 'EU', scibert_not_cv_count, null))            as eu_scibert_not_cv_count
from long_results
group by year
order by year
