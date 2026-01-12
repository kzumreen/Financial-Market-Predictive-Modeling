# Citigroup Stock Price Analysis: Financial Sector Predictive Modeling
Predictive analysis of Citigroup (C) stock performance using SAS and Python. Engineered a multi-stage regression model achieving 98% accuracy, applying Pearson Correlation screening, stepwise selection, and VIF diagnostics to resolve multicollinearity. Includes data analysis, interaction modeling, and residual analysis for financial forecasting.

## Executive Summary
This project identifies the key drivers of Citigroup's (C) daily stock price movements relative to the S&P 500 Financial Sector. Using a combination of SAS for statistical modeling and Python for exploratory data analysis, I built a regression model that explains ~98% of Citigroup’s price variation.

## Tech Stack & Methodology
Languages: Python (Pandas, Seaborn, Matplotlib), SAS.

Statistical Techniques: Pearson Correlation, Stepwise Regression, Multicollinearity Diagnostics (VIF), Residual Analysis, Interaction Terms.

Data Source: Daily market data for S&P 500 financial-sector companies.

## Key Insights
High Correlation: Identified that Citigroup's price is most significantly influenced by specific peers like Bank of America and JPMorgan, rather than the sector as a whole.

Model Robustness: Applied Variance Inflation Factor (VIF) to eliminate multicollinearity, ensuring that each predictor in the model provided unique value.

Interaction Effects: Discovered that the relationship between Citigroup and its peers changes significantly during periods of high market volatility.

## How to Navigate this Repo
notebooks/EDA.ipynb: Full Python visualization of sector trends.

sas_scripts/model_building.sas: The core regression logic and stepwise selection.

report/Full_Analysis.pdf: The complete 30-page academic report with diagnostics.
