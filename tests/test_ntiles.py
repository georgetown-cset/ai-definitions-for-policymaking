from settings import DATASET

ntile_sql = f"""\
    select
       year,
       citation_percentile,
       min(times_cited) min_times_cited,
       max(times_cited) max_times_cited,
       count(*) as count
    from {DATASET}.comparison
    group by 1, 2
    order by 1, 2
"""

ntile_sql_alt = f"""\
    select year,
           scibert_percentile,
           min(times_cited)                    min_times_cited,
           max(times_cited)                    max_times_cited,
           round(avg(times_cited), 4)          avg_times_cited,
           sum(cast(times_cited > 0 as int64)) nonzero_cite_count,
           count(scibert_percentile)           count
    from (select cset_id,
                 year,
                 times_cited,
                 if(scibert_hit is true,
                    ntile(100) over (partition by year, scibert_hit order by times_cited asc),
                    null) as scibert_percentile
          from {DATASET}.comparison
         ) t
    group by 1, 2
    order by 1, 2
"""

ntile_sql_alt2 = f"""\
    select year,
           scibert_percentile,
           min(times_cited)                    min_times_cited,
           max(times_cited)                    max_times_cited,
           round(avg(times_cited), 4)          avg_times_cited,
           sum(cast(times_cited > 0 as int64)) nonzero_cite_count,
           count(scibert_percentile)           count
    from (
             select comparison.cset_id,
                    comparison.year,
                    comparison.times_cited,
                    ntile(100) over (partition by year order by times_cited asc) as scibert_percentile
             from {DATASET}.comparison
             where scibert_hit is true
         ) t
    group by 1, 2
    order by 1, 2
"""

ntile_sql_alt3 = f"""\
    select scibert_percentile,
           min(times_cited)                    min_times_cited,
           max(times_cited)                    max_times_cited,
           round(avg(times_cited), 4)          avg_times_cited,
           sum(cast(times_cited > 0 as int64)) nonzero_cite_count,
           count(scibert_percentile) as        count
    from (select cset_id,
                 scibert_hit,
                 times_cited,
                 ntile(100) over (order by times_cited asc) as scibert_percentile
          from {DATASET}.comparison
          where scibert_hit is true
         ) t
    where scibert_hit is true
    group by 1
    order by 1
"""

ntile_sql_alt4 = f"""\
    select year,
           scibert_percentile,
           min(times_cited)                  min_times_cited,
           max(times_cited)                  max_times_cited,
           round(avg(times_cited), 4)        avg_times_cited,
           sum(if(times_cited > 0, 1, null)) nonzero_cite_count,
           count(scibert_percentile) as      count
    from {DATASET}.comparison
    where scibert_hit is true
    group by 1, 2
    order by 1, 2
"""
