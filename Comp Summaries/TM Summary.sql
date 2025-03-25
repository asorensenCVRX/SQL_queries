DECLARE @YYYYMM AS VARCHAR(7) = FORMAT(DATEADD(MONTH, -1, GETDATE()), 'yyyy_MM');


DECLARE @YYYYQQ AS VARCHAR(7) = CONCAT(
    FORMAT(DATEADD(MONTH, -1, GETDATE()), 'yyyy'),
    '_Q',
    DATEPART(QUARTER, DATEADD(MONTH, -1, GETDATE()))
);


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
        /*YOU MUST wrap these values in multiple layers of NULLIF and ISNULL. The innermost NULLIF and ISNULL
         allows the equation to return values even for those who have had no revenue unit sales. The outer NULLIF and ISNULL
         allows people who have had ONLY HCA/VA sales or implants to still be given a ratio.
         EX. Andrew Hilovsky had only VA sales and implants in Q1. Since VA sales/implants DO NOT count towards your ratio,
         he would have a ratio of 0, meaning he would not receive any IMPLANT_ACCEL_TRUE_UP, even though he had 3 implant units
         and 3 revenue units. THEREFORE, ANYONE WITH A RATIO OF 0 IS DEFAULTED TO A RATIO OF 1. People with no implants/sales
         will also receive a ratio of 1... but that doesn't matter, since there is nothing to true them up on.
         */
        MAX(
            CASE
                WHEN ISNULL(
                    NULLIF(
                        QTD_IMPLANT_UNITS / ISNULL(NULLIF(QTD_REV_UNITS, 0), 1),
                        0
                    ),
                    1
                ) >= 0.85
                AND YYYYMM IN ('2025_03', '2025_06', '2025_09', '2025_12') THEN QTD_SALES_COMMISSIONABLE
                ELSE 0
            END
        ) * 0.05 AS IMPLANT_ACCEL_TRUE_UP,
        SUM(L1_L2_PO) + (
            MAX(
                CASE
                    WHEN ISNULL(
                        NULLIF(
                            QTD_IMPLANT_UNITS / ISNULL(NULLIF(QTD_REV_UNITS, 0), 1),
                            0
                        ),
                        1
                    ) >= 0.85
                    AND YYYYMM IN ('2025_03', '2025_06', '2025_09', '2025_12') THEN QTD_SALES_COMMISSIONABLE
                    ELSE 0
                END
            ) * 0.05
        ) AS TTL_PO,
        SUM(IMPLANT_UNITS) AS IMPLANT_UNITS,
        ISNULL(
            NULLIF(
                MAX(QTD_IMPLANT_UNITS) / ISNULL(NULLIF(MAX(QTD_REV_UNITS), 0), 1),
                0
            ),
            1
        ) AS QTD_IMPL_REV_RATIO,
        ISNULL(
            NULLIF(
                MAX(YTD_IMPLANT_UNITS) / ISNULL(NULLIF(MAX(YTD_REV_UNITS), 0), 1),
                0
            ),
            1
        ) AS YTD_IMPL_REV_RATIO,
        SUM(REVENUE_UNITS) AS REVENUE_UNITS
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
                --QTD implant units
                SUM(
                    CASE
                        WHEN IMPLANTED_YYYYQQ = @YYYYQQ
                        AND IMPLANTED_YYYYMM <= @YYYYMM
                        AND (
                            DHC_IDN_NAME__C NOT IN (
                                'HCA Healthcare',
                                'Department of Veterans Affairs'
                            )
                            OR DHC_IDN_NAME__C IS NULL
                        ) THEN IMPLANT_UNITS
                        ELSE 0
                    END
                ) OVER (PARTITION BY SALES_CREDIT_REP_EMAIL) AS QTD_IMPLANT_UNITS,
                -- QTD rev units
                SUM(
                    CASE
                        WHEN CLOSE_YYYYQQ = @YYYYQQ
                        AND CLOSE_YYYYMM <= @YYYYMM
                        AND (
                            DHC_IDN_NAME__C NOT IN (
                                'HCA Healthcare',
                                'Department of Veterans Affairs'
                            )
                            OR DHC_IDN_NAME__C IS NULL
                        ) THEN REVENUE_UNITS
                        ELSE 0
                    END
                ) OVER (PARTITION BY SALES_CREDIT_REP_EMAIL) AS QTD_REV_UNITS,
                -- YTD implant units
                SUM(
                    CASE
                        WHEN YEAR(IMPLANTED_DT) = 2025
                        AND IMPLANTED_YYYYMM <= @YYYYMM
                        AND (
                            DHC_IDN_NAME__C NOT IN (
                                'HCA Healthcare',
                                'Department of Veterans Affairs'
                            )
                            OR DHC_IDN_NAME__C IS NULL
                        ) THEN IMPLANT_UNITS
                        ELSE 0
                    END
                ) OVER (PARTITION BY SALES_CREDIT_REP_EMAIL) AS YTD_IMPLANT_UNITS,
                -- YTD rev units
                SUM(
                    CASE
                        WHEN YEAR(CLOSEDATE) = 2025
                        AND CLOSE_YYYYMM <= @YYYYMM
                        AND (
                            DHC_IDN_NAME__C NOT IN (
                                'HCA Healthcare',
                                'Department of Veterans Affairs'
                            )
                            OR DHC_IDN_NAME__C IS NULL
                        ) THEN REVENUE_UNITS
                        ELSE 0
                    END
                ) OVER (PARTITION BY SALES_CREDIT_REP_EMAIL) AS YTD_REV_UNITS,
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
),
PRGRM_ACCEL AS (
    SELECT
        SALES_CREDIT_REP_EMAIL,
        JOIN_KEY,
        SUM(PROGRAM_ACCEL_PO) AS PROGRAM_ACCEL_PO
    FROM
        (
            SELECT
                CLOSEDATE,
                CLOSE_YYYYMM,
                CLOSE_YYYYQQ,
                CASE
                    WHEN CLOSE_YYYYQQ = '2025_Q1' THEN '2025_03'
                    WHEN CLOSE_YYYYQQ = '2025_Q2' THEN '2025_06'
                    WHEN CLOSE_YYYYQQ = '2025_Q3' THEN '2025_09'
                    WHEN CLOSE_YYYYQQ = '2025_Q4' THEN '2025_12'
                END AS JOIN_KEY,
                IMPLANTED_DT,
                IMPLANTED_YYYYMM,
                ACCOUNT_INDICATION__C,
                ACT_ID,
                DHC_IDN_NAME__C,
                OPP_NAME,
                OPP_ID,
                SALES_CREDIT_REP_EMAIL,
                SALES_COMMISSIONABLE,
                SALES_COMMISSIONABLE * 0.05 AS PROGRAM_ACCEL_PO
            FROM
                qry_COMP_TM_DETAIL T
            WHERE
                ACT_ID IN (
                    SELECT
                        SFDC_ID
                    FROM
                        tmpProgram_KPI
                    WHERE
                        [EXCLUDE?] = 'NO'
                        AND [IMPLANTS (ALL)] >= 15
                        AND CONSISTENCY >= 6
                        AND [ARC (R12)] >= 5
                        AND [SURG (R12)] >= 2
                )
                AND STAGENAME = 'Revenue Recognized'
        ) AS P
    GROUP BY
        SALES_CREDIT_REP_EMAIL,
        JOIN_KEY
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
    ISNULL(PRGRM_ACCEL.PROGRAM_ACCEL_PO, 0) AS PROGRAM_ACCEL_PO,
    TTL_PO - ISNULL(CS_DEDUCTION, 0) + ISNULL(PRGRM_ACCEL.PROGRAM_ACCEL_PO, 0) AS TTL_PO,
    IMPLANT_UNITS,
    REVENUE_UNITS,
    QTD_IMPL_REV_RATIO,
    YTD_IMPL_REV_RATIO,
    ISNULL(G.PO_AMT, 0) AS GAURANTEE_AMT,
    CASE
        WHEN ISNULL(G.PO_AMT, 0) > TTL_PO + ISNULL(PRGRM_ACCEL.PROGRAM_ACCEL_PO, 0) THEN G.PO_AMT - TTL_PO
        ELSE 0
    END AS GAURANTEE_ADJ,
    CASE
        WHEN ISNULL(G.PO_AMT, 0) > TTL_PO + ISNULL(PRGRM_ACCEL.PROGRAM_ACCEL_PO, 0) THEN G.PO_AMT
        ELSE TTL_PO - ISNULL(CS_DEDUCTION, 0) + ISNULL(PRGRM_ACCEL.PROGRAM_ACCEL_PO, 0)
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
    LEFT JOIN PRGRM_ACCEL ON PRGRM_ACCEL.JOIN_KEY = DETAIL.YYYYMM
    AND PRGRM_ACCEL.SALES_CREDIT_REP_EMAIL = DETAIL.EID
WHERE
    DETAIL.YYYYMM = @YYYYMM