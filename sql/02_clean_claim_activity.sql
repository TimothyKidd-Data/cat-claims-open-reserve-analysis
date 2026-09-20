
/* Objective: Create a clean activity table while preserving the raw source data.
Transformations:
- Removed currency symbols and commas from financial columns and cast values to FLOAT64.
- Cast count, delay, and supplement fields to INT64.
- Standardized flag fields into Yes/No format.
- Standardized activity owner team, activity status, communication channel, and payment type values.
*/
CREATE OR REPLACE TABLE `portfolio-data-analysis-495222.portfolio_data.cat_claim_activity_v2_clean` AS
SELECT
  * EXCEPT(
    payment_amount,
    reserve_change_amount,
    current_reserve_after_activity,
    supplement_number,
    reopened_flag,
    escalation_flag,
    customer_contact_count,
    inbound_call_count,
    outbound_call_count,
    inspection_delay_days,
    vendor_cycle_days,
    coverage_review_flag,
    documentation_complete,
    estimate_received_flag,
    litigation_referral_flag,
    subrogation_potential,
    recovery_amount,
    salvage_amount,
    deductible_collected,
    activity_owner_team,
    activity_status,
    communication_channel,
    payment_type
  ),
  ROUND(SAFE_CAST(REGEXP_REPLACE(CAST(payment_amount AS STRING), r'[^0-9.-]', '') AS FLOAT64), 2) AS payment_amount,
  ROUND(SAFE_CAST(REGEXP_REPLACE(CAST(reserve_change_amount AS STRING), r'[^0-9.-]', '') AS FLOAT64), 2) AS reserve_change_amount,
  ROUND(SAFE_CAST(REGEXP_REPLACE(CAST(current_reserve_after_activity AS STRING), r'[^0-9.-]', '') AS FLOAT64), 2) AS current_reserve_after_activity,
  ROUND(SAFE_CAST(REGEXP_REPLACE(CAST(recovery_amount AS STRING), r'[^0-9.-]', '') AS FLOAT64), 2) AS recovery_amount,
  ROUND(SAFE_CAST(REGEXP_REPLACE(CAST(salvage_amount AS STRING), r'[^0-9.-]', '') AS FLOAT64), 2) AS salvage_amount,
  ROUND(SAFE_CAST(REGEXP_REPLACE(CAST(deductible_collected AS STRING), r'[^0-9.-]', '') AS FLOAT64), 2) AS deductible_collected,
  SAFE_CAST(REGEXP_REPLACE(CAST(supplement_number AS STRING), r'[^0-9-]', '') AS INT64) AS supplement_number,
  SAFE_CAST(REGEXP_REPLACE(CAST(customer_contact_count AS STRING), r'[^0-9-]', '') AS INT64) AS customer_contact_count,
  SAFE_CAST(REGEXP_REPLACE(CAST(inbound_call_count AS STRING), r'[^0-9-]', '') AS INT64) AS inbound_call_count,
  SAFE_CAST(REGEXP_REPLACE(CAST(outbound_call_count AS STRING), r'[^0-9-]', '') AS INT64) AS outbound_call_count,
  SAFE_CAST(REGEXP_REPLACE(CAST(inspection_delay_days AS STRING), r'[^0-9-]', '') AS INT64) AS inspection_delay_days,
  SAFE_CAST(REGEXP_REPLACE(CAST(vendor_cycle_days AS STRING), r'[^0-9-]', '') AS INT64) AS vendor_cycle_days,
  /* Standardizes reopened_flag values after DISTINCT validation identified mixed Yes/No, Y/N, True/False, and 1/0 formats. */
  CASE
    WHEN UPPER(TRIM(CAST(reopened_flag AS STRING))) IN ('1', 'YES', 'Y', 'TRUE') THEN 'Yes'
    WHEN UPPER(TRIM(CAST(reopened_flag AS STRING))) IN ('0', 'NO', 'N', 'FALSE') THEN 'No'
    ELSE 'Review'
  END AS reopened_flag,
  /* Standardizes escalation_flag values after DISTINCT validation identified mixed Yes/No, Y/N, True/False, and 1/0 formats. */
  CASE
    WHEN UPPER(TRIM(CAST(escalation_flag AS STRING))) IN ('1', 'YES', 'Y', 'TRUE') THEN 'Yes'
    WHEN UPPER(TRIM(CAST(escalation_flag AS STRING))) IN ('0', 'NO', 'N', 'FALSE') THEN 'No'
    ELSE 'Review'
  END AS escalation_flag,
  /* Standardizes coverage_review_flag values after DISTINCT validation identified mixed Yes/No, Y/N, True/False, and 1/0 formats. */
  CASE
    WHEN UPPER(TRIM(CAST(coverage_review_flag AS STRING))) IN ('1', 'YES', 'Y', 'TRUE') THEN 'Yes'
    WHEN UPPER(TRIM(CAST(coverage_review_flag AS STRING))) IN ('0', 'NO', 'N', 'FALSE') THEN 'No'
    ELSE 'Review'
  END AS coverage_review_flag,
  /* Standardizes documentation_complete values after DISTINCT validation identified mixed Yes/No, Y/N, True/False, and 1/0 formats. */
  CASE
    WHEN UPPER(TRIM(CAST(documentation_complete AS STRING))) IN ('1', 'YES', 'Y', 'TRUE') THEN 'Yes'
    WHEN UPPER(TRIM(CAST(documentation_complete AS STRING))) IN ('0', 'NO', 'N', 'FALSE') THEN 'No'
    ELSE 'Review'
  END AS documentation_complete,
  /* Standardizes estimate_received_flag values after DISTINCT validation identified mixed Yes/No, Y/N, True/False, and 1/0 formats. */
  CASE
    WHEN UPPER(TRIM(CAST(estimate_received_flag AS STRING))) IN ('1', 'YES', 'Y', 'TRUE') THEN 'Yes'
    WHEN UPPER(TRIM(CAST(estimate_received_flag AS STRING))) IN ('0', 'NO', 'N', 'FALSE') THEN 'No'
    ELSE 'Review'
  END AS estimate_received_flag,
  /* Standardizes litigation_referral_flag values after DISTINCT validation identified mixed Yes/No, Y/N, True/False, and 1/0 formats. */
  CASE
    WHEN UPPER(TRIM(CAST(litigation_referral_flag AS STRING))) IN ('1', 'YES', 'Y', 'TRUE') THEN 'Yes'
    WHEN UPPER(TRIM(CAST(litigation_referral_flag AS STRING))) IN ('0', 'NO', 'N', 'FALSE') THEN 'No'
    ELSE 'Review'
  END AS litigation_referral_flag,
  /* Standardizes subrogation_potential values after DISTINCT validation identified mixed Yes/No, Y/N, True/False, and 1/0 formats. */
  CASE
    WHEN UPPER(TRIM(CAST(subrogation_potential AS STRING))) IN ('1', 'YES', 'Y', 'TRUE') THEN 'Yes'
    WHEN UPPER(TRIM(CAST(subrogation_potential AS STRING))) IN ('0', 'NO', 'N', 'FALSE') THEN 'No'
    ELSE 'Review'
  END AS subrogation_potential,
  /* Standardizes activity_owner_team values after DISTINCT validation identified inconsistent capitalization and leading/trailing spaces. */
  CASE
    WHEN UPPER(TRIM(activity_owner_team)) = 'TEAM ALPHA' THEN 'Team Alpha'
    WHEN UPPER(TRIM(activity_owner_team)) = 'TEAM BETA' THEN 'Team Beta'
    WHEN UPPER(TRIM(activity_owner_team)) = 'TEAM GAMMA' THEN 'Team Gamma'
    WHEN UPPER(TRIM(activity_owner_team)) = 'TEAM DELTA' THEN 'Team Delta'
    WHEN UPPER(TRIM(activity_owner_team)) = 'TEAM ECHO' THEN 'Team Echo'
    WHEN UPPER(TRIM(activity_owner_team)) = 'TEAM GULF' THEN 'Team Gulf'
    WHEN UPPER(TRIM(activity_owner_team)) = 'TEAM WEST' THEN 'Team West'
    WHEN UPPER(TRIM(activity_owner_team)) = 'TEAM CENTRAL' THEN 'Team Central'
    ELSE 'Review'
  END AS activity_owner_team,
  /* Standardizes activity_status values after DISTINCT validation identified inconsistent capitalization and leading/trailing spaces. */
  CASE
    WHEN UPPER(TRIM(activity_status)) = 'OPEN' THEN 'Open'
    WHEN UPPER(TRIM(activity_status)) = 'PENDING' THEN 'Pending'
    WHEN UPPER(TRIM(activity_status)) = 'COMPLETED' THEN 'Completed'
    WHEN UPPER(TRIM(activity_status)) = 'CLOSED' THEN 'Closed'
    WHEN UPPER(TRIM(activity_status)) = 'REVIEW NEEDED' THEN 'Review Needed'
    ELSE 'Review'
  END AS activity_status,
  /* Standardizes communication_channel values after DISTINCT validation identified inconsistent capitalization and leading/trailing spaces. */
  CASE
    WHEN UPPER(TRIM(communication_channel)) = 'EMAIL' THEN 'Email'
    WHEN UPPER(TRIM(communication_channel)) = 'PHONE' THEN 'Phone'
    WHEN UPPER(TRIM(communication_channel)) = 'SMS' THEN 'SMS'
    WHEN UPPER(TRIM(communication_channel)) = 'LETTER' THEN 'Letter'
    WHEN UPPER(TRIM(communication_channel)) = 'PORTAL' THEN 'Portal'
    WHEN UPPER(TRIM(communication_channel)) = 'VENDOR PORTAL' THEN 'Vendor Portal'
    ELSE 'Review'
  END AS communication_channel,
  /* Standardizes payment_type values after DISTINCT validation identified inconsistent capitalization and leading/trailing spaces. */
  CASE
    WHEN UPPER(TRIM(payment_type)) = 'NO PAYMENT' THEN 'No Payment'
    WHEN UPPER(TRIM(payment_type)) = 'EXPENSE' THEN 'Expense'
    WHEN UPPER(TRIM(payment_type)) = 'INDEMNITY' THEN 'Indemnity'
    WHEN UPPER(TRIM(payment_type)) = 'MEDICAL' THEN 'Medical'
    WHEN UPPER(TRIM(payment_type)) = 'SALVAGE' THEN 'Salvage'
    WHEN UPPER(TRIM(payment_type)) = 'RENTAL' THEN 'Rental'
    ELSE 'Review'
  END AS payment_type
FROM `portfolio-data-analysis-495222.portfolio_data.cat_claim_activity_v2_raw`;
