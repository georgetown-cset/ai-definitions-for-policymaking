-- Table of institutions, with several boolean columns
-- for the different heuristics for it being from US / China
select *,
       -- Heuristics for US
       (OfficialPage like '%.com' or OfficialPage like '%.com/') as dotcom,
       (OfficialPage like '%.edu' or OfficialPage like '%.edu/') as dotedu,
       -- Heuristics for China
       (OfficialPage like '%.cn' or OfficialPage like '%.cn/')   as dotcn,
       (OfficialPage like '%.hk' or OfficialPage like '%.hk/')   as dothk,
       (case
            when TRIM(NormalizedName) like '% china%' then true
            when TRIM(NormalizedName) like '%china %' then true
            when TRIM(NormalizedName) like '% chinese%' then true
            when TRIM(NormalizedName) like '%chinese %' then true
            else false end)                                      as china_name,
       (case
            when TRIM(NormalizedName) like '%beijing%' then true
            when TRIM(NormalizedName) like '%shanghai%' then true
            when TRIM(NormalizedName) like '%tsinghua%' then true
            when TRIM(NormalizedName) like '%tianjin%' then true
            when TRIM(NormalizedName) like '%wuhan%' then true
            when TRIM(NormalizedName) like '%huazhong%' then true
            when TRIM(NormalizedName) like '%zhejiang%' then true
            when TRIM(NormalizedName) like '%xidian%' then true
            when TRIM(NormalizedName) like '%nanjing%' then true
            when TRIM(NormalizedName) like '%shandong%' then true
            when TRIM(NormalizedName) like '%shenzhen%' then true
            else false end)                                      as china_city
from gcp_cset_mag.Affiliations

