SELECT 'null_comic_id' AS check_name, COUNT(*) AS failed_records
FROM `xkcd-case-study-493421.xkcd_analytics.dim_comic`
WHERE comic_id IS NULL

UNION ALL

SELECT 'duplicate_comic_id' AS check_name, COUNT(*) AS failed_records
FROM (
  SELECT comic_id
  FROM `xkcd-case-study-493421.xkcd_analytics.dim_comic`
  GROUP BY comic_id
  HAVING COUNT(*) > 1
)

UNION ALL

SELECT 'null_published_date' AS check_name, COUNT(*) AS failed_records
FROM `xkcd-case-study-493421.xkcd_analytics.dim_comic`
WHERE published_date IS NULL

UNION ALL

SELECT 'null_title' AS check_name, COUNT(*) AS failed_records
FROM `xkcd-case-study-493421.xkcd_analytics.dim_comic`
WHERE title IS NULL

UNION ALL

SELECT 'invalid_title_letter_count' AS check_name, COUNT(*) AS failed_records
FROM `xkcd-case-study-493421.xkcd_analytics.dim_comic`
WHERE title_letter_count < 0;