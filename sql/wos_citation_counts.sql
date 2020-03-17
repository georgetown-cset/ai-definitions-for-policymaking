select distinct(en_2010_2020.id),
               wos.times_cited
from oecd.en_2010_2020 en_2010_2020
         inner join oecd.cset_gold_all_wos_20200219 wos on wos.id = en_2010_2020.id
where en_2010_2020.dataset = 'wos'
