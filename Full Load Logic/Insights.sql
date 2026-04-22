SELECT
  COUNT(*) AS total_comics,
  ROUND(AVG(f.views), 2) AS avg_views,
  ROUND(AVG(f.review_score), 2) AS avg_review_score,
  ROUND(SUM(f.cost_eur), 2) AS total_cost_eur,
  ROUND(AVG(f.cost_eur), 2) AS avg_cost_eur
FROM `xkcd-case-study-493421.xkcd_analytics.fact_comic_metrics` f;


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
LIMIT 5;


SELECT
  d.title,
  d.published_date,
  f.review_score,
  f.views,
  f.cost_eur
FROM `xkcd-case-study-493421.xkcd_analytics.dim_comic` d
JOIN `xkcd-case-study-493421.xkcd_analytics.fact_comic_metrics` f
  ON d.comic_id = f.comic_id
ORDER BY f.review_score DESC, f.views DESC
LIMIT 10;

SELECT
  d.title,
  d.title_letter_count,
  f.cost_eur,
  f.views,
  f.review_score
FROM `xkcd-case-study-493421.xkcd_analytics.dim_comic` d
JOIN `xkcd-case-study-493421.xkcd_analytics.fact_comic_metrics` f
  ON d.comic_id = f.comic_id
ORDER BY f.cost_eur DESC
LIMIT 10;

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
LIMIT 5;


SELECT
  d.title,
  d.published_date,
  f.views,
  f.review_score,
  f.cost_eur
FROM `xkcd-case-study-493421.xkcd_analytics.dim_comic` d
JOIN `xkcd-case-study-493421.xkcd_analytics.fact_comic_metrics` f
  ON d.comic_id = f.comic_id
ORDER BY d.published_date DESC
LIMIT 10;

SELECT
  d.publish_year,
  COUNT(*) AS total_comics,
  ROUND(AVG(f.views), 2) AS avg_views,
  ROUND(AVG(f.review_score), 2) AS avg_review_score,
  ROUND(SUM(f.cost_eur), 2) AS total_cost_eur
FROM `xkcd-case-study-493421.xkcd_analytics.dim_comic` d
JOIN `xkcd-case-study-493421.xkcd_analytics.fact_comic_metrics` f
  ON d.comic_id = f.comic_id
GROUP BY d.publish_year
ORDER BY d.publish_year;