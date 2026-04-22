CREATE OR REPLACE TABLE `xkcd-case-study-493421.xkcd_analytics.fact_comic_metrics` AS
SELECT
  comic_id,

  -- stable pseudo-random views between 0 and 10000
  CAST(
    MOD(ABS(FARM_FINGERPRINT(CONCAT(CAST(comic_id AS STRING), '_views'))), 10001)
    AS INT64
  ) AS views,

  -- stable pseudo-random review score between 1.00 and 10.00
  ROUND(
    1 + (
      MOD(ABS(FARM_FINGERPRINT(CONCAT(CAST(comic_id AS STRING), '_review'))), 901) / 100.0
    ),
    2
  ) AS review_score,

  -- cost = title letters * 5 euros
  title_letter_count * 5 AS cost_eur

FROM `xkcd-case-study-493421.xkcd_analytics.dim_comic`;