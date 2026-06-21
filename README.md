# Lending Club Credit Risk Analysis

SQL and Power BI analysis of 2.26 million consumer loans to identify default risk drivers, evaluate interest rate pricing, and track portfolio risk trends from 2007–2018.

**Tools:** SQL (BigQuery), Power BI, Python
**Dataset:** [Lending Club Loan Data, Kaggle](https://www.kaggle.com/datasets/wordsforthewise/lending-club)
**Scope:** 1.37 million resolved loans (Fully Paid or Charged Off) after cleaning and exclusions

---

## Business Questions

1. What loan and borrower factors drive default risk?
2. Is interest rate pricing keeping pace with that risk?
3. How has portfolio risk evolved over time as loan volume scaled?

---

## Data Quality Note

The raw multi-year CSV export contained 33 corrupted footer rows left over from concatenated quarterly source files, which broke BigQuery's schema parsing on load. Diagnosed the pattern, adjusted the load configuration to skip malformed rows, and verified the final row count against the expected total before starting analysis.

---

## Key Findings

**1. Loan grade is a strong predictor of default — and pricing hasn't kept up**
Default rates rise from 6.6% at Grade A to 50.9% at Grade G, an eightfold increase. Interest rates rise too, but far more slowly: by Grade G, lenders charge 27.6% interest against a 50.9% default rate, a 23-point gap. The pricing premium only fully covers default risk at Grade A.

**2. Loan purpose carries meaningful, separate risk**
Small business loans default at 31.4%, the highest of any category, despite an average interest rate barely above the portfolio mean. Debt consolidation, the largest single category at nearly 794,000 loans, has a moderate 22.4% default rate but the largest absolute volume of defaults in the portfolio.

**3. Debt-to-income ratio is a clean, linear risk signal**
Default rate climbs steadily from 16.2% (DTI under 10%) to 35.6% (DTI 40%+), with a notable step up past the 30% DTI threshold — a natural underwriting cutoff.

**4. Employment length is a weak predictor**
Default rates range only 19.99%–22.00% across eleven employment length categories, from under one year to ten-plus years. Lending Club's own pricing reflects this: average interest rates are nearly flat across the same categories. A widely assumed risk factor turns out to add little signal on its own.

**5. Portfolio risk tracks growth, not just the economic cycle**
Default rates fell from 26.2% (2007) to a post-crisis low of 13.7% (2009) as underwriting tightened. From 2013–2017, as annual loan volume grew nearly 3x, default rates climbed back to 26.6% — a pattern consistent with credit quality loosening to sustain growth, not just macroeconomic conditions.

---

## Methods

- Cleaned and loaded 2.26M rows into BigQuery, handling malformed source rows
- Built a binary default flag from nine raw loan status categories, excluding unresolved loans (Current, Late, Grace Period) to avoid biasing results toward early-stage loans
- Wrote SQL using CTEs, window functions (cumulative sums, rolling 3-year averages), and conditional aggregation to analyze risk across grade, purpose, DTI, employment length, and vintage year
- Built a 3-page Power BI dashboard: Credit Risk Overview, Borrower Risk Profile, and Vintage Trend Analysis

---

## Dashboard

Live dashboard: [link]

## Files

- `queries.sql` — all SQL queries used in this analysis
