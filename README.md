# XKCD Data & Analytics Case Study on GCP

This project pulls XKCD comic data from the public API, stores it in BigQuery, cleans it in a staging layer, builds a small analytics model, and automates the flow with Cloud Composer.

The goal of the case study was not just to load raw data, but to turn it into something business-facing. In this version, the final model supports comic-level metrics such as views, review score, and estimated creation cost, along with grouped data quality checks and scheduled orchestration.

---

## What this project does

At a high level, the pipeline does five things:

1. Fetches XKCD comic data from the API and stores it in a raw BigQuery table
2. Cleans and standardizes the raw records in a staging view
3. Builds a simple star schema for analytics
4. Runs grouped data quality checks
5. Produces business-facing outputs through SQL queries

---

## Project details

**Project name**
`xkcd-case-study`

**Project ID**
`xkcd-case-study-493421`

**BigQuery datasets**

* `xkcd_raw`
* `xkcd_analytics`

**Main objects**

* `xkcd_raw.raw_xkcd_comics`
* `xkcd_analytics.stg_xkcd_comics`
* `xkcd_analytics.dim_comic`
* `xkcd_analytics.fact_comic_metrics`

---

## Architecture summary

The flow is straightforward:

```text
XKCD API
  → raw_xkcd_comics
  → stg_xkcd_comics
  → dim_comic + fact_comic_metrics
  → business SQL queries

Cloud Composer orchestrates ingestion, refresh, and data quality checks.
```
<img width="1500" height="844" alt="image" src="https://github.com/user-attachments/assets/2162edc3-ddb1-46b7-ad95-c164757c190c" />

---

## Repository structure

```text
.
├── README.md
├── src/
├── dags/
├── sql/
├── checks/
├── docs/
└── presentation/
```

### Folder guide

* `src/`
  Python code for ingestion logic

* `dags/`
  Airflow / Cloud Composer DAG and helper modules

* `sql/`
  SQL used for staging and model builds

* `checks/`
  SQL quality checks for dimensions, facts, and relationships

* `docs/`
  Architecture images, ER diagram screenshots, DAG screenshots, and query output screenshots

* `presentation/`
  Final presentation deck used for the case study submission

<img width="1010" height="484" alt="image" src="https://github.com/user-attachments/assets/b0789141-3ebf-4be6-8fa8-e1585cf2f53f" />

---

## End-to-end pipeline flow

The pipeline was built in this order:

### 1. Raw ingestion

The first step was creating a raw BigQuery table and proving ingestion worked with a single-row test.

After that, I ran a full historical backfill to load all available XKCD comics into the raw table.

### 2. Incremental ingestion

Once the historical load was in place, I added incremental logic to fetch only new comics that were not already loaded.

The loader:

* checks the highest `comic_id` already in BigQuery
* checks the latest comic ID from the XKCD API
* fetches only missing IDs
* fails the task if a comic cannot be fetched or loaded unexpectedly

That fail-fast behavior was intentional. I did not want the pipeline to silently skip a comic and continue as if nothing happened.

### 3. Staging

The raw data is cleaned in a staging view. This is where duplicates are removed, blank strings are normalized to `NULL`, and `title_letter_count` is derived for later cost calculation.

### 4. Gold model

From staging, the data is split into:

* `dim_comic` for descriptive comic attributes
* `fact_comic_metrics` for business measures

The fact table is kept at **one row per comic**.

### 5. Quality checks

Grouped SQL checks validate:

* dimension integrity
* fact integrity
* dim-fact relationships

### 6. Business outputs

Once the model is refreshed and validated, SQL queries can be run directly on the gold tables for KPI summaries and rankings.

---

## Raw layer

### `raw_xkcd_comics`

This table keeps the original source payload as close to the API response as possible, while also adding a few fields that help with traceability.

Main fields:

* `comic_id`
* `month`
* `day`
* `year`
* `title`
* `safe_title`
* `alt`
* `img_url`
* `transcript`
* `news`
* `link`
* `published_date`
* `fetched_at`
* `source_url`
* `raw_json`

Why I kept this layer simple:

* it preserves source context
* it makes debugging easier
* it gives a clean starting point for downstream transformations

<img width="1913" height="854" alt="image" src="https://github.com/user-attachments/assets/ac211910-9b9d-4ff7-bd90-c954bc18eaa3" />

---

## Core ingestion logic

The historical load came first. Incremental logic was added only after the raw ingestion pattern was proven.

