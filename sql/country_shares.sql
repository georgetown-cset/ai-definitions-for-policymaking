/*
This is like country_share_template.sql, but we don't impose any minimum citation threshold.
*/
with comparison as (
    select year,
           country,
           sum(cast(keyword_hit as int64))                              keyword_count,
           sum(cast(elsevier_hit as int64))                             elsevier_count,
           sum(cast(subject_hit as int64))                              subject_count,
           sum(cast(scibert_hit as int64))                              scibert_count,
           sum(cast(scibert_cl_hit as int64))                           scibert_cl_count,
           sum(cast(scibert_cv_hit as int64))                           scibert_cv_count,
           sum(cast(scibert_ro_hit as int64))                           scibert_ro_count,
           sum(cast(scibert_hit and not scibert_cv_hit as int64))       scibert_not_cv_count,
           sum(cast(arxiv_scibert_hit as int64))                        arxiv_scibert_count,
           sum(cast(arxiv_scibert_cl_hit as int64))                     arxiv_scibert_cl_count,
           sum(cast(arxiv_scibert_cv_hit as int64))                     arxiv_scibert_cv_count,
           sum(cast(arxiv_scibert_ro_hit as int64))                     arxiv_scibert_ro_count,
           sum(cast(arxiv_scibert_hit and not scibert_cv_hit as int64)) arxiv_scibert_not_cv_count
    from oecd.comparison
    group by year, country
),
     long_results as (
         -- calculate shares
         select country,
                year,
                -- keyword
                (0.0 + keyword_count) / sum(keyword_count) over (partition by year) as keyword_share,
                keyword_count,
                -- elsevier
                (0.0 + elsevier_count) /
                sum(elsevier_count) over (partition by year)                        as elsevier_share,
                elsevier_count,
                -- subject
                (0.0 + subject_count) /
                sum(subject_count) over (partition by year)                         as subject_share,
                subject_count,
                -- scibert
                (0.0 + scibert_count) /
                sum(scibert_count) over (partition by year)                         as scibert_share,
                scibert_count,
                -- scibert_cl
                (0.0 + scibert_cl_count) /
                sum(scibert_cl_count) over (partition by year)                      as scibert_cl_share,
                scibert_cl_count,
                -- scibert_cv
                (0.0 + scibert_cv_count) /
                sum(scibert_cv_count) over (partition by year)                      as scibert_cv_share,
                scibert_cv_count,
                -- scibert_ro
                (0.0 + scibert_ro_count) /
                sum(scibert_ro_count) over (partition by year)                      as scibert_ro_share,
                scibert_ro_count,
                -- scibert_not_cv
                (0.0 + scibert_not_cv_count) /
                sum(scibert_not_cv_count) over (partition by year)                  as scibert_not_cv_share,
                scibert_not_cv_count,
                -- arxiv_scibert
                (0.0 + arxiv_scibert_count) /
                sum(arxiv_scibert_count) over (partition by year)                   as arxiv_scibert_share,
                arxiv_scibert_count,
                -- arxiv_scibert_cl
                (0.0 + arxiv_scibert_cl_count) /
                sum(arxiv_scibert_cl_count) over (partition by year)                as arxiv_scibert_cl_share,
                arxiv_scibert_cl_count,
                -- arxiv_scibert_cv
                (0.0 + arxiv_scibert_cv_count) /
                sum(arxiv_scibert_cv_count) over (partition by year)                as arxiv_scibert_cv_share,
                arxiv_scibert_cv_count,
                -- arxiv_scibert_ro
                (0.0 + arxiv_scibert_ro_count) /
                sum(arxiv_scibert_ro_count) over (partition by year)                as arxiv_scibert_ro_share,
                arxiv_scibert_ro_count,
                -- arxiv_scibert_not_cv
                (0.0 + arxiv_scibert_not_cv_count) /
                sum(arxiv_scibert_not_cv_count) over (partition by year)            as arxiv_scibert_not_cv_share,
                arxiv_scibert_not_cv_count
         from comparison
         order by year, country
     )
