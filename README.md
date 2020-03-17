## Overview

> We use data from three sources in this analysis: Clarivate Web of Science (WOS), Digital Science Dimensions, and Microsoft Academic Graph (MAG). This analysis includes all unique English-language articles from 2010-2019 for which a title and abstract is available.
>
> Citation counts are important in our analysis because we focus on the top one percent of most-cited articles. For articles that appeared in more than one dataset, we chose to use the largest citation count for each (usually from MAG), on the assumption that the smaller counts (usually from the other, smaller datasets) probably omitted citations[...] Also, when ranking articles by citation count, we encountered ties among articles for inclusion in the top percentile. Rather than arbitrarily break the ties, we included all tied articles, producing more consistent results.
>
> The three datasets also differ in the information they provide about the institutional affiliations of authors. We use this metadata in our analysis above to identify the country or countries with which we should associate a paper. The shares of global output that we report for China, the EU, and the US include articles where at least one author has an institutional affiliation in one of these countries or regions, in any dataset, and no author has an affiliation in the remaining two, in any dataset. For example, a paper with one Chinese author and one U.S. author would be counted in the output share for neither country. 
>
> Most articles in the analysis are available in more than one of our three datasets[...] Articles often appear more than once within any of these sources. Articles within each dataset have some degree of incomplete metadata, and even relatively unambiguous fields like publication year occasionally have discrepancies across datasets for what otherwise appear to be the same article. To deduplicate, we normalize titles, abstracts, and author last names, and then consider each group of articles within or across datasets that share at least three of the following (non-null) metadata fields to correspond to one article in the merged dataset: normalized title; normalized abstract; publication year; normalized author last names (for within-dataset matches); and digital object identifier (DOI).

## Reproducibility

This repo contains the code to reproduce our analysis, but not all necessary data.
Some of this data is under license, e.g., from Digital Science and Clarivate.
We also use the results of applying a keyword search, the Elsevier classifier, and SciBERT models to a deduplicated corpus of Dimensions, MAG, and WoS publications.
Please get in contact if you have any questions about replication.

The basis for most of our results is the table `comparison`, which compares the results from alternative classification methods.
It relies on many upstream tables, which you can trace back from `./sql/comparison.sql`.

Workflow: 
 
1. Run `tables.py` to create the required BQ tables;
2. Run `analysis.py` to pull from various tables and write results to the `./analysis` directory.

