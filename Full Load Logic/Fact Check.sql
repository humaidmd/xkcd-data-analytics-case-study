SELECT COUNT(*) AS total_rows
FROM `xkcd-case-study-493421.xkcd_analytics.fact_comic_metrics`;

SELECT COUNT(*) AS null_comic_id_count
FROM `xkcd-case-study-493421.xkcd_analytics.fact_comic_metrics`
WHERE comic_id IS NULL;

SELECT COUNT(*) AS failed_records
FROM (
  SELECT comic_id
  FROM `xkcd-case-study-493421.xkcd_analytics.fact_comic_metrics`
  GROUP BY comic_id
  HAVING COUNT(*) > 1
);


SELECT COUNT(*) AS failed_records
FROM `xkcd-case-study-493421.xkcd_analytics.fact_comic_metrics`
WHERE views < 0 OR views > 10000;


SELECT COUNT(*) AS failed_records
FROM `xkcd-case-study-493421.xkcd_analytics.fact_comic_metrics`
WHERE review_score < 1 OR review_score > 10;


SELECT COUNT(*) AS failed_records
FROM `xkcd-case-study-493421.xkcd_analytics.fact_comic_metrics`
WHERE cost_eur < 0;