At a high level, the loader works like this:

```python
def load_new_comics():
    max_comic_id = get_max_comic_id_from_bigquery()
    latest_comic_id = get_latest_comic_id_from_xkcd()

    if latest_comic_id <= max_comic_id:
        raise RuntimeError("No new comic appeared within the polling window.")

    rows_to_insert = []

    for comic_id in range(max_comic_id + 1, latest_comic_id + 1):
        comic = fetch_comic_from_api(comic_id)
        if comic is None:
            raise RuntimeError(f"Failed to fetch comic {comic_id}")

        rows_to_insert.append(transform_raw_comic(comic))

    insert_rows_into_bigquery(rows_to_insert)
```

This is the part that matters most:

* only missing comics are fetched
* unexpected errors fail the task
* missing data is not silently skipped

### Key ingestion files

#### `src/xkcd_loader.py`

Main Python loader for fetching comics and writing raw rows into BigQuery.

#### `dags/src/xkcd_loader.py`

Composer-friendly version of the loader used by Airflow tasks.

---

## Staging layer

### `stg_xkcd_comics`

The staging layer is implemented as a view:

`xkcd-case-study-493421.xkcd_analytics.stg_xkcd_comics`

Why I used a view instead of a physical staging table:

* it kept development simpler
* it was fast to refresh while iterating
* the case study did not require a separate materialized staging layer

### What the staging view does

* reads from `raw_xkcd_comics`
* deduplicates by `comic_id` using the latest `fetched_at`
* trims text fields
* converts blank strings to `NULL`
* computes `title_letter_count`

Representative staging logic:

```sql
WITH ranked AS (
  SELECT
    *,
    ROW_NUMBER() OVER (
      PARTITION BY comic_id
      ORDER BY fetched_at DESC
    ) AS rn
  FROM `xkcd-case-study-493421.xkcd_raw.raw_xkcd_comics`
)
SELECT
  comic_id,
  NULLIF(TRIM(title), '') AS title,
  published_date,
  LENGTH(NULLIF(TRIM(title), '')) AS title_letter_count
FROM ranked
WHERE rn = 1;
```

This is where the raw API payload becomes clean and predictable enough for analytics.

#### SQL file

* `sql/stg_xkcd_comics.sql`

<img width="1914" height="863" alt="image" src="https://github.com/user-attachments/assets/66c9b83d-055d-4e6e-a064-50a1870fe003" />

---

## Data model

The final model is a small star schema.

### `dim_comic`

This table stores descriptive comic attributes.

Main fields:

* `comic_id`
* `title`
* `safe_title`
* `alt`
* `img_url`
* `transcript`
* `news`
* `link`
* `published_date`
* `publish_year`
* `publish_month`
* `publish_day`
* `title_letter_count`

#### SQL file

* `sql/dim_comic.sql`

### `fact_comic_metrics`

This table stores comic-level measures.

Fields:

* `comic_id`
* `views`
* `review_score`
* `cost_eur`

Grain:

* **one row per comic**

#### SQL file

* `sql/fact_comic_metrics.sql`

### Why I chose this model

I kept the model intentionally simple:

* `dim_comic` holds descriptive fields
* `fact_comic_metrics` holds measures
* the join key is `comic_id`

This was easier to explain and query than one wide reporting table, and it fit the case study scope better than a more elaborate warehouse design.

<img width="1294" height="844" alt="image" src="https://github.com/user-attachments/assets/b7c0c4c9-0b5f-4fba-a763-d0986b011628" />

---

## Metric generation logic

The case study asked for three business-facing metrics:

* views
* review score
* cost

### Cost

Cost follows the business rule directly:

```sql
cost_eur = title_letter_count * 5
```

### Views and review score

Views and review score were generated using **deterministic pseudo-random logic** based on `comic_id`.

That choice was intentional.

I did not use true random values because true random changes on every rerun. That makes outputs unstable and harder to test, compare, or present. Deterministic pseudo-random values still look random enough for the case study, but stay stable across reruns.

Representative fact logic:

```sql
SELECT
  comic_id,
  ABS(MOD(FARM_FINGERPRINT(CAST(comic_id AS STRING)), 10001)) AS views,
  ROUND(1 + ABS(MOD(FARM_FINGERPRINT(CONCAT(CAST(comic_id AS STRING), '-review')), 901)) / 100, 2) AS review_score,
  title_letter_count * 5 AS cost_eur
FROM `xkcd-case-study-493421.xkcd_analytics.stg_xkcd_comics`;
```

