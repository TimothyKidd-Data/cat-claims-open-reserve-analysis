/* 
Validation queries for the CAT Claims Open Reserve Analysis project.

These checks confirm that the final Power BI reporting table has one row per claim,
that open-reserve totals tie back to dashboard metrics, and that the main operational
indicator fields are available for reporting.
*/


-- 1. Validate final table row count and unique claim count.
-- Purpose: Confirms the final reporting table is one row per claim.

SELECT
  COUNT(*) AS row_count,
  COUNT(DISTINCT claim_id) AS unique_claim_count,
  COUNT(*) - COUNT(DISTINCT claim_id) AS duplicate_claim_rows
FROM `portfolio-data-analysis-495222.portfolio_data.cat_claim_profile_final`;


-- 2. Validate reserve totals by open reserve flag.
-- Purpose: Confirms total reserves and open-reserve claim counts used in Power BI.

SELECT
  open_reserve_flag,
  COUNT(DISTINCT claim_id) AS claim_count,
  ROUND(SUM(reserve_amount), 2) AS total_reserves,
  ROUND(AVG(reserve_amount), 2) AS avg_reserve
FROM `portfolio-data-analysis-495222.portfolio_data.cat_claim_profile_final`
GROUP BY
  open_reserve_flag
ORDER BY
  open_reserve_flag;


-- 3. Validate open reserve totals by catastrophe type.
-- Purpose: Confirms Page 1 reserve-pressure totals by CAT type.

SELECT
  catastrophe_type,
  COUNT(DISTINCT claim_id) AS open_reserve_claims,
  ROUND(SUM(reserve_amount), 2) AS total_open_reserves,
  ROUND(AVG(reserve_amount), 2) AS avg_open_reserve
FROM `portfolio-data-analysis-495222.portfolio_data.cat_claim_profile_final`
WHERE
  open_reserve_flag = 'Yes'
GROUP BY
  catastrophe_type
ORDER BY
  total_open_reserves DESC;


-- 4. Validate operational indicator counts for open-reserve claims.
-- Purpose: Confirms escalation, litigation, supplement, coverage review, and documentation indicators are available for reporting.

SELECT
  SUM(has_escalation) AS escalated_claims,
  SUM(has_litigation) AS litigation_claims,
  SUM(has_supplement) AS supplement_claims,
  SUM(has_coverage_review) AS coverage_review_claims,
  SUM(has_incomplete_docs) AS incomplete_documentation_claims
FROM `portfolio-data-analysis-495222.portfolio_data.cat_claim_profile_final`
WHERE
  open_reserve_flag = 'Yes';


-- 5. Validate state-level open reserve totals.
-- Purpose: Confirms map and geographic workload visuals tie back to the final reporting table.

SELECT
  state,
  COUNT(DISTINCT claim_id) AS open_reserve_claims,
  ROUND(SUM(reserve_amount), 2) AS total_open_reserves
FROM `portfolio-data-analysis-495222.portfolio_data.cat_claim_profile_final`
WHERE
  open_reserve_flag = 'Yes'
GROUP BY
  state
ORDER BY
  total_open_reserves DESC;
