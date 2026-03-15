/* ============================================================
   Regression Modeling of Citigroup Daily Stocks
   Using S&P 500 Financial Sector Components
   
   Author: Kadeeja Zumreen
   Tools: SAS Studio (academic license)
   Note: EDA performed in Python — see eda.ipynb
   ============================================================ */


/* ============================================================
   STEP 1: DATA IMPORT
   ============================================================ */

FILENAME REFFILE '/home/u63886066/Lab 3/Fall 2025 Lab #3 Closing Prices.xlsx';

PROC IMPORT DATAFILE=REFFILE
    DBMS=XLSX
    OUT=WORK.stock;
    GETNAMES=YES;
RUN;

PROC CONTENTS DATA=WORK.stock; RUN;

%web_open_table(WORK.IMPORT);

proc print data = stock; run;


/* ============================================================
   STEP 2: INITIAL CORRELATION ANALYSIS
   Pearson correlation between CitiGroup (C) and all numeric
   variables to identify stocks with |r| >= 0.60
   ============================================================ */

proc corr data=stock nosimple;
    var C;
    with _numeric_;
run;


/* ============================================================
   STEP 3: FIRST STEPWISE REGRESSION
   Reduce from 40 correlated variables down to 19 predictors
   ============================================================ */

proc reg data = stock;
    model C = WRB WFC TRV TFC SYF STT SCHW RJF RF NTRS NDAQ MS MMC MCO MA L KEY
              JPM JKHY IVZ IBKR HOOD HIG HBAN GS GL FISV FDS ERIE COIN COF CINF CFG CBOE BRO
              BLK BK BEN BAC AXP/selection = stepwise;
    run;


/* ============================================================
   STEP 4: SECOND CORRELATION ANALYSIS WITH SCATTERPLOTS
   Focused on the 19 variables selected by stepwise regression
   ============================================================ */

proc corr data=stock
    plots(maxpoints=none)=scatter(ellipse=none);
    var GS JPM BK IBKR MS HOOD COF NDAQ BAC BEN AXP SYF GL ERIE MCO HIG TRV WRB BLK;
    with C;
run;

/* Additional scatterplot subsets for visual clarity */
proc corr data=stock
    plots(maxpoints=none)=scatter(ellipse=none);
    var HOOD COF NDAQ BAC BEN;
    with C;
run;

proc corr data=stock
    plots(maxpoints=none)=scatter(ellipse=none);
    var AXP SYF GL ERIE MCO;
    with C;
run;

proc corr data=stock
    plots(maxpoints=none)=scatter(ellipse=none);
    var HIG TRV WRB BLK;
    with C;
run;


/* ============================================================
   STEP 5: SECOND STEPWISE REGRESSION
   After removing Insurance group and MCO following EDA,
   run stepwise on the remaining 12 predictors
   ============================================================ */

proc reg data = stock;
    model C = AXP GS IBKR MS HOOD JPM BAC COF BEN BK NDAQ BLK/selection = stepwise;
    run;

/* GLMSELECT for additional model selection criteria */
proc glmselect data = stock plots = criterionpanel;
    model C = AXP GS IBKR MS HOOD JPM BAC COF BEN BK NDAQ BLK/selection = stepwise stats = all;
    run;


/* ============================================================
   STEP 6: MULTICOLLINEARITY DIAGNOSTICS (VIF)
   Iteratively remove highest-VIF predictors
   ============================================================ */

/* Iteration 1: 8-variable model from stepwise */
proc reg data = stock;
    model C = GS IBKR MS BAC COF BEN BK BLK/vif;
    run;

/* Iteration 2: Remove GS (highest VIF) */
proc reg data = stock;
    model C = IBKR MS BAC COF BEN BK BLK/vif;
    run;

/* Iteration 3: Remove IBKR */
proc reg data = stock;
    model C = IBKR BAC COF BEN BK BLK/vif;
    run;

