SELECT 'fact_row_missing_in_dim' AS check_name, COUNT(*) AS failed_records
FROM `xkcd-case-study-493421.xkcd_analytics.fact_comic_metrics` f
LEFT JOIN `xkcd-case-study-493421.xkcd_analytics.dim_comic` d
  ON f.comic_id = d.comic_id
WHERE d.comic_id IS NULL

UNION ALL

SELECT 'invalid_cost_logic' AS check_name, COUNT(*) AS failed_records
FROM `xkcd-case-study-493421.xkcd_analytics.fact_comic_metrics` f
JOIN `xkcd-case-study-493421.xkcd_analytics.dim_comic` d
  ON f.comic_id = d.comic_id
WHERE f.cost_eur != d.title_letter_count * 5;