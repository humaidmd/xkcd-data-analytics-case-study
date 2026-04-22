# XKCD Comics Data Pipeline – Template

This document is a **template** for the XKCD comics data pipeline README.  It follows the same structure as the final README but leaves blank sections where you can insert the actual SQL queries, Python code, screenshots and query outputs.  The general context is preserved so that once you fill in the placeholders, the document becomes a comprehensive project handoff.

XKCD publishes new comics three times per week—on **Monday**, **Wednesday** and **Friday**:contentReference[oaicite:0]{index=0}—and exposes a simple JSON interface for each comic:contentReference[oaicite:1]{index=1}.  The pipeline described here is designed to ingest these comics, clean the data, build warehouse tables and expose analytics.  Replace all sections marked “TODO” with your real implementation.

## Repository Overview

The repository is organised into a few top‑level directories:

| Folder | Purpose |
| --- | --- |
| **src/** | Contains Python scripts for ingesting comics from the XKCD API and interacting with BigQuery. |
| **dags/** | Airflow/Cloud Composer DAG definitions and helper modules. |
| **sql/** | Parameterised SQL used for staging tables and core models. |
| **checks/** | SQL assertions used to verify data quality and relationships. |

### Key Scripts and SQL Files

Below is a short explanation of the most important files and how they fit into the pipeline.  These descriptions can remain unchanged; fill in any additional details as needed.

| File | What it does | Where it fits / Why it matters |
| --- | --- | --- |
| **`src/xkcd_loader.py`** | A Python module that calls the XKCD JSON API, downloads new comics and writes them to BigQuery.  It keeps track of the highest comic ID already loaded and only fetches missing comics.  If a fetch fails or returns unexpected data, the loader raises an error to prevent partial loads. | Runs as part of the `poll_and_load_raw` task.  Ensures that `raw_xkcd_comics` contains exactly one row per comic with complete metadata. |
| **`dags/src/xkcd_loader.py`** | A thin wrapper around the loader that makes it callable from Airflow.  It provides hooks for logging and passes runtime configuration (e.g. project ID, dataset names, API timeouts). | Imported by the `xkcd_pipeline_dag.py` DAG to perform ingestion in a scheduled fashion. |
| **`dags/src/bq_sql_runner.py`** | Utility module that executes parameterised SQL files against BigQuery.  It abstracts away the Airflow `BigQueryInsertJobOperator` setup and allows SQL to be stored cleanly under `sql/`. | Used by staging, dimension and fact tasks to run SQL without embedding long queries in the DAG code. |
| **`sql/stg_xkcd_comics.sql`** | SQL script that reads from `raw_xkcd_comics`, deduplicates records, trims text fields, converts empty strings to NULL and computes additional attributes like `title_letter_count`. | Defines the *staging* layer (`stg_xkcd_comics`), preparing clean data for downstream models. |
| **`sql/dim_comic.sql`** | Builds the `dim_comic` dimension table from staging.  It selects descriptive fields about each comic (title, alt text, publication date) and applies type casting and default values. | Forms the core lookup table used by fact models and business queries. |
| **`sql/fact_comic_metrics.sql`** | Generates the `fact_comic_metrics` fact table.  It synthesises a deterministic view count and review score from the comic ID, calculates `cost_eur` from the title length and joins to the dimension. | Provides measurable metrics (views, review_score, cost) for analytics and KPIs. |
| **`checks/dim_checks.sql`** | Contains assertions for the `dim_comic` table, such as ensuring the ID is unique, publication dates are not null and that titles exist. | Helps detect data quality issues in the dimension layer before facts reference it. |
| **`checks/fact_checks.sql`** | Data quality checks for `fact_comic_metrics`.  Examples include verifying that synthetic `views` and `review_score` are non‑negative and that all fact rows have matching dimension keys. | Prevents analytics from operating on corrupted or missing metrics. |
| **`checks/relationship_checks.sql`** | Cross‑table checks enforcing referential integrity between facts and dimensions.  For instance, it ensures there are no orphaned fact rows and that every dimension row has a corresponding fact. | Ensures the warehouse remains internally consistent and that joins produce correct results. |
| **`dags/xkcd_pipeline_dag.py`** | The Airflow DAG definition that orchestrates the pipeline.  It defines tasks for polling the API, running SQL transformations and executing quality checks.  The DAG is scheduled according to XKCD’s update cadence. | The control centre of the pipeline; without this DAG the individual scripts and SQL wouldn’t run automatically. |

## Code Flow Overview

At a high level the pipeline follows these steps:

1. **Load raw comics into `raw_xkcd_comics`.**  The loader fetches the current max comic ID from BigQuery, calls the XKCD API for any comics with higher IDs, and appends the new rows.  Failed loads raise an exception to stop downstream tasks.
2. **Clean and deduplicate in `stg_xkcd_comics`.**  The staging SQL trims strings, replaces empty strings with `NULL`, deduplicates by `comic_id` using the most recent `fetched_at` timestamp and computes derived columns (e.g. letter counts).
3. **Build the `dim_comic` dimension.**  This model selects canonical attributes from the staging table, applies type conversions and fills in default values for missing fields.
4. **Build the `fact_comic_metrics` table.**  Using deterministic functions of `comic_id`, this model generates synthetic metrics (views, review score, cost) and joins them back to the dimension.  In a real pipeline this would come from analytics sources; for demonstration purposes it is derived data.
5. **Run grouped quality checks.**  The checks in `checks/` verify uniqueness, not‑null constraints, numerical ranges and referential integrity.  Any failure will cause the DAG to stop and mark the run as failed.
6. **Query business outputs.**  Once the tables are populated and validated, downstream analysts can run KPI and other analytical queries to extract insights.  Examples are given below.

## Representative Python Logic

This section should include a short, readable code example showing how the loader fetches new comics, compares IDs and writes to BigQuery.  Replace the placeholder below with your own pseudocode or simplified real code.

```python
# TODO: Insert the Python loader logic here.
# The code should:
# 1. Query BigQuery for the current maximum comic_id in raw_xkcd_comics.
# 2. Use requests to get the latest comic via https://xkcd.com/info.0.json.
# 3. Compare latest_id to the maximum and fetch any missing comics one by one via https://xkcd.com/<id>/info.0.json.
# 4. Insert the new rows into BigQuery.