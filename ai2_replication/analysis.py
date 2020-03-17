from pathlib import Path

import pandas as pd
from matplotlib import pyplot as plt
from scipy import stats

from settings import PROJECT_ID

REPLICATION_DIR = Path('./ai2_replication')
BQ_EXPORT_PATH = REPLICATION_DIR / 'ai_papers_any_author.pkl.gz'
CITATION_COUNT_FIELD = "EstimatedCitation"
FIGURE_PATH = REPLICATION_DIR / 'output'

# [ai2]: Pull down table of AI papers from Redshift, and add on columns for the final US/China heuristics and the
# cutoffs for levels of how much a paper is cited.
if BQ_EXPORT_PATH.exists():
    df = pd.read_pickle(BQ_EXPORT_PATH, compression='gzip')
else:
    df = pd.read_gbq('select * from ai2_replication.ai_papers_any_author '
                     'where extract(year from CreatedDate) < 2019 '
                     '  and extract(year from CreatedDate) > 1980',
                     project_id=PROJECT_ID)
    df.to_pickle(BQ_EXPORT_PATH, compression='gzip')

# [jd] We already subset by year, above, but it doesn't seem effective
df = df.loc[(df['yr'] > 1980) & (df['yr'] < 2019)]

df["citation_count"] = df[CITATION_COUNT_FIELD].astype(int)
df["citation_count"].value_counts()

df['china'] = df.dotcn.astype(bool) | df.dothk.astype(bool) \
              | df.china_name.astype(bool) | df.china_language.astype(bool) \
              | df.china_city.astype(bool)
df['us'] = df.dotedu.astype(bool) | df.dotedu.astype(bool)
df['top_half_cutoff'] = df.groupby('yr').citation_count.transform(lambda x: (x - x) + x.quantile(0.5))
df['top_tenth_cutoff'] = df.groupby('yr').citation_count.transform(lambda x: (x - x) + x.quantile(0.9))
df['top_twentieth_cutoff'] = df.groupby('yr').citation_count.transform(lambda x: (x - x) + x.quantile(0.95))
df['top_hundredth_cutoff'] = df.groupby('yr').citation_count.transform(lambda x: (x - x) + x.quantile(0.99))
df['top_halfpercent_cutoff'] = df.groupby('yr').citation_count.transform(lambda x: (x - x) + x.quantile(0.995))

# JD: Write the final analysis table back to BQ
cutoffs = ['half', 'tenth', 'twentieth', 'hundredth', 'halfpercent']
bq_cols = ['PaperId', 'yr', 'china', 'us', 'citation_count'] + [f'top_{stub}' for stub in cutoffs]
# JD: nb these columns weren't in the original dataframe
for stub in ['half', 'tenth', 'twentieth', 'hundredth', 'halfpercent']:
    df[f'top_{stub}'] = df['citation_count'] > df[f'top_{stub}_cutoff']
df[bq_cols].to_gbq('ai2_replication.analysis', project_id=PROJECT_ID, if_exists='replace')

# What's this (x - x) business above?
for col, q in zip(
        ['top_half_cutoff', 'top_tenth_cutoff', 'top_twentieth_cutoff', 'top_hundredth_cutoff',
         'top_halfpercent_cutoff'],
        [0.5, .9, .95, .99, .995]):
    assert (df[col] == df.groupby('yr').citation_count.transform(lambda x: x.quantile(q))).all()

plt.close()
sums = df.groupby('yr').china.sum()
ax1 = sums.plot(label="# Papers", color='b')
ax1.set_xlabel('');
ax1.set_ylabel('# Papers')
ax2 = ax1.twinx()
df[df.citation_count > df.top_tenth_cutoff].groupby('yr').china.mean().plot(label='Top 10%', ax=ax2, color='g',
                                                                            style='--')
df[df.citation_count <= df.top_half_cutoff].groupby('yr').china.mean().plot(label='Bottom Half', ax=ax2, color='r',
                                                                            style='--')
ax2.set_xlabel('');
ax2.set_ylabel('Market Shares')
ax2.set_xlim([1980, 2018])
plt.title("China's Drop was in Bad Papers")
plt.minorticks_on()
plt.legend()
plt.savefig(FIGURE_PATH / 'chinas_drop_vs_market_share.png')

# Raw number of papers
plt.close()
ax1 = df.groupby('yr').china.sum().plot(label='China')
ax2 = df.groupby('yr').us.sum().plot(label='US')
plt.title('All AI Papers')
ax2.set_xlim([1980, 2018])
plt.legend();
plt.xlabel('');
plt.ylabel('# Papers')
plt.minorticks_on()
plt.savefig(FIGURE_PATH / 'all_papers.png')

# Market share for different levels of citation
cutoffcol_title_pairs = [
    ('top_half_cutoff', 'Share of Papers in the Top 50%'),
    ('top_twentieth_cutoff', 'Share of Papers in the Top 10% '),
    ('top_halfpercent_cutoff', 'Share of Papers in the Top 1%')
]
xlim = [1981, 2025]
ylim = [0.0, .75]
for cutoffcol, title in cutoffcol_title_pairs:
    print(title)
    # Create time series for each country
    china_ts = df[df.citation_count > df[cutoffcol]].groupby('yr').china.mean()
    us_ts = df[df.citation_count > df[cutoffcol]].groupby('yr').us.mean()
    # fit lines to last 4 years
    china_slope, china_intercept, r_value, p_value, std_err = stats.linregress([2015, 2016, 2017, 2018], china_ts[-4:])
    us_slope, us_intercept, r_value, p_value, std_err = stats.linregress([2015, 2016, 2017, 2018], us_ts[-4:])
    intercept_year = (china_intercept - us_intercept) / (us_slope - china_slope)
    # Compute interpolations to plot
    fit_years = pd.Series(range(2014, 2026), index=range(2014, 2026))
    china_fit = fit_years * china_slope + china_intercept
    us_fit = fit_years * us_slope + us_intercept
    # Save a CSV
    pd.DataFrame({'China': china_ts, 'US': us_ts,
                  'China Fit': china_fit, 'US Fit': us_fit}).to_csv(FIGURE_PATH / f'{title}.csv')
    # Plot
    plt.close()
    ax1 = china_ts.plot(label='China')
    ax2 = us_ts.plot(label='US')
    ax1.set_xlim(xlim)
    ax2.set_xlim(xlim)
    # ax1.set_ylim(ylim)
    # ax2.set_ylim(ylim)
    china_fit = china_fit.plot(style='--', label='China Fit')
    us_fit = us_fit.plot(style='--', label='US Fit')
    china_fit.set_xlim(xlim)
    # china_fit.set_ylim(ylim)
    us_fit.set_xlim(xlim)
    # us_fit.set_ylim(ylim)
    # china_fit.set_ylim(ylim)
    # us_fit.set_ylim(ylim)
    plt.title(title + ' : Intercept in ' + str(int(intercept_year)))
    plt.legend();
    plt.xlabel('');
    plt.ylabel('Market Share')
    plt.minorticks_on()
    plt.savefig(FIGURE_PATH / f'{title}.png')
