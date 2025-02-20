/* set YYYYMM as last month in the format yyyy_MM */
DECLARE @YYYYMM AS VARCHAR(7) = FORMAT(DATEADD(MONTH, -1, GETDATE()), 'yyyy_MM');


WITH DETAIL AS (
    SELECT
        SALES_CREDIT_CS_EMAIL,
        NAME_REP,
        @YYYYMM AS YYYYMM,
        REGION_NM,
        REGION_ID,
        SUM(
            /* regional payments are made only on rev rec'd opps */
            CASE
                WHEN CLOSE_YYYYMM = @YYYYMM
                AND STAGENAME = 'Revenue Recognized' THEN SALES_COMMISSIONABLE
                ELSE 0
            END
        ) AS SALES,
        SUM(
            CASE
                WHEN CLOSE_YYYYMM = @YYYYMM
                AND STAGENAME = 'Revenue Recognized' THEN REVENUE_UNITS
                ELSE 0
            END
        ) AS REVENUE_UNITS,
        SUM(
            /* targets are paid on both implant completed or rev rec'd */
            /* ensure that targets are only paid out for the month they were implanted OR closed,
             depending on if it's an implant target or a revenue target */
            CASE
                WHEN TGT_PO_YYYYMM = @YYYYMM THEN TGT_PO
            END
        ) AS TGT_PO,
        ISNULL(
            MAX(
                CASE
                    WHEN CLOSE_YYYYMM = @YYYYMM THEN YTD_SALES_COMMISSIONABLE
                END
            ),
            0
        ) AS YTD_SALES
    FROM
        qry_COMP_CS_DETAIL
    WHERE
        CLOSE_YYYYMM = @YYYYMM
        OR IMPLANTED_YYYYMM = @YYYYMM
    GROUP BY
        SALES_CREDIT_CS_EMAIL,
        NAME_REP,
        REGION_NM,
        REGION_ID
)
SELECT
    A.SALES_CREDIT_CS_EMAIL,
    A.NAME_REP,
    YYYYMM,
    DOH,
    DOT,
    A.REGION_NM,
    A.REGION_ID,
    A.SALES,
    A.REVENUE_UNITS,
    A.TGT_PO,
    A.YTD_SALES,
    A.REGIONAL_TGT,
    A.FY_PLAN,
    A.[%_FY_PLAN],
    A.REGIONAL_PO,
    REGIONAL_PO + ISNULL(TGT_PO, 0) AS TOTAL_PO
    /******/
    -- INTO tmpCS_PO
    /******/
FROM
    (
        SELECT
            DETAIL.*,
            FC.BASE_BONUS AS REGIONAL_TGT,
            R.[PLAN] AS FY_PLAN,
            YTD_SALES / R.[PLAN] AS [%_FY_PLAN],
            CAST((SALES / [PLAN]) * BASE_BONUS AS MONEY) AS REGIONAL_PO
        FROM
            DETAIL
            LEFT JOIN tblFCE_COMP FC ON FC.FCE_EMAIL = DETAIL.SALES_CREDIT_CS_EMAIL
            LEFT JOIN tblRates_RM R ON R.REGION_ID = DETAIL.REGION_ID
    ) AS A
    LEFT JOIN qryRoster R ON R.REP_EMAIL = SALES_CREDIT_CS_EMAIL
    AND R.[isLATEST?] = 1
    AND R.ROLE = 'FCE'