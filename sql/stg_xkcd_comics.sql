CREATE OR REPLACE VIEW `xkcd-case-study-493421.xkcd_analytics.stg_xkcd_comics` AS
WITH deduped AS (
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
  TRIM(title) AS title,
  NULLIF(TRIM(safe_title), '') AS safe_title,
  NULLIF(TRIM(alt), '') AS alt,
  NULLIF(TRIM(img_url), '') AS img_url,
  NULLIF(TRIM(transcript), '') AS transcript,
  NULLIF(TRIM(news), '') AS news,
  NULLIF(TRIM(link), '') AS link,
  published_date,
  year,
  month,
  day,
  fetched_at,
  LENGTH(REGEXP_REPLACE(TRIM(title), r'[^A-Za-z]', '')) AS title_letter_count
FROM deduped
WHERE rn = 1;