---

## Data quality checks

Quality checks are grouped into three SQL files.

### `checks/dim_checks.sql`

Used for dimension-level validations such as:

* null `comic_id`
* duplicate `comic_id`
* null `published_date`
* null `title`
* invalid `title_letter_count`

Example:

```sql
SELECT
  'duplicate_comic_id_in_dim' AS check_name,
  COUNT(*) AS failed_records
FROM (
  SELECT comic_id
  FROM `xkcd-case-study-493421.xkcd_analytics.dim_comic`
  GROUP BY comic_id
  HAVING COUNT(*) > 1
);
```

### `checks/fact_checks.sql`

Used for fact-level validations such as:

* null `comic_id`
* duplicate `comic_id`
* invalid `views`
* invalid `review_score`
* invalid `cost_eur`

Example:

```sql
SELECT
  'invalid_review_score_range' AS check_name,
  COUNT(*) AS failed_records
FROM `xkcd-case-study-493421.xkcd_analytics.fact_comic_metrics`
WHERE review_score < 1 OR review_score > 10;
```

### `checks/relationship_checks.sql`

Used for cross-table validations such as:

* every fact row exists in the dimension
* `fact.cost_eur = dim.title_letter_count * 5`

Example:

```sql
SELECT
  'cost_logic_mismatch' AS check_name,
  COUNT(*) AS failed_records
FROM `xkcd-case-study-493421.xkcd_analytics.fact_comic_metrics` f
JOIN `xkcd-case-study-493421.xkcd_analytics.dim_comic` d
  ON f.comic_id = d.comic_id
WHERE f.cost_eur != d.title_letter_count * 5;
```

### Check pattern

Each check returns:

* `check_name`
* `failed_records`

Interpretation:

* `0` = pass
* `> 0` = fail

This pattern made it easy to automate validation inside the DAG.

<img width="1918" height="634" alt="image" src="https://github.com/user-attachments/assets/aa795c1b-427e-41c1-9cd2-921d6c49a08e" />

---

## Airflow / Cloud Composer orchestration

The pipeline is orchestrated in Cloud Composer.

### Main DAG file

* `dags/xkcd_pipeline_dag.py`

### Supporting files

* `dags/src/xkcd_loader.py`
* `dags/src/bq_sql_runner.py`
* `dags/sql/*`
* `dags/checks/*`

### DAG tasks

```text
poll_and_load_raw
  -> refresh_staging
  -> refresh_dim
  -> refresh_fact
  -> run_all_checks
```

### Schedule

* Monday / Wednesday / Friday
* 9:00 AM

### Important behavior

Polling logic lives inside the first task.

If no new comic appears within the polling window:

* the first task fails by design
* downstream tasks do not run

That behavior was deliberate. It makes it obvious that no new source data was available, instead of letting the run continue silently.

### `bq_sql_runner.py`

This helper is used to run SQL files from the `sql/` and `checks/` folders. It also fails the task if any quality check returns `failed_records > 0`.

---

## Manual DAG test result

I triggered the DAG manually in Composer as part of the case study.

What happened:

* the DAG was deployed correctly
* the first task executed from a technical point of view
* the run failed with: **“No new comic appeared within the polling window.”**

That was not a system failure. It confirmed that the polling logic worked as intended and that downstream tasks were correctly blocked when no new source data was available.

This ended up being a useful validation of the fail-fast behavior.

---

## How to run the project

This section should be adjusted to match your exact final repository setup. Replace the placeholders below where needed.

### 1. Create the BigQuery datasets

Create these datasets in the target GCP project:

* `xkcd_raw`
* `xkcd_analytics`

### 2. Create the raw table

Create `raw_xkcd_comics` in the `xkcd_raw` dataset using your final schema.

### 3. Run the historical load

Run the ingestion code once to:

* test a single comic insert
* then backfill all available comics into `raw_xkcd_comics`

### 4. Build the staging view

Run the staging SQL:

* `sql/stg_xkcd_comics.sql`

### 5. Build the gold tables

Run:

* `sql/dim_comic.sql`
* `sql/fact_comic_metrics.sql`

### 6. Run the quality checks

Run:

* `checks/dim_checks.sql`
* `checks/fact_checks.sql`
* `checks/relationship_checks.sql`

### 7. Deploy to Cloud Composer

Upload the DAG and supporting files to the Composer environment:

