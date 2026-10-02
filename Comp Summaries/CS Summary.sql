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
    A.YTD_SALES,
    A.REGIONAL_TGT,
    A.FY_PLAN,
    A.[%_FY_PLAN],
    A.REGIONAL_PO,
    C.NEW_OPP_SUBMISSION_PAYOUT + ISNULL(C2.CPAS_PAYOUT, 0) AS CS_SPIFF_PAYOUT,
    REGIONAL_PO + ISNULL(C.NEW_OPP_SUBMISSION_PAYOUT, 0) + ISNULL(C2.CPAS_PAYOUT, 0) AS TOTAL_PO
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
    LEFT JOIN (
        SELECT
            CREATED_BY_EMAIL,
            CREATED_YYYYMM,
            SUM(NEW_OPP_SUBMISSION_PAYOUT) AS NEW_OPP_SUBMISSION_PAYOUT
        FROM
            qryCS_SPIFF
        WHERE
            CREATED_YYYYMM = @YYYYMM
        GROUP BY
            CREATED_BY_EMAIL,
            CREATED_YYYYMM
    ) AS C ON A.SALES_CREDIT_CS_EMAIL = C.CREATED_BY_EMAIL
    LEFT JOIN (
        SELECT
            CREATED_BY_EMAIL,
            CPAS_SUBMIT_YYYYMM,
            SUM(CPAS_PAYOUT) AS CPAS_PAYOUT
        FROM
            qryCS_SPIFF
        WHERE
            CPAS_SUBMIT_YYYYMM = @YYYYMM
        GROUP BY
            CREATED_BY_EMAIL,
            CPAS_SUBMIT_YYYYMM
    ) AS C2 ON A.SALES_CREDIT_CS_EMAIL = C2.CREATED_BY_EMAIL