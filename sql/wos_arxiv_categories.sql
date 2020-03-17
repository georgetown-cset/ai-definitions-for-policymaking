/*
Identify the WoS category associated with each WoS publication in the analysis.
Determine whether it's a category we've coded as having overlap with arXiv's coverage of fields.
These codings are in `oecd_for_james.arxiv_wos_coverage`.
*/
with subject as (
    select id,
           subject,
           cast(arxiv_overlap as boolean) arxiv_coverage
    from oecd.wos_subjects_20200219 subjects
             left join (
        select *
        from oecd_for_james.arxiv_wos_coverage coverage
        where arxiv_overlap = 1
    ) coverage on lower(subjects.subject) = lower(coverage.category)
)
select corpus.id,
       array_agg(distinct subject.subject ignore nulls order by subject.subject) as subject,
       max(coalesce(arxiv_coverage, false))                                      as arxiv_coverage
from oecd.en_2010_2020 corpus
         left join subject on corpus.id = subject.id
where corpus.dataset = 'wos'
group by 1
