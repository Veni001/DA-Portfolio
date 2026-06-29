-- =============================================================================
-- 1: DATA CLEANING
-- =============================================================================
 
-- Cek missing value pada table customer
SELECT * FROM customer_master
WHERE "Customer_ID" IS NULL;

-- Cek missing value pada table transaction
SELECT * FROM transactions
WHERE "Customer_ID" IS NULL
   OR "Transaction_Date" IS NULL
   OR "Total_Transaction_Value" IS NULL;
   
-- Cek duplikat transaction
SELECT "Transaction_ID", COUNT(*) AS Total_Record
FROM transactions
GROUP BY "Transaction_ID"
HAVING COUNT(*) > 1;

-- Cek customer yang tidak terdaftar
SELECT t.* FROM transactions t
LEFT JOIN customer_master c
ON t."Customer_ID" = c."Customer_ID"
WHERE c."Customer_ID" IS NULL;

-- Cek nilai transaksi tidak wajar
SELECT * FROM transactions
WHERE "Quantity" <= 0
   OR "Unit_Price" <= 0
   OR "Total_Transaction_Value" <= 0;
   
  
-- =============================================================================
-- 2: DATA TRANSFORMATION
-- =============================================================================
  
CREATE VIEW customer_transaction AS
SELECT
    t."Transaction_ID",
    t."Customer_ID",
    c."Customer_Name",
    c."Region",
    c."Customer_Segment",
    c."Risk_Profile",
    t."Transaction_Date",
    t."Product_Category",
    t."Quantity",
    t."Unit_Price",
    t."Total_Transaction_Value",
    t."Sales_Channel",
    t."Payment_Method"
FROM transactions t
LEFT JOIN customer_master c
ON t."Customer_ID" = c."Customer_ID";

SELECT * FROM customer_transaction;

-- =============================================================================
-- 3: CUSTOMER AGGREGATION
-- =============================================================================

CREATE VIEW customer_summary AS
SELECT "Customer_ID",
    COUNT("Transaction_ID") AS Total_Transactions,
    SUM("Total_Transaction_Value") AS Total_Spend,
    AVG("Total_Transaction_Value") AS Avg_Transaction_Value,
    MIN("Transaction_Date") AS First_Purchase,
    MAX("Transaction_Date") AS Last_Purchase
FROM transactions
GROUP BY "Customer_ID";

SELECT * FROM customer_summary;


-- =============================================================================
-- 4: CUSTOMER SEGMENTATION
-- =============================================================================

-- RFM
CREATE VIEW rfm AS
SELECT
    "Customer_ID",
    CAST('2026-12-31' AS DATE) - MAX("Transaction_Date"::date) AS Recency,
    COUNT("Transaction_ID") AS Frequency,
    SUM("Total_Transaction_Value") AS Monetary
FROM transactions
GROUP BY "Customer_ID";

SELECT * FROM rfm;

-- RFM SCORE
CREATE VIEW rfm_score AS
SELECT
    "Customer_ID",
    "recency",
    "frequency",
    "monetary",

    CASE
        WHEN "recency" <= 30 THEN 5
        WHEN "recency" <= 90 THEN 4
        WHEN "recency" <= 180 THEN 3
        WHEN "recency" <= 365 THEN 2
        ELSE 1
    END AS R_Score,

    CASE
        WHEN "frequency" >= 20 THEN 5
        WHEN "frequency" >= 15 THEN 4
        WHEN "frequency" >= 10 THEN 3
        WHEN "frequency" >= 5 THEN 2
        ELSE 1
    END AS F_Score,

    CASE
        WHEN "monetary" >= 10000000 THEN 5
        WHEN "monetary" >= 5000000 THEN 4
        WHEN "monetary" >= 2000000 THEN 3
        WHEN "monetary" >= 1000000 THEN 2
        ELSE 1
    END AS M_Score

FROM rfm;
SELECT * FROM rfm_score;


-- CUSTOMER SEGMENTATION
CREATE VIEW customer_segment AS
SELECT
    "Customer_ID",
    "recency",
    "frequency",
    "monetary",
    R_Score,
    F_Score,
    M_Score,
    (R_Score + F_Score + M_Score) AS Total_RFM_Score,

    CASE
        WHEN (R_Score + F_Score + M_Score) >= 12
            THEN 'Low Risk'
        WHEN (R_Score + F_Score + M_Score) >= 7
            THEN 'Medium Risk'
        ELSE 'High Risk'
    END AS Customer_Risk

FROM rfm_score;

SELECT * FROM customer_segment;