/* Iteration 4: Remove MS */
proc reg data = stock;
    model C = BAC COF BEN BK BLK/vif;
    run;

/* Iteration 5: Remove BEN (negative coefficient — sign reversal
   indicates multicollinearity despite low VIF) */
proc reg data = stock;
    model C = BAC COF BK BLK/vif;
    run;


/* ============================================================
   STEP 7: FINAL FIRST-ORDER MODEL WITH DIAGNOSTICS
   4-variable model: BAC + COF + BK + BLK
   ============================================================ */

proc reg data = stock plots = (all diagnostics (unpack));
    model C = BAC COF BK BLK/all;
    run;


/* ============================================================
   STEP 8: INTERACTION TERMS
   Test all pairwise interactions using PROC GLM and PROC PLM
   ============================================================ */

proc glm data=stock;
    model C = BAC | COF | BK | BLK @2 / solution;
    store GLMMODEL;
run;

proc plm restore=GLMMODEL noinfo;
    /* 1. Interactions with BAC */
    effectplot slicefit(x = BAC sliceby = COF);
    effectplot slicefit(x = BAC sliceby = BK);
    effectplot slicefit(x = BAC sliceby = BLK);

    /* 2. Interactions with COF */
    effectplot slicefit(x = COF sliceby = BK);
    effectplot slicefit(x = COF sliceby = BLK);

    /* 3. Interaction between BK and BLK */
    effectplot slicefit(x = BK  sliceby = BLK);
run;


/* ============================================================
   STEP 9: CREATE INTERACTION AND QUADRATIC TERMS
   ============================================================ */

data stock2;
    set stock;

    BAC_COF = BAC * COF;
    BAC_BK  = BAC * BK;
    BAC_BLK = BAC * BLK;
    COF_BK  = COF * BK;
    COF_BLK = COF * BLK;
    BK_BLK  = BK  * BLK;
    BAC_SQ  = BAC**2;
    BK_SQ   = BK**2;
    COF_SQ  = COF**2;
    BLK_SQ  = BLK**2;
    RUN;


/* ============================================================
   STEP 10: INTERACTION MODEL (without quadratic)
   ============================================================ */

/* All interaction terms including COF_BLK */
proc reg data = stock2;
    model C = BAC COF BK BLK BAC_COF BAC_BK BAC_BLK COF_BK COF_BLK BK_BLK;
    run;

/* Significant interactions only (drop COF_BLK) */
proc reg data = stock2;
    model C = BAC COF BK BLK BAC_COF BAC_BK BAC_BLK COF_BK BK_BLK;
    run;


/* ============================================================
   STEP 11: COMPLETE MODEL — interactions + quadratic term
   BK_SQ was the only significant quadratic term
   ============================================================ */

proc reg data = stock2;
    model C = BAC COF BK BLK BAC_COF BAC_BK BAC_BLK COF_BK BK_BLK BK_SQ;
    run;

/* First-order only baseline for comparison */
proc reg data = stock2;
    model C = BAC COF BK BLK;
    run;


/* ============================================================
   STEP 12: FULL DIAGNOSTICS ON BEST MODEL
   ============================================================ */

proc reg data = stock2 plots = (all diagnostics (unpack));
    model C = BAC COF BK BLK BAC_COF BAC_BK BAC_BLK COF_BK BK_BLK BK_SQ/all;
    run;


/* ============================================================
   FINAL MODEL EQUATION (Least Squares):

   Predicted C = 36.54
               + 5.367(BAC)
               - 0.386(COF)
               - 3.752(BK)
               + 0.139(BLK)
               - 0.0137(BK_SQ)
               + 0.0274(BAC_COF)
               + 0.046(BAC_BK)
               - 0.01418(BAC_BLK)
               - 0.00725(COF_BK)
               + 0.00580(BK_BLK)

   Adj R-Square : 0.9834
   Root MSE     : 1.604
   Coeff Var    : 2.012%
   ============================================================ */
