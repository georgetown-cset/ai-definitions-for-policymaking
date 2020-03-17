/*
Like `country_share_arxiv_coverage_template.sql`, but only using WOS data.
*/
with ntile_comparison as (
    select cset_id,
           year,
           country,
           times_cited,
           cast(keyword_hit as int64)                                           keyword_hit,
           cast(elsevier_hit as int64)                                          elsevier_hit,
           cast(scibert_hit and arxiv_coverage as int64)                        scibert_hit,
           cast(scibert_cl_hit and arxiv_coverage as int64)                     scibert_cl_hit,
           cast(scibert_cv_hit and arxiv_coverage as int64)                     scibert_cv_hit,
           cast(scibert_ro_hit and arxiv_coverage as int64)                     scibert_ro_hit,
           cast(scibert_hit and not scibert_cv_hit and arxiv_coverage as int64) scibert_not_cv_hit,
           -- Add within-method citation percentiles
           wos_percentile                                                       percentile,
           wos_keyword_percentile                                               keyword_percentile,
           wos_elsevier_percentile                                              elsevier_percentile,
           wos_scibert_percentile                                               scibert_percentile,
           wos_scibert_cl_percentile                                            scibert_cl_percentile,
           wos_scibert_cv_percentile                                            scibert_cv_percentile,
           wos_scibert_ro_percentile                                            scibert_ro_percentile,
           wos_scibert_not_cv_percentile                                        scibert_not_cv_percentile
    from oecd.comparison
         -- Include only papers that appear in WOS
    where comparison.wos_id is not null
),
     yearly_keyword_counts as (
         -- counts of relevant articles (per keyword hit) by country-year
         select year,
                country,
                sum(keyword_hit) as keyword_count
         from ntile_comparison
         where keyword_percentile > @gt_ntile
         group by year, country
     ),
     yearly_elsevier_counts as (
         -- same thing but for elsevier
         select year,
                country,
                sum(elsevier_hit) as elsevier_count
         from ntile_comparison
         where elsevier_percentile > @gt_ntile
         group by year, country
     ),
     yearly_scibert_counts as (
         -- same thing but for scibert
         select year,
                country,
                sum(scibert_hit) as scibert_count
         from ntile_comparison
         where scibert_percentile > @gt_ntile
         group by year, country
     ),
     yearly_scibert_cl_counts as (
         select year,
                country,
                sum(scibert_cl_hit) as scibert_cl_count
         from ntile_comparison
         where scibert_cl_percentile > @gt_ntile
         group by year, country
     ),
     yearly_scibert_cv_counts as (
         select year,
                country,
                sum(scibert_cv_hit) as scibert_cv_count
         from ntile_comparison
         where scibert_cv_percentile > @gt_ntile
         group by year, country
     ),
     yearly_scibert_ro_counts as (
         select year,
                country,
                sum(scibert_ro_hit) as scibert_ro_count
         from ntile_comparison
         where scibert_ro_percentile > @gt_ntile
         group by year, country
     ),
     yearly_scibert_not_cv_counts as (
         select year,
                country,
                sum(scibert_not_cv_hit) as scibert_not_cv_count
         from ntile_comparison
         where scibert_not_cv_percentile > @gt_ntile
         group by year, country
     ),
     long_results as (
         -- calculate country shares
         select keywords.year,
                keywords.country,
                -- keyword share + count
                (0.0 + keyword_count) / sum(keyword_count) over (partition by keywords.year) as keyword_share,
                keyword_count,
                -- elsevier share + count
                (0.0 + elsevier_count) /
                sum(elsevier_count) over (partition by elsevier.year)                        as elsevier_share,
                elsevier_count,
                -- scibert share + count
                (0.0 + scibert_count) /
                sum(scibert_count) over (partition by scibert.year)                          as scibert_share,
                scibert_count,
                -- scibert_cl share + count
                (0.0 + scibert_cl_count) /
                sum(scibert_cl_count) over (partition by scibert_cl.year)                    as scibert_cl_share,
                scibert_cl_count,
                -- scibert_cv share + count
                (0.0 + scibert_cv_count) /
                sum(scibert_cv_count) over (partition by scibert_cv.year)                    as scibert_cv_share,
                scibert_cv_count,
                -- scibert_ro share + count
                (0.0 + scibert_ro_count) /
                sum(scibert_ro_count) over (partition by scibert_ro.year)                    as scibert_ro_share,
                scibert_ro_count,
                -- scibert_not_cv share + count
                (0.0 + scibert_not_cv_count) /
                sum(scibert_not_cv_count) over (partition by scibert_not_cv.year)            as scibert_not_cv_share,
                scibert_not_cv_count
         from yearly_keyword_counts keywords
                  left join yearly_elsevier_counts elsevier
                            on (keywords.year = elsevier.year and keywords.country = elsevier.country)
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
       sum(if(country = 'China', keyword_share, null))                             as china_keyword_share,
       sum(if(country = 'United States', keyword_share, null))                     as us_keyword_share,
       sum(if(country = 'EU', keyword_share, null))                                as eu_keyword_share,
       -- scibert
       sum(if(country = 'China', scibert_share, null))                             as china_scibert_share,
       sum(if(country = 'United States', scibert_share, null))                     as us_scibert_share,
       sum(if(country = 'EU', scibert_share, null))                                as eu_scibert_share,
       -- scibert_cl
       sum(if(country = 'China', scibert_cl_share, null))                          as china_scibert_cl_share,
       sum(if(country = 'United States', scibert_cl_share, null))                  as us_scibert_cl_share,
       sum(if(country = 'EU', scibert_cl_share, null))                             as eu_scibert_cl_share,
       -- scibert_cv
       sum(if(country = 'China', scibert_cv_share, null))                          as china_scibert_cv_share,
       sum(if(country = 'United States', scibert_cv_share, null))                  as us_scibert_cv_share,
       sum(if(country = 'EU', scibert_cv_share, null))                             as eu_scibert_cv_share,
       -- scibert_ro
       sum(if(country = 'China', scibert_ro_share, null))                          as china_scibert_ro_share,
       sum(if(country = 'United States', scibert_ro_share, null))                  as us_scibert_ro_share,
       sum(if(country = 'EU', scibert_ro_share, null))                             as eu_scibert_ro_share,
       -- elsevier
       sum(if(country = 'China', elsevier_share, null))                            as china_elsevier_share,
       sum(if(country = 'United States', elsevier_share, null))                    as us_elsevier_share,
       sum(if(country = 'EU', elsevier_share, null))                               as eu_elsevier_share,
       -- scibert_not_cv
       sum(if(country = 'China', scibert_not_cv_share, null))                      as china_scibert_not_cv_share,
       sum(if(country = 'United States', scibert_not_cv_share, null))              as us_scibert_not_cv_share,
       sum(if(country = 'EU', scibert_not_cv_share, null))                         as eu_scibert_not_cv_share,
       -- counts --
       -- keywords
       sum(if(country = 'China', long_results.keyword_count, null))                as china_keyword_count,
       sum(if(country = 'United States', long_results.keyword_count, null))        as us_keyword_count,
       sum(if(country = 'EU', long_results.keyword_count, null))                   as eu_keyword_count,
       -- scibert
       sum(if(country = 'China', long_results.scibert_count, null))                as china_scibert_count,
       sum(if(country = 'United States', long_results.scibert_count, null))        as us_scibert_count,
       sum(if(country = 'EU', long_results.scibert_count, null))                   as eu_scibert_count,
       -- scibert_cl
       sum(if(country = 'China', long_results.scibert_cl_count, null))             as china_scibert_cl_count,
       sum(if(country = 'United States', long_results.scibert_cl_count, null))     as us_scibert_cl_count,
       sum(if(country = 'EU', long_results.scibert_cl_count, null))                as eu_scibert_cl_count,
       -- scibert_cv
       sum(if(country = 'China', long_results.scibert_cv_count, null))             as china_scibert_cv_count,
       sum(if(country = 'United States', long_results.scibert_cv_count, null))     as us_scibert_cv_count,
       sum(if(country = 'EU', long_results.scibert_cv_count, null))                as eu_scibert_cv_count,
       -- scibert_ro
       sum(if(country = 'China', long_results.scibert_ro_count, null))             as china_scibert_ro_count,
       sum(if(country = 'United States', long_results.scibert_ro_count, null))     as us_scibert_ro_count,
       sum(if(country = 'EU', long_results.scibert_ro_count, null))                as eu_scibert_ro_count,
       -- elsevier
       sum(if(country = 'China', long_results.elsevier_count, null))               as china_elsevier_count,
       sum(if(country = 'United States', long_results.elsevier_count, null))       as us_elsevier_count,
       sum(if(country = 'EU', long_results.elsevier_count, null))                  as eu_elsevier_count,
       -- scibert_not_cv
       sum(if(country = 'China', long_results.scibert_not_cv_count, null))         as china_scibert_not_cv_count,
       sum(if(country = 'United States', long_results.scibert_not_cv_count, null)) as us_scibert_not_cv_count,
       sum(if(country = 'EU', long_results.scibert_not_cv_count, null))            as eu_scibert_not_cv_count
from long_results
group by year
order by year