* `dags/xkcd_pipeline_dag.py`
* `dags/src/*`
* `dags/sql/*`
* `dags/checks/*`

Also make sure the required Python dependency is available:

* `google-cloud-bigquery`

### 8. Trigger the DAG

You can either:

* wait for the Monday / Wednesday / Friday schedule
* or trigger the DAG manually from the Airflow UI

<img width="1839" height="535" alt="image" src="https://github.com/user-attachments/assets/fc2466fa-39dd-4748-ac22-ebbb11e4a1f4" />

---

## Example business outputs

No dashboard was built for this case study. Instead, business outputs were produced directly through SQL on the gold tables.

### KPI summary

```sql
SELECT
  COUNT(*) AS total_comics,
  ROUND(AVG(f.views), 2) AS avg_views,
  ROUND(AVG(f.review_score), 2) AS avg_review_score,
  ROUND(SUM(f.cost_eur), 2) AS total_cost_eur,
  ROUND(AVG(f.cost_eur), 2) AS avg_cost_eur
FROM `xkcd-case-study-493421.xkcd_analytics.fact_comic_metrics` f;
```

Result:

* `total_comics = 3233`
* `avg_views = 5010.79`
* `avg_review_score = 5.50`
* `total_cost_eur = 197180.0`
* `avg_cost_eur = 60.99`

### Top comics by views

```sql
SELECT
  d.title,
  d.published_date,
  f.views,
  f.review_score,
  f.cost_eur
FROM `xkcd-case-study-493421.xkcd_analytics.dim_comic` d
JOIN `xkcd-case-study-493421.xkcd_analytics.fact_comic_metrics` f
  ON d.comic_id = f.comic_id
ORDER BY f.views DESC
LIMIT 10;
```

Top 5:

* Rembrandt Photo — 9998
* A Better Idea — 9998
* Language Development — 9998
* Frogger — 9994
* Future Archaeology — 9992

### Best value-for-money comics

```sql
SELECT
  d.title,
  f.views,
  f.cost_eur,
  ROUND(f.views / NULLIF(f.cost_eur, 0), 2) AS views_per_euro,
  f.review_score
FROM `xkcd-case-study-493421.xkcd_analytics.dim_comic` d
JOIN `xkcd-case-study-493421.xkcd_analytics.fact_comic_metrics` f
  ON d.comic_id = f.comic_id
ORDER BY views_per_euro DESC
LIMIT 10;
```

Examples:

* d65536 — 6704 views — €5 cost — 1340.8 views per euro
* 1 to 10 — 9261 views — €10 cost — 926.1 views per euro
* X — 4527 views — €5 cost — 905.4 views per euro

<img width="1918" height="773" alt="image" src="https://github.com/user-attachments/assets/51894898-01af-4fb9-a14d-52e50e41dc76" />

<img width="1865" height="747" alt="image" src="https://github.com/user-attachments/assets/25a60846-5f58-4cc3-91fb-13e0fe396e40" />

---

## Tradeoffs and design decisions

A few choices were made deliberately to keep the solution practical and aligned with the case study.

### BigQuery SQL over dbt

I used plain BigQuery SQL for transformations because it was faster to deliver within the case study timeline. If this were extended further, dbt would be the next step.

### Simple star schema

I chose a straightforward dimension/fact split instead of one large reporting table. That made the model easier to explain, query, and validate.

### Deterministic pseudo-random metrics

Views and review score were generated in a way that stays stable across reruns. That made testing and presentation much easier than using true random values.

### Manual SQL outputs instead of a dashboard

I focused on answering the business questions directly rather than spending time building a reporting layer.

### Broader IAM during setup

I used broader access during setup to move faster in GCP. In a production version, I would tighten that down significantly.

### Limited real-world test window

The Composer test did not catch a newly published comic, but it still proved that the polling logic and fail-fast behavior worked.

---

## Future improvements

If I took this further, these would be the next steps:

* move transformation logic and tests into dbt
* add BI dashboards for KPI tracking and reporting
* tighten IAM and Composer permissions
* add monitoring and alerting
* introduce a date dimension if reporting grows
* tune polling and retry behavior

---

## Notes

This project was built to satisfy the case study requirements while keeping the implementation simple enough to explain clearly. Where possible, I preferred explicit logic and readable SQL over extra tooling.

If you are reviewing this repository, the best places to start are:

1. this README
2. the DAG file
3. the staging and model SQL
4. the quality checks

---
