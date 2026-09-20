/* 
Identifies open-reserve claims that had both supplement activity and escalation activity,
even if those events occurred on different activity records.
*/

WITH activity_rollup AS (
  SELECT
    claim_id,
    MAX(CASE WHEN supplement_number > 0 THEN 1 ELSE 0 END) AS has_supplement,
    MAX(CASE WHEN escalation_flag = 'Yes' THEN 1 ELSE 0 END) AS has_escalation
  FROM `portfolio-data-analysis-495222.portfolio_data.cat_claim_activity_v2_clean`
  GROUP BY
    claim_id
)

SELECT
  m.assigned_team AS team,
  m.state,
  COUNT(DISTINCT m.claim_id) AS claims
FROM `portfolio-data-analysis-495222.portfolio_data.cat_claims_master_v2_clean_table` m
INNER JOIN activity_rollup ar
  ON m.claim_id = ar.claim_id
WHERE
  m.open_reserve_flag = 'Yes'
  AND ar.has_supplement = 1
  AND ar.has_escalation = 1
GROUP BY
  m.assigned_team,
  m.state
ORDER BY
  claims DESC;
