/* 
Creates a final one-row-per-claim reporting table for Power BI.
The master claim table is deduplicated before joining to the activity rollup
to prevent reserve amounts from being overstated in final reporting.
*/

CREATE OR REPLACE TABLE `portfolio-data-analysis-495222.portfolio_data.cat_claim_profile_final` AS

WITH master_dedup AS (
  SELECT * EXCEPT(row_num)
  FROM (
    SELECT
      m.*,
      ROW_NUMBER() OVER (
        PARTITION BY claim_id
        ORDER BY
          CASE WHEN open_reserve_flag = 'Yes' THEN 1 ELSE 0 END DESC,
          reserve_amount DESC,
          incurred_amount DESC
      ) AS row_num
    FROM `portfolio-data-analysis-495222.portfolio_data.cat_claims_master_v2_clean_table` m
  )
  WHERE row_num = 1
),

activity_rollup AS (
  SELECT
    claim_id,
    MAX(CASE WHEN escalation_flag = 'Yes' THEN 1 ELSE 0 END) AS has_escalation,
    MAX(CASE WHEN litigation_referral_flag = 'Yes' THEN 1 ELSE 0 END) AS has_litigation,
    MAX(CASE WHEN coverage_review_flag = 'Yes' THEN 1 ELSE 0 END) AS has_coverage_review,
    MAX(CASE WHEN documentation_complete = 'No' THEN 1 ELSE 0 END) AS has_incomplete_docs,
    MAX(CASE WHEN supplement_number > 0 THEN 1 ELSE 0 END) AS has_supplement,
    MAX(inspection_delay_days) AS max_inspection_delay_days,
    MAX(vendor_cycle_days) AS max_vendor_cycle_days,
    COUNT(*) AS activity_count
  FROM `portfolio-data-analysis-495222.portfolio_data.cat_claim_activity_v2_clean`
  GROUP BY claim_id
)

SELECT
  m.claim_id,
  m.state,
  m.region,
  m.catastrophe_type,
  m.line_of_business,
  m.claim_status,
  m.open_reserve_flag,
  m.reserve_amount,
  m.paid_amount,
  m.incurred_amount,
  m.assigned_team,
  UPPER(TRIM(m.assigned_adjuster_id)) AS assigned_adjuster_id,

  COALESCE(ar.has_escalation, 0) AS has_escalation,
  COALESCE(ar.has_litigation, 0) AS has_litigation,
  COALESCE(ar.has_coverage_review, 0) AS has_coverage_review,
  COALESCE(ar.has_incomplete_docs, 0) AS has_incomplete_docs,
  COALESCE(ar.has_supplement, 0) AS has_supplement,

  COALESCE(ar.max_inspection_delay_days, 0) AS max_inspection_delay_days,
  COALESCE(ar.max_vendor_cycle_days, 0) AS max_vendor_cycle_days,
  COALESCE(ar.activity_count, 0) AS activity_count

FROM master_dedup m
LEFT JOIN activity_rollup ar
  ON m.claim_id = ar.claim_id;
