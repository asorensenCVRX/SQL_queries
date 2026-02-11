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
        SUM(
            CASE
                WHEN COVERAGE_TYPE <> 'T-SPLIT' THEN SALES_COMMISSIONABLE
            END
        ) AS SALES,
        SUM(
            CASE
                WHEN COVERAGE_TYPE = 'T-SPLIT' THEN SALES_COMMISSIONABLE
            END
        ) AS T_SPLIT_SALES,
        MAX(QTD_SALES_COMMISSIONABLE) AS QTD_SALES,
        SUM(L1_REV) AS L1_REV,
        SUM(L2_REV) AS L2_REV,
        SUM(L1_PO) AS L1_PO,
        SUM(L2_PO) AS L2_PO,
        /* only calc the implant accel true up if it's the last month of the quarter and
         impl_rev_ratio is >= 0.85 */
        /*The innermost NULLIF and ISNULL allows the equation to return values even for those who have had no revenue unit sales*/
        MAX(
            CASE
                WHEN QTD_IMPLANT_UNITS / ISNULL(NULLIF(QTD_REV_UNITS, 0), 1) >= 0.85
                AND YYYYMM IN ('2026_03', '2026_06', '2026_09', '2026_12') THEN QTD_SALES_COMMISSIONABLE
                ELSE 0
            END
        ) * 0.05 AS IMPLANT_ACCEL_TRUE_UP,
        SUM(L1_L2_PO) + (
            MAX(
                CASE
                    WHEN QTD_IMPLANT_UNITS / ISNULL(NULLIF(QTD_REV_UNITS, 0), 1) >= 0.85
                    AND YYYYMM IN ('2026_03', '2026_06', '2026_09', '2026_12') THEN QTD_SALES_COMMISSIONABLE
                    ELSE 0
                END
            ) * 0.05
        ) AS TTL_PO,
        SUM(
            CASE
                WHEN IMPLANTED_YYYYMM = @YYYYMM THEN IMPLANT_UNITS
                ELSE 0
            END
        ) AS IMPLANT_UNITS,
        MAX(QTD_IMPLANT_UNITS) / ISNULL(NULLIF(MAX(QTD_REV_UNITS), 0), 1) AS QTD_IMPL_REV_RATIO,
        MAX(YTD_IMPLANT_UNITS) / ISNULL(NULLIF(MAX(YTD_REV_UNITS), 0), 1) AS YTD_IMPL_REV_RATIO,
        SUM(REVENUE_UNITS) AS REVENUE_UNITS
    FROM
        (
            SELECT
                SALES_CREDIT_REP_EMAIL AS EID,
                NAME_REP,
                COVERAGE_TYPE,
                REGION_NM,
                CLOSE_YYYYMM AS YYYYMM,
                CLOSE_YYYYQQ AS YYYYQQ,
                IMPLANTED_YYYYMM,
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
                --always count implant units if they occurred within last month's quarter
                SUM(
                    CASE
                        WHEN IMPLANTED_YYYYQQ = @YYYYQQ
                        AND IMPLANTED_YYYYMM <= @YYYYMM THEN IMPLANT_UNITS_FOR_RATIO
                        ELSE 0
                    END
                ) OVER (PARTITION BY SALES_CREDIT_REP_EMAIL) AS QTD_IMPLANT_UNITS,
                -- QTD rev units
                --HCA/VA rev units do not count towards the ratio on their own (this is unfair to the rep
                --because the sold units might be implanted in a different territory). Instead, each implant 
                --adds 1 implant unit and 1 revenue unit
                SUM(
                    CASE
                        WHEN DHC_IDN_NAME__C IN (
                            'HCA Healthcare',
                            'Department of Veterans Affairs'
                        )
                        AND IMPLANTED_YYYYQQ = @YYYYQQ
                        AND IMPLANTED_YYYYMM <= @YYYYMM THEN REV_UNITS_FOR_RATIO
                        WHEN CLOSE_YYYYQQ = @YYYYQQ
                        AND CLOSE_YYYYMM <= @YYYYMM
                        AND (
                            DHC_IDN_NAME__C NOT IN (
                                'HCA Healthcare',
                                'Department of Veterans Affairs'
                            )
                            OR DHC_IDN_NAME__C IS NULL
                        ) THEN REV_UNITS_FOR_RATIO
                    END
                ) OVER (PARTITION BY SALES_CREDIT_REP_EMAIL) AS QTD_REV_UNITS,
                -- YTD implant units
                SUM(
                    CASE
                        WHEN YEAR(IMPLANTED_DT) = 2026
                        AND IMPLANTED_YYYYMM <= @YYYYMM THEN IMPLANT_UNITS_FOR_RATIO
                        ELSE 0
                    END
                ) OVER (PARTITION BY SALES_CREDIT_REP_EMAIL) AS YTD_IMPLANT_UNITS,
                -- YTD rev units
                SUM(
                    CASE
                        WHEN DHC_IDN_NAME__C IN (
                            'HCA Healthcare',
                            'Department of Veterans Affairs'
                        )
                        AND YEAR(IMPLANTED_DT) = 2026
                        AND IMPLANTED_YYYYMM <= @YYYYMM THEN REV_UNITS_FOR_RATIO
                        WHEN YEAR(CLOSEDATE) = 2026
                        AND CLOSE_YYYYMM <= @YYYYMM
                        AND (
                            DHC_IDN_NAME__C NOT IN (
                                'HCA Healthcare',
                                'Department of Veterans Affairs'
                            )
                            OR DHC_IDN_NAME__C IS NULL
                        ) THEN REV_UNITS_FOR_RATIO
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
                    WHEN CLOSE_YYYYQQ = '2026_Q1' THEN '2026_03'
                    WHEN CLOSE_YYYYQQ = '2026_Q2' THEN '2026_06'
                    WHEN CLOSE_YYYYQQ = '2026_Q3' THEN '2026_09'
                    WHEN CLOSE_YYYYQQ = '2026_Q4' THEN '2026_12'
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
),
CPAS AS (
    SELECT
        ACCOUNT_OWNER_EMAIL,
        CPAS_SUBMIT_YYYYMM,
        SUM(TM_PO) AS TM_PO
    FROM
        (
            SELECT
                ISNULL(AA.OWNER_EMAIL, U.EMAIL) AS ACCOUNT_OWNER_EMAIL,
                CPAS_SUBMIT_YYYYMM,
                CASE
                    WHEN ROW_NUMBER() OVER(
                        PARTITION BY PATIENT__C
                        ORDER BY
                            CPAS_PA_SUB_DT
                    ) = 1
                    AND CPAS_SUBMIT_YYYYMM >= '2026_01' THEN 250
                    ELSE 0
                END AS TM_PO
            FROM
                qryCPAS_Cases C
                LEFT JOIN sfdcAccount A ON A.ID = C.ACT_ID
                LEFT JOIN qryAlign_Act AA ON AA.ACT_ID = C.ACT_ID
                AND C.CPAS_PA_SUB_DT BETWEEN AA.ST_DT
                AND AA.END_DT
                LEFT JOIN sfdcUser U ON A.OWNERID = U.ID
            WHERE
                [isExcl?] = 0
                AND CPAS_PA_SUB_DT IS NOT NULL
        ) AS A
    WHERE
        CPAS_SUBMIT_YYYYMM >= '2026_01'
    GROUP BY
        ACCOUNT_OWNER_EMAIL,
        CPAS_SUBMIT_YYYYMM
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
    T_SPLIT_SALES,
    QTD_SALES,
    L1_REV,
    L2_REV,
    L1_PO,
    L2_PO,
    ISNULL(CPAS.TM_PO, 0) AS CPAS_PO,
    IMPLANT_ACCEL_TRUE_UP,
    ISNULL(PRGRM_ACCEL.PROGRAM_ACCEL_PO, 0) AS PROGRAM_ACCEL_PO,
    TTL_PO + ISNULL(PRGRM_ACCEL.PROGRAM_ACCEL_PO, 0) + ISNULL(CPAS.TM_PO, 0) AS TTL_PO,
    IMPLANT_UNITS,
    REVENUE_UNITS,
    QTD_IMPL_REV_RATIO,
    YTD_IMPL_REV_RATIO,
    ISNULL(G.PO_AMT, 0) AS GAURANTEE_AMT,
    CASE
        WHEN ISNULL(G.PO_AMT, 0) > (
            TTL_PO + ISNULL(PRGRM_ACCEL.PROGRAM_ACCEL_PO, 0)
        ) + ISNULL(CPAS.TM_PO, 0) THEN G.PO_AMT - (
            TTL_PO + ISNULL(PRGRM_ACCEL.PROGRAM_ACCEL_PO, 0) + ISNULL(CPAS.TM_PO, 0)
        )
        ELSE 0
    END AS GAURANTEE_ADJ,
    CASE
        WHEN ISNULL(G.PO_AMT, 0) > (
            TTL_PO + ISNULL(PRGRM_ACCEL.PROGRAM_ACCEL_PO, 0)
        ) + ISNULL(CPAS.TM_PO, 0) THEN G.PO_AMT
        ELSE TTL_PO + ISNULL(PRGRM_ACCEL.PROGRAM_ACCEL_PO, 0) + ISNULL(CPAS.TM_PO, 0)
    END AS PO_AMT
    /******/
    -- INTO tmpTM_PO
    /******/
FROM
    DETAIL
    LEFT JOIN qryGuarantee G ON G.EMP_EMAIL = DETAIL.EID
    AND G.YYYYMM = DETAIL.YYYYMM
    LEFT JOIN qryRoster R ON R.REP_EMAIL = DETAIL.EID
    AND R.[isLATEST?] = 1
    AND R.ROLE = 'REP'
    LEFT JOIN PRGRM_ACCEL ON PRGRM_ACCEL.JOIN_KEY = DETAIL.YYYYMM
    AND PRGRM_ACCEL.SALES_CREDIT_REP_EMAIL = DETAIL.EID
    LEFT JOIN CPAS ON CPAS.ACCOUNT_OWNER_EMAIL = DETAIL.EID
    AND CPAS.CPAS_SUBMIT_YYYYMM = DETAIL.YYYYMM
WHERE
    DETAIL.YYYYMM = @YYYYMM