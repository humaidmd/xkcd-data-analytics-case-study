import json
from datetime import datetime, UTC
from urllib.request import urlopen

from google.cloud import bigquery


RAW_TABLE_ID = "xkcd-case-study-493421.xkcd_raw.raw_xkcd_comics"
LATEST_COMIC_URL = "https://xkcd.com/info.0.json"


def get_bq_client():
    return bigquery.Client()


def get_latest_api_comic_id():
    with urlopen(LATEST_COMIC_URL) as response:
        data = json.load(response)
    return int(data["num"])


def get_latest_loaded_comic_id(client, table_id=RAW_TABLE_ID):
    query = f"""
    SELECT COALESCE(MAX(comic_id), 0) AS max_comic_id
    FROM `{table_id}`
    """
    result = list(client.query(query).result())[0]
    return int(result.max_comic_id)


def fetch_comic(comic_id):
    url = f"https://xkcd.com/{comic_id}/info.0.json"
    with urlopen(url) as response:
        data = json.load(response)
    return data, url


def build_raw_row(data, source_url):
    return {
        "comic_id": int(data["num"]),
        "month": int(data["month"]),
        "day": int(data["day"]),
        "year": int(data["year"]),
        "title": data["title"],
        "safe_title": data["safe_title"],
        "alt": data["alt"],
        "img_url": data["img"],
        "transcript": data["transcript"],
        "news": data["news"],
        "link": data["link"],
        "published_date": f'{data["year"]}-{int(data["month"]):02d}-{int(data["day"]):02d}',
        "fetched_at": datetime.now(UTC).isoformat(),
        "source_url": source_url,
        "raw_json": json.dumps(data),
    }


def load_rows_to_bigquery(client, rows, table_id=RAW_TABLE_ID):
    if not rows:
        return 0

    job = client.load_table_from_json(rows, table_id)
    job.result()
    return len(rows)


def run_incremental_load(table_id=RAW_TABLE_ID):
    client = get_bq_client()

    latest_loaded = get_latest_loaded_comic_id(client, table_id)
    latest_api = get_latest_api_comic_id()

    rows_to_load = []

    for comic_id in range(latest_loaded + 1, latest_api + 1):
        try:
            data, source_url = fetch_comic(comic_id)
            row = build_raw_row(data, source_url)
            rows_to_load.append(row)
        except Exception as e:
            raise RuntimeError(f"Failed to fetch comic {comic_id}: {e}")

    loaded_count = load_rows_to_bigquery(client, rows_to_load, table_id)

    return {
        "latest_loaded_before_run": latest_loaded,
        "latest_api_comic_id": latest_api,
        "rows_loaded": loaded_count,
    }


if __name__ == "__main__":
    result = run_incremental_load()
    print(result)