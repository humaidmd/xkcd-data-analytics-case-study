from datetime import datetime
import time

from airflow import DAG
from airflow.operators.python import PythonOperator

from src.xkcd_loader import run_incremental_load
from src.bq_sql_runner import run_sql_file, run_check_file

POLL_INTERVAL_SECONDS = 1800
MAX_POLL_ATTEMPTS = 24

def poll_and_load_raw():
    """
    Runs on Monday, Wednesday, Friday.
    Checks if a new comic is available.
    If not, waits and checks again.
    If yes, loads only the missing comic(s) into raw.
    """
    for attempt in range(1, MAX_POLL_ATTEMPTS + 1):
        result = run_incremental_load()
        print(f"Polling attempt {attempt}: {result}")

        if result["rows_loaded"] > 0:
            print("New comic loaded successfully.")
            return result

        if attempt < MAX_POLL_ATTEMPTS:
            print(f"No new comic yet. Waiting {POLL_INTERVAL_SECONDS // 60} minutes...")
            time.sleep(POLL_INTERVAL_SECONDS)

    raise ValueError("No new comic appeared within the polling window.")


def refresh_staging():
    run_sql_file("sql", "stg_xkcd_comics.sql")


def refresh_dim():
    run_sql_file("sql", "dim_comic.sql")


def refresh_fact():
    run_sql_file("sql", "fact_comic_metrics.sql")


def run_all_checks():
    run_check_file("dim_checks.sql")
    run_check_file("fact_checks.sql")
    run_check_file("relationship_checks.sql")


with DAG(
    dag_id="xkcd_pipeline",
    start_date=datetime(2026, 4, 18),
    schedule="0 9 * * 1,3,5",   # 9 AM on Monday, Wednesday, Friday
    catchup=False,
    tags=["xkcd", "bigquery", "airflow"],
) as dag:

    poll_and_load_raw_task = PythonOperator(
        task_id="poll_and_load_raw",
        python_callable=poll_and_load_raw,
    )

    refresh_staging_task = PythonOperator(
        task_id="refresh_staging",
        python_callable=refresh_staging,
    )

    refresh_dim_task = PythonOperator(
        task_id="refresh_dim",
        python_callable=refresh_dim,
    )

    refresh_fact_task = PythonOperator(
        task_id="refresh_fact",
        python_callable=refresh_fact,
    )

    run_all_checks_task = PythonOperator(
        task_id="run_all_checks",
        python_callable=run_all_checks,
    )

    (
        poll_and_load_raw_task
        >> refresh_staging_task
        >> refresh_dim_task
        >> refresh_fact_task
        >> run_all_checks_task
    )