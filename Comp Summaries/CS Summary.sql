WITH DETAIL AS (
    SELECT
        SALES_CREDIT_CS_EMAIL,
        NAME_REP,
        CLOSE_YYYYMM AS YYYYMM,
        REGION_NM,
        REGION_ID,
        -- SUM(
        --     CASE
        --         WHEN CLOSE_YYYYMM = FORMAT(DATEADD(MONTH, -1, GETDATE()), 'yyyy_MM') THEN SALES
        --         ELSE 0
        --     END
        -- ) AS SALES,
        SUM (
            /* regional payments are made only on rev rec'd opps */
            CASE
                WHEN STAGENAME = 'Revenue Recognized' THEN SALES
                ELSE 0
            END
        ) AS SALES,
        -- SUM(
        --     CASE
        --         WHEN IMPLANTED_YYYYMM = FORMAT(DATEADD(MONTH, -1, GETDATE()), 'yyyy_MM') THEN IMPLANT_UNITS
        --         ELSE 0
        --     END
        -- ) AS IMPLANT_UNITS,
        SUM(IMPLANT_UNITS) AS IMPLANT_UNITS,
        -- SUM(
        --     CASE
        --         WHEN CLOSE_YYYYMM = FORMAT(DATEADD(MONTH, -1, GETDATE()), 'yyyy_MM') THEN REVENUE_UNITS
        --         ELSE 0
        --     END
        -- ) AS REVENUE_UNITS,
        SUM(REVENUE_UNITS) AS REVENUE_UNITS,
        SUM(TGT_PO) AS TGT_PO
    FROM
        qry_COMP_CS_DETAIL
    GROUP BY
        SALES_CREDIT_CS_EMAIL,
        NAME_REP,
        CLOSE_YYYYMM,
        REGION_NM,
        REGION_ID
)
SELECT
    *,
    REGIONAL_PO + TGT_PO AS TOTAL_PO
FROM
    (
        SELECT
            DETAIL.*,
            FC.BASE_BONUS AS REGIONAL_TGT,
            R.Quota,
            CAST((SALES / QUOTA) * BASE_BONUS AS MONEY) AS REGIONAL_PO
        FROM
            DETAIL
            LEFT JOIN tblFCE_COMP FC ON FC.FCE_EMAIL = DETAIL.SALES_CREDIT_CS_EMAIL
            LEFT JOIN tblRates_RM R ON R.REGION_ID = DETAIL.REGION_ID
    ) AS A