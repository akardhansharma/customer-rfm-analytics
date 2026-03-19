 -- STEP 1 append all monthly sales tables together
 CREATE OR REPLACE TABLE `the-rfm-analysis.sales.sales_2025` AS
 SELECT * FROM `the-rfm-analysis.sales.sales202501` 
 UNION ALL SELECT * FROM `the-rfm-analysis.sales.sales202502`
 UNION ALL SELECT * FROM `the-rfm-analysis.sales.sales202503`
 UNION ALL SELECT * FROM `the-rfm-analysis.sales.sales202504`
 UNION ALL SELECT * FROM `the-rfm-analysis.sales.sales202505`
 UNION ALL SELECT * FROM `the-rfm-analysis.sales.sales202506`
 UNION ALL SELECT * FROM `the-rfm-analysis.sales.sales202507`
 UNION ALL SELECT * FROM `the-rfm-analysis.sales.sales202508`
 UNION ALL SELECT * FROM `the-rfm-analysis.sales.sales202509`
 UNION ALL SELECT * FROM `the-rfm-analysis.sales.sales202510`
 UNION ALL SELECT * FROM `the-rfm-analysis.sales.sales202511`
 UNION ALL SELECT * FROM `the-rfm-analysis.sales.sales202512`;

-- STEP 2 : calculate recency , frequency , monetary , r, f, m ranks
-- COMBINE views with CTEs

CREATE OR REPLACE VIEW `the-rfm-analysis.sales.rfm_metrics`
AS
WITH current_date AS (
  SELECT DATE ('2026-03-09') AS analysis_date -- today's date
),
rfm AS (
  SELECT
    CustomerID,
    MAX(OrderDate) AS last_order_date,
    date_diff((SELECT analysis_date FROM current_date),MAX(OrderDate),DAY) AS recency,
    COUNT(*) AS frequency,
    SUM(OrderValue) AS monetary
  FROM `the-rfm-analysis.sales.sales_2025`
  GROUP BY CustomerID
)
SELECT 
  rfm.*,
  ROW_NUMBER() OVER(ORDER BY recency ASC) AS r_rank,
  ROW_NUMBER() OVER(ORDER BY rfm.frequency DESC) AS f_rank,
  ROW_NUMBER() OVER(ORDER BY rfm.monetary DESC) AS m_rank
FROM rfm;


-- STEP 3 : Asigning deciles(10=best 1=worst)
CREATE OR REPLACE VIEW `the-rfm-analysis.sales.rfm_scores`
AS
SELECT
  *,
  NTILE(10) OVER(ORDER BY r_rank DESC) AS r_score,
  NTILE(10) OVER(ORDER BY f_rank DESC) AS f_score,
  NTILE(10) OVER(ORDER BY m_rank DESC) AS m_score
FROM `the-rfm-analysis.sales.rfm_metrics`;


--STEP 4 : TOTAL SCORES
CREATE OR REPLACE VIEW `the-rfm-analysis.sales.rfm_total_scores`
AS
SELECT
  CustomerID,
  recency,
  frequency,
  monetary,
  r_score,
  f_score,
  m_score,
  (r_score + f_score +m_score) AS rfm_total_score

FROM `the-rfm-analysis.sales.rfm_scores`
ORDER BY rfm_total_score DESC;

--STEP5 : BI ready rfm segments table
CREATE OR REPLACE TABLE `the-rfm-analysis.sales.rfm_final_segments`
AS
SELECT 
  CustomerID,
  recency,
  frequency,
  monetary,
  r_score,
  f_score,
  m_score,rfm_total_score,
  CASE
    WHEN rfm_total_score >=28 THEN 'Champions'
    WHEN rfm_total_score >=24 THEN 'Loyal VIPs'
    WHEN rfm_total_score >=20 THEN 'High Potential'
    WHEN rfm_total_score >=16 THEN 'Emerging/Promising'
    WHEN rfm_total_score >=12 THEN 'Needs Nurturing'
    WHEN rfm_total_score >=8 THEN 'At Risk'
    WHEN rfm_total_score >=4 THEN 'Dormant'
    ELSE 'Lost/Inactive'
    END AS rfm_segment

FROM `the-rfm-analysis.sales.rfm_total_scores`
ORDER BY rfm_total_score DESC;
