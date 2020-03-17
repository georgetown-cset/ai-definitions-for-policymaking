select distinct(en_2010_2020.id),
               ds.times_cited
from oecd.en_2010_2020 en_2010_2020
         inner join analysis_friendly.cset_gold_all_dimensions_publications ds on ds.id = en_2010_2020.id
where en_2010_2020.dataset = 'ds'
