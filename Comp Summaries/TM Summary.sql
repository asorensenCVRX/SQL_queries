WITH DETAIL AS (
    SELECT
        EID,
        NAME_REP,
        REGION_NM,
        YYYYMM,
        YYYYQQ,
        THRESHOLD,
        [PLAN],
        SUM(SALES) AS SALES,
        MAX(QTD_SALES) AS QTD_SALES,
        SUM(L1_REV) AS L1_REV,
        SUM(L2_REV) AS L2_REV,
        SUM(L1_PO) AS L1_PO,
        SUM(L2_PO) AS L2_PO,
        SUM(CS_DEDUCTION) AS CS_DEDUCTION,
        /* only calc the implant accel true up if it's the last month of the quarter and
         impl_rev_ratio is >= 0.85 */
        MAX(
            CASE
                WHEN IMPL_REV_RATIO >= 0.85
                AND YYYYMM IN ('2025_03', '2025_06', '2025_09', '2025_12') THEN QTD_SALES
                ELSE 0
            END
        ) * 0.05 AS IMPLANT_ACCEL_TRUE_UP,
        SUM(L1_L2_PO) + (
            MAX(
                CASE
                    WHEN IMPL_REV_RATIO >= 0.85
                    AND YYYYMM IN ('2025_03', '2025_06', '2025_09', '2025_12') THEN QTD_SALES
                    ELSE 0
                END
            ) * 0.05
        ) - SUM(CS_DEDUCTION) AS TTL_PO,
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
                SALES,
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
                FIRST_VALUE(QTD_SALES) OVER (
                    PARTITION BY SALES_CREDIT_REP_EMAIL,
                    CLOSE_YYYYQQ
                    ORDER BY
                        CLOSEDATE DESC
                ) AS QTD_SALES,
                [CS_PO_$] + [CS_PO_%] AS CS_DEDUCTION
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
)
SELECT
    DETAIL.*,
    ISNULL(G.PO_AMT, 0) AS GAURANTEE_AMT,
    CASE
        WHEN ISNULL(G.PO_AMT, 0) > TTL_PO THEN G.PO_AMT - TTL_PO
        ELSE 0
    END AS GAURANTEE_ADJ,
    CASE
        WHEN ISNULL(G.PO_AMT, 0) > TTL_PO THEN G.PO_AMT
        ELSE TTL_PO
    END AS PO_AMT
FROM
    DETAIL
    LEFT JOIN qryGuarantee G ON G.EMP_EMAIL = DETAIL.EID
    AND G.YYYYMM = DETAIL.YYYYMM 
    -- WHERE DETAIL.YYYYMM = FORMAT(DATEADD(MONTH, -1, GETDATE()), 'yyyy_MM')