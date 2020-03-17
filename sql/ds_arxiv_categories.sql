with subject as (
    select id,
           subject,
           cast(arxiv_overlap as boolean) arxiv_coverage
    from oecd.cset_gold_all_dimensions_publications_20200224 subjects
             left join (
        select *
        from oecd_for_james.arxiv_ds_coverage coverage
        where arxiv_overlap = 1
    ) coverage
                       on lower(subjects.ds_subject) = lower(coverage.discipline)
)
select corpus.id,
       array_agg(distinct subject.subject ignore nulls order by subject.subject) as subject,
       max(coalesce(subject.arxiv_coverage, false))                              as arxiv_coverage
from oecd.en_2010_2020 corpus
         left join subject
                   on corpus.id = subject.id
where corpus.dataset = 'ds'
group by 1
