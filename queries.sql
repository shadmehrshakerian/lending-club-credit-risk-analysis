-- ============================================
-- Lending Club Credit Risk Analysis
-- ============================================

-- Query 1: Row count verification
SELECT COUNT(*) AS total_rows
FROM `lending_club.accepted_loans`;

-- Query 2: Loan status distribution
SELECT loan_status, COUNT(*) AS count
FROM `lending_club.accepted_loans`
GROUP BY loan_status
ORDER BY count DESC;

-- Query 3: Default rate by loan grade
SELECT 
  grade,
  COUNT(*) AS total_loans,
  SUM(CASE 
    WHEN loan_status IN ('Charged Off', 'Default', 'Late (31-120 days)', 
    'Does not meet the credit policy. Status:Charged Off') 
    THEN 1 ELSE 0 END) AS defaulted_loans,
  ROUND(SUM(CASE 
    WHEN loan_status IN ('Charged Off', 'Default', 'Late (31-120 days)', 
    'Does not meet the credit policy. Status:Charged Off') 
    THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS default_rate_pct
FROM `lending_club.accepted_loans`
WHERE loan_status NOT IN ('Current', 'In Grace Period', 'Late (16-30 days)')
GROUP BY grade
ORDER BY grade;

-- Query 4: Interest rate vs default rate by grade
SELECT 
  grade,
  COUNT(*) AS total_loans,
  ROUND(AVG(int_rate), 2) AS avg_interest_rate,
  ROUND(SUM(CASE 
    WHEN loan_status IN ('Charged Off', 'Default', 'Late (31-120 days)', 
    'Does not meet the credit policy. Status:Charged Off') 
    THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS default_rate_pct,
  ROUND(AVG(loan_amnt), 2) AS avg_loan_amount
FROM `lending_club.accepted_loans`
WHERE loan_status NOT IN ('Current', 'In Grace Period', 'Late (16-30 days)')
GROUP BY grade
ORDER BY grade;

-- Query 5: Default rate by loan purpose
SELECT 
  purpose,
  COUNT(*) AS total_loans,
  ROUND(AVG(int_rate), 2) AS avg_interest_rate,
  ROUND(SUM(CASE 
    WHEN loan_status IN ('Charged Off', 'Default', 'Late (31-120 days)', 
    'Does not meet the credit policy. Status:Charged Off') 
    THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS default_rate_pct,
  ROUND(AVG(loan_amnt), 2) AS avg_loan_amount
FROM `lending_club.accepted_loans`
WHERE loan_status NOT IN ('Current', 'In Grace Period', 'Late (16-30 days)')
GROUP BY purpose
ORDER BY default_rate_pct DESC;

-- Query 6: Vintage cohort analysis with window functions
WITH yearly_cohorts AS (
  SELECT 
    EXTRACT(YEAR FROM PARSE_DATE('%b-%Y', issue_d)) AS issue_year,
    COUNT(*) AS total_loans,
    SUM(CASE 
      WHEN loan_status IN ('Charged Off', 'Default', 'Late (31-120 days)', 
      'Does not meet the credit policy. Status:Charged Off') 
      THEN 1 ELSE 0 END) AS defaulted_loans,
    ROUND(SUM(CASE 
      WHEN loan_status IN ('Charged Off', 'Default', 'Late (31-120 days)', 
      'Does not meet the credit policy. Status:Charged Off') 
      THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS default_rate_pct,
    ROUND(AVG(loan_amnt), 2) AS avg_loan_amount,
    ROUND(AVG(int_rate), 2) AS avg_interest_rate
  FROM `lending_club.accepted_loans`
  WHERE loan_status NOT IN ('Current', 'In Grace Period', 'Late (16-30 days)')
    AND issue_d IS NOT NULL
  GROUP BY issue_year
)
SELECT 
  issue_year,
  total_loans,
  defaulted_loans,
  default_rate_pct,
  avg_loan_amount,
  avg_interest_rate,
  SUM(total_loans) OVER (ORDER BY issue_year) AS cumulative_loans,
  ROUND(AVG(default_rate_pct) OVER (
    ORDER BY issue_year 
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS rolling_3yr_avg_default_rate
FROM yearly_cohorts
ORDER BY issue_year;

-- Query 7: Default rate by debt-to-income ratio bucket
SELECT 
  CASE 
    WHEN dti < 10 THEN '0-10%'
    WHEN dti < 20 THEN '10-20%'
    WHEN dti < 30 THEN '20-30%'
    WHEN dti < 40 THEN '30-40%'
    ELSE '40%+'
  END AS dti_bucket,
  COUNT(*) AS total_loans,
  ROUND(AVG(int_rate), 2) AS avg_interest_rate,
  ROUND(SUM(CASE 
    WHEN loan_status IN ('Charged Off', 'Default', 'Late (31-120 days)', 
    'Does not meet the credit policy. Status:Charged Off') 
    THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS default_rate_pct,
  ROUND(AVG(loan_amnt), 2) AS avg_loan_amount
FROM `lending_club.accepted_loans`
WHERE loan_status NOT IN ('Current', 'In Grace Period', 'Late (16-30 days)')
  AND dti IS NOT NULL
GROUP BY dti_bucket
ORDER BY dti_bucket;

-- Query 8: Default rate by employment length
SELECT 
  emp_length,
  COUNT(*) AS total_loans,
  ROUND(SUM(CASE 
    WHEN loan_status IN ('Charged Off', 'Default', 'Late (31-120 days)', 
    'Does not meet the credit policy. Status:Charged Off') 
    THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS default_rate_pct,
  ROUND(AVG(int_rate), 2) AS avg_interest_rate,
  ROUND(AVG(loan_amnt), 2) AS avg_loan_amount
FROM `lending_club.accepted_loans`
WHERE loan_status NOT IN ('Current', 'In Grace Period', 'Late (16-30 days)')
  AND emp_length IS NOT NULL
GROUP BY emp_length
ORDER BY emp_length;

-- Query 9: Final summary table for Power BI export
WITH loan_base AS (
  SELECT
    id,
    loan_amnt,
    int_rate,
    grade,
    sub_grade,
    emp_length,
    home_ownership,
    annual_inc,
    loan_status,
    purpose,
    dti,
    issue_d,
    EXTRACT(YEAR FROM PARSE_DATE('%b-%Y', issue_d)) AS issue_year,
    addr_state,
    total_pymnt,
    recoveries,
    CASE 
      WHEN loan_status IN (
        'Charged Off', 
        'Default', 
        'Late (31-120 days)', 
        'Does not meet the credit policy. Status:Charged Off'
      ) THEN 1 ELSE 0 
    END AS is_defaulted,
    CASE 
      WHEN loan_status IN (
        'Fully Paid',
        'Does not meet the credit policy. Status:Fully Paid'
      ) THEN 1 ELSE 0 
    END AS is_paid,
    CASE 
      WHEN dti < 10 THEN '0-10%'
      WHEN dti < 20 THEN '10-20%'
      WHEN dti < 30 THEN '20-30%'
      WHEN dti < 40 THEN '30-40%'
      ELSE '40%+'
    END AS dti_bucket,
    CASE
      WHEN annual_inc < 40000 THEN 'Under 40K'
      WHEN annual_inc < 60000 THEN '40K-60K'
      WHEN annual_inc < 80000 THEN '60K-80K'
      WHEN annual_inc < 100000 THEN '80K-100K'
      ELSE '100K+'
    END AS income_bucket
  FROM `lending_club.accepted_loans`
  WHERE loan_status NOT IN ('Current', 'In Grace Period', 'Late (16-30 days)')
    AND issue_d IS NOT NULL
    AND dti IS NOT NULL
)
SELECT
  id,
  issue_year,
  grade,
  sub_grade,
  purpose,
  emp_length,
  home_ownership,
  addr_state,
  dti_bucket,
  income_bucket,
  loan_amnt,
  int_rate,
  annual_inc,
  dti,
  total_pymnt,
  recoveries,
  is_defaulted,
  is_paid,
  loan_status,
  ROUND(total_pymnt - loan_amnt, 2) AS net_return,
  ROUND((total_pymnt - loan_amnt) / NULLIF(loan_amnt, 0) * 100, 2) AS return_pct
FROM loan_base;
