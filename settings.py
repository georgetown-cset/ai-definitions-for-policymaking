from pathlib import Path

# Dataset holding analytic outputs - for historical reasons it's "oecd" here; if changing this, also update references
# in ./sql/*.sql
DATASET = 'oecd'

PROJECT_ID = 'gcp-cset-projects'

SQL_DIR = Path(__file__).parent / 'sql'
OUTPUT_DIR = Path(__file__).parent / 'data' / 'output'

CITATION_PERCENTILES = [50, 90, 95, 98, 99, 100]
