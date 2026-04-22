CREATE OR REPLACE TABLE `xkcd-case-study-493421.xkcd_analytics.dim_comic` AS
SELECT
  comic_id,
  title,
  safe_title,
  alt,
  img_url,
  transcript,
  news,
  link,
  published_date,
  year AS publish_year,
  month AS publish_month,
  day AS publish_day,
  title_letter_count
FROM `xkcd-case-study-493421.xkcd_analytics.stg_xkcd_comics`;

SELECT COUNT(*) AS total_rows
FROM `xkcd-case-study-493421.xkcd_analytics.dim_comic`;

SELECT *
FROM `xkcd-case-study-493421.xkcd_analytics.dim_comic`
LIMIT 10;