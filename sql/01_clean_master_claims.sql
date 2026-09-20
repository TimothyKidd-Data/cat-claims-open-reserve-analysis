
/* Objective: Create a clean master table while preserving the raw source data.
Transformations:
- Removed currency symbols and commas from financial columns and cast values to FLOAT64.
- Standardized inconsistent state names into 2-letter uppercase abbreviations.
- Standardized open_reserve_flag values into Yes/No format.
- Standardized catastrophe_type and line_of_business values for consistent category analysis.
- Cleaned customer, date, region, county, event, coverage, status, severity, team, flag, and vehicle status fields.
*/
CREATE OR REPLACE TABLE `portfolio-data-analysis-495222.portfolio_data.cat_claims_master_v2_clean_table` AS
SELECT
  * EXCEPT(
    reserve_amount,
    paid_amount,
    incurred_amount,
    deductible_amount,
    insured_name,
    loss_date,
    reported_date,
    first_contact_date,
    state,
    region,
    county,
    open_reserve_flag,
    catastrophe_type,
    cat_event_name,
    line_of_business,
    coverage_type,
    claim_status,
    claim_severity,
    assigned_team,
    inspection_completed,
    days_to_first_contact,
    legal_involved,
    injury_indicator,
    vehicle_drivable
  ),
  ROUND(SAFE_CAST(REGEXP_REPLACE(CAST(reserve_amount AS STRING), r'[^0-9.-]', '') AS FLOAT64), 2) AS reserve_amount,
  ROUND(SAFE_CAST(REGEXP_REPLACE(CAST(paid_amount AS STRING), r'[^0-9.-]', '') AS FLOAT64), 2) AS paid_amount,
  ROUND(SAFE_CAST(REGEXP_REPLACE(CAST(incurred_amount AS STRING), r'[^0-9.-]', '') AS FLOAT64), 2) AS incurred_amount,
  ROUND(SAFE_CAST(REGEXP_REPLACE(CAST(deductible_amount AS STRING), r'[^0-9.-]', '') AS FLOAT64), 2) AS deductible_amount,
  /* Standardizes insured_name values after validation identified inconsistent capitalization and leading/trailing spaces. */
  INITCAP(TRIM(CAST(insured_name AS STRING))) AS insured_name,
  /* Standardizes date fields after validation identified mixed MM/DD/YYYY and Mon DD YYYY formats. */
  COALESCE(
    SAFE.PARSE_DATE('%Y-%m-%d', TRIM(CAST(loss_date AS STRING))),
    SAFE.PARSE_DATE('%m/%d/%Y', TRIM(CAST(loss_date AS STRING))),
    SAFE.PARSE_DATE('%b %d %Y', TRIM(CAST(loss_date AS STRING))),
    SAFE.PARSE_DATE('%B %d %Y', TRIM(CAST(loss_date AS STRING)))
  ) AS loss_date,
  COALESCE(
    SAFE.PARSE_DATE('%Y-%m-%d', TRIM(CAST(reported_date AS STRING))),
    SAFE.PARSE_DATE('%m/%d/%Y', TRIM(CAST(reported_date AS STRING))),
    SAFE.PARSE_DATE('%b %d %Y', TRIM(CAST(reported_date AS STRING))),
    SAFE.PARSE_DATE('%B %d %Y', TRIM(CAST(reported_date AS STRING)))
  ) AS reported_date,
  COALESCE(
    SAFE.PARSE_DATE('%Y-%m-%d', TRIM(CAST(first_contact_date AS STRING))),
    SAFE.PARSE_DATE('%m/%d/%Y', TRIM(CAST(first_contact_date AS STRING))),
    SAFE.PARSE_DATE('%b %d %Y', TRIM(CAST(first_contact_date AS STRING))),
    SAFE.PARSE_DATE('%B %d %Y', TRIM(CAST(first_contact_date AS STRING)))
  ) AS first_contact_date,
  /* Standardizes state values after DISTINCT validation identified full names, abbreviations, misspellings, and punctuation issues. */
  CASE
    WHEN UPPER(TRIM(state)) = 'ARKANSAS' THEN 'AR'
    WHEN UPPER(TRIM(state)) = 'CALIF' THEN 'CA'
    WHEN UPPER(TRIM(state)) = 'CALIF.' THEN 'CA'
    WHEN UPPER(TRIM(state)) = 'CALIFORNIA' THEN 'CA'
    WHEN UPPER(TRIM(state)) = 'COLORADO' THEN 'CO'
    WHEN UPPER(TRIM(state)) = 'FLORID' THEN 'FL'
    WHEN UPPER(TRIM(state)) = 'FLORIDA' THEN 'FL'
    WHEN UPPER(TRIM(state)) = 'GEORIGA' THEN 'GA'
    WHEN UPPER(TRIM(state)) = 'GEORGIA' THEN 'GA'
    WHEN UPPER(TRIM(state)) = 'ILLINOIS' THEN 'IL'
    WHEN UPPER(TRIM(state)) = 'KANSAS' THEN 'KS'
    WHEN UPPER(TRIM(state)) = 'LOUISIANA' THEN 'LA'
    WHEN UPPER(TRIM(state)) = 'MISSOURI' THEN 'MO'
    WHEN UPPER(TRIM(state)) = 'NORTH CAROLINA' THEN 'NC'
    WHEN UPPER(TRIM(state)) = 'OKLAHOMA' THEN 'OK'
    WHEN UPPER(TRIM(state)) = 'OREGON' THEN 'OR'
    WHEN UPPER(TRIM(state)) = 'SOUTH CAROLINA' THEN 'SC'
    WHEN UPPER(TRIM(state)) = 'TEXAS' THEN 'TX'
    WHEN UPPER(TRIM(state)) = 'TEXS' THEN 'TX'
    WHEN UPPER(TRIM(state)) = 'WASHINGTON' THEN 'WA'
    ELSE UPPER(TRIM(state))
  END AS state,
  /* Standardizes region values after validation identified inconsistent capitalization and leading/trailing spaces. */
  CASE
    WHEN UPPER(TRIM(region)) = 'SOUTH CENTRAL' THEN 'South Central'
    WHEN UPPER(TRIM(region)) = 'MIDWEST' THEN 'Midwest'
    WHEN UPPER(TRIM(region)) = 'MOUNTAIN' THEN 'Mountain'
    WHEN UPPER(TRIM(region)) = 'GULF' THEN 'Gulf'
    WHEN UPPER(TRIM(region)) = 'SOUTHEAST' THEN 'Southeast'
    WHEN UPPER(TRIM(region)) = 'WEST' THEN 'West'
    WHEN UPPER(TRIM(region)) = 'GULF/SOUTH CENTRAL' THEN 'Gulf/South Central'
    WHEN UPPER(TRIM(region)) = 'SOUTHEAST/GULF' THEN 'Southeast/Gulf'
    ELSE 'Review'
  END AS region,
  /* Standardizes county values after validation identified inconsistent capitalization and blank values. */
  CASE
    WHEN UPPER(TRIM(CAST(county AS STRING))) IN ('', 'NULL', 'N/A') THEN NULL
    ELSE INITCAP(TRIM(CAST(county AS STRING)))
  END AS county,
  /* Standardizes open_reserve_flag values after DISTINCT validation identified mixed Yes/No, Y/N, True/False, and 1/0 formats. */
  CASE
    WHEN UPPER(TRIM(CAST(open_reserve_flag AS STRING))) IN ('1', 'YES', 'Y', 'TRUE') THEN 'Yes'
    WHEN UPPER(TRIM(CAST(open_reserve_flag AS STRING))) IN ('0', 'NO', 'N', 'FALSE') THEN 'No'
    ELSE 'Review'
  END AS open_reserve_flag,
  /* Standardizes catastrophe_type values after DISTINCT validation identified inconsistent capitalization and leading/trailing spaces. */
  CASE
    WHEN UPPER(TRIM(catastrophe_type)) = 'HAIL' THEN 'Hail'
    WHEN UPPER(TRIM(catastrophe_type)) = 'HURRICANE' THEN 'Hurricane'
    WHEN UPPER(TRIM(catastrophe_type)) = 'WIND' THEN 'Wind'
    WHEN UPPER(TRIM(catastrophe_type)) = 'FLOOD' THEN 'Flood'
    WHEN UPPER(TRIM(catastrophe_type)) = 'TORNADO' THEN 'Tornado'
    WHEN UPPER(TRIM(catastrophe_type)) = 'WILDFIRE' THEN 'Wildfire'
    ELSE 'Review'
  END AS catastrophe_type,
  /* Standardizes cat_event_name values after validation identified inconsistent capitalization and leading/trailing spaces. */
  CASE
    WHEN UPPER(TRIM(cat_event_name)) = 'GREAT PLAINS HAILSTORM' THEN 'Great Plains Hailstorm'
    WHEN UPPER(TRIM(cat_event_name)) = 'SPRING HAIL EVENT' THEN 'Spring Hail Event'
    WHEN UPPER(TRIM(cat_event_name)) = 'METRO HAIL SURGE' THEN 'Metro Hail Surge'
    WHEN UPPER(TRIM(cat_event_name)) = 'SEVERE WIND EVENT' THEN 'Severe Wind Event'
    WHEN UPPER(TRIM(cat_event_name)) = 'STRAIGHT-LINE WIND EVENT' THEN 'Straight-Line Wind Event'
    WHEN UPPER(TRIM(cat_event_name)) = 'DERECHO WIND EVENT' THEN 'Derecho Wind Event'
    WHEN UPPER(TRIM(cat_event_name)) = 'HURRICANE NORA' THEN 'Hurricane Nora'
    WHEN UPPER(TRIM(cat_event_name)) = 'HURRICANE MASON' THEN 'Hurricane Mason'
    WHEN UPPER(TRIM(cat_event_name)) = 'HURRICANE IRIS' THEN 'Hurricane Iris'
    WHEN UPPER(TRIM(cat_event_name)) = 'COASTAL FLOOD SURGE' THEN 'Coastal Flood Surge'
    WHEN UPPER(TRIM(cat_event_name)) = 'GULF FLOODING EVENT' THEN 'Gulf Flooding Event'
    WHEN UPPER(TRIM(cat_event_name)) = 'RIVER BASIN FLOOD' THEN 'River Basin Flood'
    WHEN UPPER(TRIM(cat_event_name)) = 'CENTRAL PLAINS TORNADO' THEN 'Central Plains Tornado'
    WHEN UPPER(TRIM(cat_event_name)) = 'MIDWEST TORNADO OUTBREAK' THEN 'Midwest Tornado Outbreak'
    WHEN UPPER(TRIM(cat_event_name)) = 'SOUTHERN TORNADO LINE' THEN 'Southern Tornado Line'
    WHEN UPPER(TRIM(cat_event_name)) = 'PINE VALLEY FIRE' THEN 'Pine Valley Fire'
    WHEN UPPER(TRIM(cat_event_name)) = 'CANYON RIDGE FIRE' THEN 'Canyon Ridge Fire'
    WHEN UPPER(TRIM(cat_event_name)) = 'WESTERN WILDFIRE COMPLEX' THEN 'Western Wildfire Complex'
    ELSE INITCAP(TRIM(cat_event_name))
  END AS cat_event_name,
  /* Standardizes line_of_business values after DISTINCT validation identified inconsistent capitalization and leading/trailing spaces. */
  CASE
    WHEN UPPER(TRIM(line_of_business)) = 'AUTO' THEN 'Auto'
    WHEN UPPER(TRIM(line_of_business)) = 'INJURY' THEN 'Injury'
    WHEN UPPER(TRIM(line_of_business)) = 'PROPERTY' THEN 'Property'
    ELSE 'Review'
  END AS line_of_business,
  /* Standardizes coverage_type values after validation identified inconsistent capitalization and leading/trailing spaces. */
  CASE
    WHEN UPPER(TRIM(coverage_type)) = 'COLLISION' THEN 'Collision'
    WHEN UPPER(TRIM(coverage_type)) = 'COMPREHENSIVE' THEN 'Comprehensive'
    WHEN UPPER(TRIM(coverage_type)) = 'PHYSICAL DAMAGE' THEN 'Physical Damage'
    WHEN UPPER(TRIM(coverage_type)) = 'RENTAL' THEN 'Rental'
    WHEN UPPER(TRIM(coverage_type)) = 'TOWING' THEN 'Towing'
    ELSE 'Review'
  END AS coverage_type,
  /* Standardizes claim_status values after validation identified inconsistent capitalization and leading/trailing spaces. */
  CASE
    WHEN UPPER(TRIM(claim_status)) = 'OPEN' THEN 'Open'
    WHEN UPPER(TRIM(claim_status)) = 'CLOSED' THEN 'Closed'
    WHEN UPPER(TRIM(claim_status)) = 'PENDING REVIEW' THEN 'Pending Review'
    WHEN UPPER(TRIM(claim_status)) = 'REOPENED' THEN 'Reopened'
    WHEN UPPER(TRIM(claim_status)) = 'LITIGATION REVIEW' THEN 'Litigation Review'
    WHEN UPPER(TRIM(claim_status)) = 'CLOSED WITH SUPPLEMENT' THEN 'Closed with Supplement'
    ELSE 'Review'
  END AS claim_status,
  /* Standardizes claim_severity values after validation identified inconsistent capitalization and leading/trailing spaces. */
  CASE
    WHEN UPPER(TRIM(claim_severity)) = 'LOW' THEN 'Low'
    WHEN UPPER(TRIM(claim_severity)) = 'MODERATE' THEN 'Moderate'
    WHEN UPPER(TRIM(claim_severity)) = 'HIGH' THEN 'High'
    WHEN UPPER(TRIM(claim_severity)) = 'SEVERE' THEN 'Severe'
    ELSE 'Review'
  END AS claim_severity,
  /* Standardizes assigned_team values after validation identified inconsistent capitalization and leading/trailing spaces. */
  CASE
    WHEN UPPER(TRIM(assigned_team)) = 'TEAM ALPHA' THEN 'Team Alpha'
    WHEN UPPER(TRIM(assigned_team)) = 'TEAM BETA' THEN 'Team Beta'
    WHEN UPPER(TRIM(assigned_team)) = 'TEAM GAMMA' THEN 'Team Gamma'
    WHEN UPPER(TRIM(assigned_team)) = 'TEAM DELTA' THEN 'Team Delta'
    WHEN UPPER(TRIM(assigned_team)) = 'TEAM ECHO' THEN 'Team Echo'
    WHEN UPPER(TRIM(assigned_team)) = 'TEAM GULF' THEN 'Team Gulf'
    WHEN UPPER(TRIM(assigned_team)) = 'TEAM WEST' THEN 'Team West'
    WHEN UPPER(TRIM(assigned_team)) = 'TEAM CENTRAL' THEN 'Team Central'
    ELSE 'Review'
  END AS assigned_team,
  /* Standardizes inspection_completed values after validation identified mixed Yes/No, Y/N, True/False, and 1/0 formats. */
  CASE
    WHEN UPPER(TRIM(CAST(inspection_completed AS STRING))) IN ('1', 'YES', 'Y', 'TRUE') THEN 'Yes'
    WHEN UPPER(TRIM(CAST(inspection_completed AS STRING))) IN ('0', 'NO', 'N', 'FALSE') THEN 'No'
    ELSE 'Review'
  END AS inspection_completed,
  SAFE_CAST(REGEXP_REPLACE(CAST(days_to_first_contact AS STRING), r'[^0-9-]', '') AS INT64) AS days_to_first_contact,
  /* Standardizes legal_involved values after validation identified mixed Yes/No, Y/N, True/False, and 1/0 formats. */
  CASE
    WHEN UPPER(TRIM(CAST(legal_involved AS STRING))) IN ('1', 'YES', 'Y', 'TRUE') THEN 'Yes'
    WHEN UPPER(TRIM(CAST(legal_involved AS STRING))) IN ('0', 'NO', 'N', 'FALSE') THEN 'No'
    ELSE 'Review'
  END AS legal_involved,
  /* Standardizes injury_indicator values after validation identified mixed Yes/No, Y/N, True/False, and 1/0 formats. */
  CASE
    WHEN UPPER(TRIM(CAST(injury_indicator AS STRING))) IN ('1', 'YES', 'Y', 'TRUE') THEN 'Yes'
    WHEN UPPER(TRIM(CAST(injury_indicator AS STRING))) IN ('0', 'NO', 'N', 'FALSE') THEN 'No'
    ELSE 'Review'
  END AS injury_indicator,
  /* Standardizes vehicle_drivable values after validation identified inconsistent capitalization and leading/trailing spaces. */
  CASE
    WHEN UPPER(TRIM(vehicle_drivable)) = 'DRIVABLE' THEN 'Drivable'
    WHEN UPPER(TRIM(vehicle_drivable)) = 'NON-DRIVABLE' THEN 'Non-Drivable'
    WHEN UPPER(TRIM(vehicle_drivable)) = 'UNKNOWN' THEN 'Unknown'
    ELSE 'Review'
  END AS vehicle_drivable
FROM `portfolio-data-analysis-495222.portfolio_data.cat_claims_master_v2_raw_fixed`;
