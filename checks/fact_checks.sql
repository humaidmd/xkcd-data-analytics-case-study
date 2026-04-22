SELECT 'null_comic_id' AS check_name, COUNT(*) AS failed_records
FROM `xkcd-case-study-493421.xkcd_analytics.fact_comic_metrics`
WHERE comic_id IS NULL

UNION ALL

SELECT 'duplicate_comic_id' AS check_name, COUNT(*) AS failed_records
FROM (
  SELECT comic_id
  FROM `xkcd-case-study-493421.xkcd_analytics.fact_comic_metrics`
  GROUP BY comic_id
  HAVING COUNT(*) > 1
)

UNION ALL

SELECT 'invalid_views' AS check_name, COUNT(*) AS failed_records
FROM `xkcd-case-study-493421.xkcd_analytics.fact_comic_metrics`
WHERE views < 0 OR views > 10000

UNION ALL

SELECT 'invalid_review_score' AS check_name, COUNT(*) AS failed_records
FROM `xkcd-case-study-493421.xkcd_analytics.fact_comic_metrics`
WHERE review_score < 1 OR review_score > 10

UNION ALL

SELECT 'invalid_cost_eur' AS check_name, COUNT(*) AS failed_records
FROM `xkcd-case-study-493421.xkcd_analytics.fact_comic_metrics`
WHERE cost_eur < 0;