-- Pivot wide
select year,
       -- keywords
       sum(if(country = 'China', keyword_share, null))                      as china_keyword_share,
       sum(if(country = 'United States', keyword_share, null))              as us_keyword_share,
       sum(if(country = 'EU', keyword_share, null))                         as eu_keyword_share,
       -- elsevier
       sum(if(country = 'China', elsevier_share, null))                     as china_elsevier_share,
       sum(if(country = 'United States', elsevier_share, null))             as us_elsevier_share,
       sum(if(country = 'EU', elsevier_share, null))                        as eu_elsevier_share,
       -- subjects
       sum(if(country = 'China', subject_share, null))                      as china_subject_share,
       sum(if(country = 'United States', subject_share, null))              as us_subject_share,
       sum(if(country = 'EU', subject_share, null))                         as eu_subject_share,
       -- scibert
       sum(if(country = 'China', scibert_share, null))                      as china_scibert_share,
       sum(if(country = 'United States', scibert_share, null))              as us_scibert_share,
       sum(if(country = 'EU', scibert_share, null))                         as eu_scibert_share,
       -- scibert_cl
       sum(if(country = 'China', scibert_cl_share, null))                   as china_scibert_cl_share,
       sum(if(country = 'United States', scibert_cl_share, null))           as us_scibert_cl_share,
       sum(if(country = 'EU', scibert_cl_share, null))                      as eu_scibert_cl_share,
       -- scibert_cv
       sum(if(country = 'China', scibert_cv_share, null))                   as china_scibert_cv_share,
       sum(if(country = 'United States', scibert_cv_share, null))           as us_scibert_cv_share,
       sum(if(country = 'EU', scibert_cv_share, null))                      as eu_scibert_cv_share,
       -- scibert_ro
       sum(if(country = 'China', scibert_ro_share, null))                   as china_scibert_ro_share,
       sum(if(country = 'United States', scibert_ro_share, null))           as us_scibert_ro_share,
       sum(if(country = 'EU', scibert_ro_share, null))                      as eu_scibert_ro_share,
       -- scibert_not_cv
       sum(if(country = 'China', scibert_not_cv_share, null))               as china_scibert_not_cv_share,
       sum(if(country = 'United States', scibert_not_cv_share, null))       as us_scibert_not_cv_share,
       sum(if(country = 'EU', scibert_not_cv_share, null))                  as eu_scibert_not_cv_share,
       -- arxiv_scibert
       sum(if(country = 'China', arxiv_scibert_share, null))                as china_arxiv_scibert_share,
       sum(if(country = 'United States', arxiv_scibert_share, null))        as us_arxiv_scibert_share,
       sum(if(country = 'EU', arxiv_scibert_share, null))                   as eu_arxiv_scibert_share,
       -- arxiv_scibert_cl
       sum(if(country = 'China', arxiv_scibert_cl_share, null))             as china_arxiv_scibert_cl_share,
       sum(if(country = 'United States', arxiv_scibert_cl_share, null))     as us_arxiv_scibert_cl_share,
       sum(if(country = 'EU', arxiv_scibert_cl_share, null))                as eu_arxiv_scibert_cl_share,
       -- arxiv_scibert_cv
       sum(if(country = 'China', arxiv_scibert_cv_share, null))             as china_arxiv_scibert_cv_share,
       sum(if(country = 'United States', arxiv_scibert_cv_share, null))     as us_arxiv_scibert_cv_share,
       sum(if(country = 'EU', arxiv_scibert_cv_share, null))                as eu_arxiv_scibert_cv_share,
       -- arxiv_scibert_ro
       sum(if(country = 'China', arxiv_scibert_ro_share, null))             as china_arxiv_scibert_ro_share,
       sum(if(country = 'United States', arxiv_scibert_ro_share, null))     as us_arxiv_scibert_ro_share,
       sum(if(country = 'EU', arxiv_scibert_ro_share, null))                as eu_arxiv_scibert_ro_share,
       -- arxiv_scibert_not_cv
       sum(if(country = 'China', arxiv_scibert_not_cv_share, null))         as china_arxiv_scibert_not_cv_share,
       sum(if(country = 'United States', arxiv_scibert_not_cv_share, null)) as us_arxiv_scibert_not_cv_share,
       sum(if(country = 'EU', arxiv_scibert_not_cv_share, null))            as eu_arxiv_scibert_not_cv_share,
       -- keywords
       sum(if(country = 'China', keyword_count, null))                      as china_keyword_count,
       sum(if(country = 'United States', keyword_count, null))              as us_keyword_count,
       sum(if(country = 'EU', keyword_count, null))                         as eu_keyword_count,
       -- elsevier
       sum(if(country = 'China', elsevier_count, null))                     as china_elsevier_count,
       sum(if(country = 'United States', elsevier_count, null))             as us_elsevier_count,
       sum(if(country = 'EU', elsevier_count, null))                        as eu_elsevier_count,
       -- subjects
       sum(if(country = 'China', subject_count, null))                      as china_subject_count,
       sum(if(country = 'United States', subject_count, null))              as us_subject_count,
       sum(if(country = 'EU', subject_count, null))                         as eu_subject_count,
       -- scibert
       sum(if(country = 'China', scibert_count, null))                      as china_scibert_count,
       sum(if(country = 'United States', scibert_count, null))              as us_scibert_count,
       sum(if(country = 'EU', scibert_count, null))                         as eu_scibert_count,
       -- scibert_cl
       sum(if(country = 'China', scibert_cl_count, null))                   as china_scibert_cl_count,
       sum(if(country = 'United States', scibert_cl_count, null))           as us_scibert_cl_count,
       sum(if(country = 'EU', scibert_cl_count, null))                      as eu_scibert_cl_count,
       -- scibert_cv
       sum(if(country = 'China', scibert_cv_count, null))                   as china_scibert_cv_count,
       sum(if(country = 'United States', scibert_cv_count, null))           as us_scibert_cv_count,
       sum(if(country = 'EU', scibert_cv_count, null))                      as eu_scibert_cv_count,
       -- scibert_ro
       sum(if(country = 'China', scibert_ro_count, null))                   as china_scibert_ro_count,
       sum(if(country = 'United States', scibert_ro_count, null))           as us_scibert_ro_count,
       sum(if(country = 'EU', scibert_ro_count, null))                      as eu_scibert_ro_count,
       -- scibert_not_cv
       sum(if(country = 'China', scibert_not_cv_count, null))               as china_scibert_not_cv_count,
       sum(if(country = 'United States', scibert_not_cv_count, null))       as us_scibert_not_cv_count,
       sum(if(country = 'EU', scibert_not_cv_count, null))                  as eu_scibert_not_cv_count,
       -- arxiv_scibert
       sum(if(country = 'China', arxiv_scibert_count, null))                as china_arxiv_scibert_count,
       sum(if(country = 'United States', arxiv_scibert_count, null))        as us_arxiv_scibert_count,
       sum(if(country = 'EU', arxiv_scibert_count, null))                   as eu_arxiv_scibert_count,
       -- arxiv_scibert_cl
       sum(if(country = 'China', arxiv_scibert_cl_count, null))             as china_arxiv_scibert_cl_count,
       sum(if(country = 'United States', arxiv_scibert_cl_count, null))     as us_arxiv_scibert_cl_count,
       sum(if(country = 'EU', arxiv_scibert_cl_count, null))                as eu_arxiv_scibert_cl_count,
       -- arxiv_scibert_cv
       sum(if(country = 'China', arxiv_scibert_cv_count, null))             as china_arxiv_scibert_cv_count,
       sum(if(country = 'United States', arxiv_scibert_cv_count, null))     as us_arxiv_scibert_cv_count,
       sum(if(country = 'EU', arxiv_scibert_cv_count, null))                as eu_arxiv_scibert_cv_count,
       -- arxiv_scibert_ro
       sum(if(country = 'China', arxiv_scibert_ro_count, null))             as china_arxiv_scibert_ro_count,
       sum(if(country = 'United States', arxiv_scibert_ro_count, null))     as us_arxiv_scibert_ro_count,
       sum(if(country = 'EU', arxiv_scibert_ro_count, null))                as eu_arxiv_scibert_ro_count,
       -- arxiv_scibert_not_cv
       sum(if(country = 'China', arxiv_scibert_not_cv_count, null))         as china_arxiv_scibert_not_cv_count,
       sum(if(country = 'United States', arxiv_scibert_not_cv_count, null)) as us_arxiv_scibert_not_cv_count,
       sum(if(country = 'EU', arxiv_scibert_not_cv_count, null))            as eu_arxiv_scibert_not_cv_count
from long_results
group by year
order by year
