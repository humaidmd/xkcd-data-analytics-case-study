SELECT COUNT(*) AS total_rows
FROM `xkcd-case-study-493421.xkcd_analytics.dim_comic`;

SELECT COUNT(*) AS null_comic_id_count
FROM `xkcd-case-study-493421.xkcd_analytics.dim_comic`
WHERE comic_id IS NULL;

SELECT comic_id, COUNT(*) AS cnt
FROM `xkcd-case-study-493421.xkcd_analytics.dim_comic`
GROUP BY comic_id
HAVING COUNT(*) > 1;

SELECT COUNT(*) AS null_published_date_count
FROM `xkcd-case-study-493421.xkcd_analytics.dim_comic`
WHERE published_date IS NULL;

SELECT COUNT(*) AS null_title_count
FROM `xkcd-case-study-493421.xkcd_analytics.dim_comic`
WHERE title IS NULL;

SELECT COUNT(*) AS invalid_title_letter_count
FROM `xkcd-case-study-493421.xkcd_analytics.dim_comic`
WHERE title_letter_count < 0;