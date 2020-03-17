/*
These queries create several views and tables that can be used to
study AI research in China.

The main table is ai_papers_any_author_table, which contains one row
for every AI paper along with relevant stats like
* its estimated citation count
* whether or not one of its authors is from an institution whose
  website ends in .cn
* etc

These queries assume that the following tables already exist, which are copies
of the Microsoft Academic Graph (MAG) data:
* mag_affiliations => jd: gcp_cset_mag.Affiliations
* mag_paperauthoraffiliations => jd: gcp_cset_mag.PaperAuthorAffiliations
* mag_papers => jd: gcp_cset_mag.Papers
* mag_paperlanguages => jd: this doesn't exist?

*/


-- Table of institutions, with several boolean columns
-- for the different heuristics for it being from US / China
create or replace view institutions as
select *,
  -- Heuristics for US
  (officialpage LIKE '%.com' or officialpage LIKE '%.com/') as dotcom,
  (officialpage LIKE '%.edu' or officialpage LIKE '%.edu/') as dotedu,
  -- Heuristics for China
  (officialpage LIKE '%.cn' or officialpage LIKE '%.cn/') as dotcn,
  (officialpage LIKE '%.hk' or officialpage LIKE '%.hk/') as dothk,
  (case
    when TRIM(normalizedname) like '% china%' then true
    when TRIM(normalizedname) like '%china %' then true
    when TRIM(normalizedname) like '% chinese%' then true
    when TRIM(normalizedname) like '%chinese %' then true
    else false end) as china_name,
  (case
    when TRIM(normalizedname) like '%beijing%' then true
    when TRIM(normalizedname) like '%shanghai%' then true
    when TRIM(normalizedname) like '%tsinghua%' then true
    when TRIM(normalizedname) like '%tianjin%' then true
    when TRIM(normalizedname) like '%wuhan%' then true
    when TRIM(normalizedname) like '%huazhong%' then true
    when TRIM(normalizedname) like '%zhejiang%' then true
    when TRIM(normalizedname) like '%xidian%' then true
    when TRIM(normalizedname) like '%nanjing%' then true
    when TRIM(normalizedname) like '%shandong%' then true
    when TRIM(normalizedname) like '%shenzhen%' then true
    else false end) as china_city
from gcp_cset_mag.Affiliations;

-- All author/paper pairs, along with country heuristics for the author
create or replace view paper_authors_w_countries as
select "PaperId", "AuthorId",
    -- US
    bool_or(dotcom) as dotcom,
    bool_or(dotedu) as dotedu,
    -- China
    bool_or(dotcn) as dotcn,
    bool_or(dothk) as dothk,
    bool_or(china_name) as china_name,
    bool_or(china_city) as china_city
from gcp_cset_mag.PaperAuthorAffiliations auths
left outer join institutions i
on auths.AffiliationId=i.AffiliationId
group by "AuthorId", "PaperId"
create table paper_authors_w_countries_table as select * from paper_authors_w_countries;

--
-- This is the main table!
--
create or replace view ai_papers_any_author as
select p.*,
  dotcom, dotedu,
  dotcn, dothk, china_name, china_city, (langs."PaperId" is not null) as china_language
-- Only look at conference or journal papers
from (select *,
    (case when trim("year")='' then null
        when "year" ~ '^[0-9]{4}$' then "year"::int
        else null end) as yr
    from mag_papers
    where "doc type" in ('Conference', 'Journal')
) p
-- Only look at AI papers
join (
    select "paper id"
    from gcp_cset_mag.PaperFieldsOfStudy
    where "FieldOfStudyId" = '154945302'
) pfos
on p.PaperId=pfos.PaperId
-- Author affiliation-based country heuristics.  True if ANY author has heauristic
join (
    select "PaperId",
      bool_or(dotcom) as dotcom, bool_or(dotedu) as dotedu,
      bool_or(dotcn) as dotcn, bool_or(dothk) as dothk,
      bool_or(china_name) as china_name, bool_or(china_city) as china_city
     from paper_authors_w_countries_table
     group by PaperId
) auths
on p."PaperId"=auths."PaperId"
--
left outer join (
    select distinct "PaperId" from mag_paperlanguages
    where "language code" like 'zh_chs%'
) langs
on p."PaperId"=langs."PaperId"
;
create table ai_papers_any_author_table as select * from ai_papers_any_author;
GRANT SELECT ON ai_papers_any_author_table TO johnconnor;

-- Used for finding top istitutions
create table paper_author_institution_table as
select p."PaperId",
    p."EstimatedCitationCount"::int as "EstimatedCitationCount",
    pa."AuthorId",
    i."AffiliationId", i.DisplayName, i.OfficialPage
from ai_papers_any_author_table p
join gcp_cset_mag.PaperAuthorAffiliations pa
on p."PaperId"=pa."PaperId"
join institutions i
on pa."AffiliationId"=i."AffiliationId";

create table ai_papers_institutions as
select pac.*
from paper_authors_w_countries_table pac
join mag_paperauthoraffiliations pa
on pa."PaperId"=p."PaperId";
select displayname from ai_papers_institutions where dotcom order by random() limit 20;
