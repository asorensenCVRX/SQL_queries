DECLARE @YYYYMM AS VARCHAR(7) = FORMAT(DATEADD(MONTH, -1, GETDATE()), 'yyyy_MM');


WITH DETAIL AS (
    SELECT
        EID,
        NAME_REP,
        REGION_NM,
        YYYYMM,
        YYYYQQ,
        THRESHOLD,
        [PLAN],
        SUM(SALES_COMMISSIONABLE) AS SALES,
        MAX(QTD_SALES_COMMISSIONABLE) AS QTD_SALES,
        SUM(L1_REV) AS L1_REV,
        SUM(L2_REV) AS L2_REV,
        SUM(L1_PO) AS L1_PO,
        SUM(L2_PO) AS L2_PO,
        /* only calc the implant accel true up if it's the last month of the quarter and
         impl_rev_ratio is >= 0.85 */
        MAX(
            CASE
                WHEN IMPL_REV_RATIO >= 0.85
                AND YYYYMM IN ('2025_03', '2025_06', '2025_09', '2025_12') THEN QTD_SALES_COMMISSIONABLE
                ELSE 0
            END
        ) * 0.05 AS IMPLANT_ACCEL_TRUE_UP,
        SUM(L1_L2_PO) + (
            MAX(
                CASE
                    WHEN IMPL_REV_RATIO >= 0.85
                    AND YYYYMM IN ('2025_03', '2025_06', '2025_09', '2025_12') THEN QTD_SALES_COMMISSIONABLE
                    ELSE 0
                END
            ) * 0.05
        ) AS TTL_PO,
        SUM(IMPLANT_UNITS) AS IMPLANT_UNITS,
        SUM(REVENUE_UNITS) AS REVENUE_UNITS,
        MAX(IMPL_REV_RATIO) AS QTD_IMPL_REV_RATIO
    FROM
        (
            SELECT
                SALES_CREDIT_REP_EMAIL AS EID,
                NAME_REP,
                REGION_NM,
                CLOSE_YYYYMM AS YYYYMM,
                CLOSE_YYYYQQ AS YYYYQQ,
                THRESHOLD,
                [PLAN],
                SALES_COMMISSIONABLE,
                L1_REV,
                L2_REV,
                L1_PO,
                L2_PO,
                L1_PO + L2_PO AS L1_L2_PO,
                IMPLANT_UNITS,
                REVENUE_UNITS,
                FIRST_VALUE(QTD_IMPL_REV_RATIO) OVER (
                    PARTITION BY SALES_CREDIT_REP_EMAIL,
                    CLOSE_YYYYQQ
                    ORDER BY
                        CLOSEDATE DESC
                ) AS IMPL_REV_RATIO,
                MAX(QTD_SALES_COMISSIONABLE) OVER (
                    PARTITION BY SALES_CREDIT_REP_EMAIL,
                    CLOSE_YYYYMM
                    ORDER BY
                        CLOSEDATE DESC
                ) AS QTD_SALES_COMMISSIONABLE
            FROM
                qry_COMP_TM_DETAIL
        ) AS A
    GROUP BY
        EID,
        NAME_REP,
        REGION_NM,
        YYYYMM,
        YYYYQQ,
        THRESHOLD,
        [PLAN]
),
CS_DED AS (
    SELECT
        SALES_CREDIT_REP_EMAIL,
        CS_PO_YYYYMM,
        SUM([CS_PO_$]) + SUM([CS_PO_%]) AS CS_DEDUCTION
    FROM
        qry_COMP_TM_DETAIL
    WHERE
        CS_PO_YYYYMM IS NOT NULL
    GROUP BY
        SALES_CREDIT_REP_EMAIL,
        CS_PO_YYYYMM
)
SELECT
    EID,
    DETAIL.NAME_REP,
    R.DOH,
    R.DOT,
    DETAIL.REGION_NM,
    DETAIL.YYYYMM,
    DETAIL.YYYYQQ,
    THRESHOLD,
    [PLAN],
    SALES,
    QTD_SALES,
    L1_REV,
    L2_REV,
    L1_PO,
    L2_PO,
    ISNULL(CS_DEDUCTION, 0) AS CS_DEDUCTION,
    IMPLANT_ACCEL_TRUE_UP,
    TTL_PO - ISNULL(CS_DEDUCTION, 0) AS TTL_PO,
    IMPLANT_UNITS,
    REVENUE_UNITS,
    QTD_IMPL_REV_RATIO,
    ISNULL(G.PO_AMT, 0) AS GAURANTEE_AMT,
    CASE
        WHEN ISNULL(G.PO_AMT, 0) > TTL_PO THEN G.PO_AMT - TTL_PO
        ELSE 0
    END AS GAURANTEE_ADJ,
    CASE
        WHEN ISNULL(G.PO_AMT, 0) > TTL_PO THEN G.PO_AMT
        ELSE TTL_PO - ISNULL(CS_DEDUCTION, 0)
    END AS PO_AMT
    /******/
    -- INTO tmpTM_PO
    /******/
FROM
    DETAIL
    LEFT JOIN qryGuarantee G ON G.EMP_EMAIL = DETAIL.EID
    AND G.YYYYMM = DETAIL.YYYYMM
    LEFT JOIN CS_DED ON CS_DED.CS_PO_YYYYMM = DETAIL.YYYYMM
    AND DETAIL.EID = CS_DED.SALES_CREDIT_REP_EMAIL
    LEFT JOIN qryRoster R ON R.REP_EMAIL = DETAIL.EID
    AND R.[isLATEST?] = 1
    AND R.ROLE = 'REP'
WHERE
    DETAIL.YYYYMM = @YYYYMM