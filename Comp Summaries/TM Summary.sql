DECLARE @AsOfDate date = DATEADD(MONTH, -1, GETDATE());

DECLARE @YYYYMM varchar(7) = FORMAT(@AsOfDate, 'yyyy_MM');

DECLARE @YYYYQQ varchar(7) = CONCAT(
    FORMAT(@AsOfDate, 'yyyy'),
    '_Q',
    DATEPART(QUARTER, @AsOfDate)
);

DECLARE @Year int = YEAR(@AsOfDate);

WITH special_idn AS (
    SELECT
        IDN_NAME
    FROM
        (
            VALUES
                ('HCA Healthcare'),
                ('Department of Veterans Affairs'),
                (
                    'Department of Veterans Affairs (AKA Veterans Health Administration)'
                ),
                (
                    'HCA Healthcare (FKA Hospital Corporation of America)'
                )
        ) v(IDN_NAME)
),
base AS (
    SELECT
        T.SALES_CREDIT_REP_EMAIL AS EID,
        T.NAME_REP,
        T.COVERAGE_TYPE,
        T.REGION_NM,
        T.CLOSE_YYYYMM AS YYYYMM,
        T.CLOSE_YYYYQQ AS YYYYQQ,
        T.IMPLANTED_YYYYMM,
        T.IMPLANTED_YYYYQQ,
        T.THRESHOLD,
        T.[PLAN],
        T.SALES_COMMISSIONABLE,
        T.ATM_ACCOUNT_REVENUE,
        T.L1_REV,
        T.L2_REV,
        T.ATM_ACCOUNT_PO,
        T.L1_PO,
        T.L2_PO,
        T.L1_PO + T.L2_PO + T.ATM_ACCOUNT_PO AS L1_L2_ATM_PO,
        T.IMPLANT_UNITS,
        T.REVENUE_UNITS,
        T.IMPLANT_UNITS_FOR_RATIO,
        T.REV_UNITS_FOR_RATIO,
        T.IMPLANTED_DT,
        T.CLOSEDATE,
        T.DHC_IDN_NAME__C,
        CASE
            WHEN S.IDN_NAME IS NOT NULL THEN 1
            ELSE 0
        END AS IS_SPECIAL_IDN
    FROM
        qry_COMP_TM_DETAIL T
        LEFT JOIN special_idn S ON S.IDN_NAME = T.DHC_IDN_NAME__C
),
detail_src AS (
    SELECT
        B.*,
        SUM(
            CASE
                WHEN B.IMPLANTED_YYYYQQ = @YYYYQQ
                AND B.IMPLANTED_YYYYMM <= @YYYYMM THEN B.IMPLANT_UNITS_FOR_RATIO
                ELSE 0
            END
        ) OVER (PARTITION BY B.EID) AS QTD_IMPLANT_UNITS,
        -- QTD rev units
        --HCA/VA rev units do not count towards the ratio on their own (this is unfair to the rep
        --because the sold units might be implanted in a different territory). Instead, each implant 
        --adds 1 implant unit and 1 revenue unit
        SUM(
            CASE
                WHEN B.IS_SPECIAL_IDN = 1
                AND B.IMPLANTED_YYYYQQ = @YYYYQQ
                AND B.IMPLANTED_YYYYMM <= @YYYYMM THEN B.REV_UNITS_FOR_RATIO
                WHEN B.IS_SPECIAL_IDN = 0
                AND B.YYYYQQ = @YYYYQQ
                AND B.YYYYMM <= @YYYYMM THEN B.REV_UNITS_FOR_RATIO
                ELSE 0
            END
        ) OVER (PARTITION BY B.EID) AS QTD_REV_UNITS,
        SUM(
            CASE
                WHEN YEAR(B.IMPLANTED_DT) = @Year
                AND B.IMPLANTED_YYYYMM <= @YYYYMM THEN B.IMPLANT_UNITS_FOR_RATIO
                ELSE 0
            END
        ) OVER (PARTITION BY B.EID) AS YTD_IMPLANT_UNITS,
        SUM(
            CASE
                WHEN B.IS_SPECIAL_IDN = 1
                AND YEAR(B.IMPLANTED_DT) = @Year
                AND B.IMPLANTED_YYYYMM <= @YYYYMM THEN B.REV_UNITS_FOR_RATIO
                WHEN B.IS_SPECIAL_IDN = 0
                AND YEAR(B.CLOSEDATE) = @Year
                AND B.YYYYMM <= @YYYYMM THEN B.REV_UNITS_FOR_RATIO
                ELSE 0
            END
        ) OVER (PARTITION BY B.EID) AS YTD_REV_UNITS,
        SUM(
            CASE
                WHEN B.YYYYQQ = @YYYYQQ
                AND B.YYYYMM <= @YYYYMM THEN B.SALES_COMMISSIONABLE
                ELSE 0
            END
        ) OVER (PARTITION BY B.EID) AS QTD_SALES_COMMISSIONABLE,
        SUM(
            CASE
                WHEN B.YYYYQQ = @YYYYQQ
                AND B.YYYYMM <= @YYYYMM THEN B.SALES_COMMISSIONABLE - B.ATM_ACCOUNT_REVENUE
                ELSE 0
            END
        ) OVER (PARTITION BY B.EID) AS QTD_SALES_MINUS_ATM_REV
    FROM
        base B
),
detail AS (
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
                ELSE 0
            END
        ) AS SALES,
        SUM(
            CASE
                WHEN COVERAGE_TYPE = 'T-SPLIT' THEN SALES_COMMISSIONABLE
                ELSE 0
            END
        ) AS T_SPLIT_SALES,
        MAX(QTD_SALES_COMMISSIONABLE) AS QTD_SALES,
        MAX(QTD_SALES_MINUS_ATM_REV) AS QTD_SALES_MINUS_ATM_REV,
        SUM(ATM_ACCOUNT_REVENUE) AS ATM_ACCOUNT_REVENUE,
        SUM(L1_REV) AS L1_REV,
        SUM(L2_REV) AS L2_REV,
        SUM(ATM_ACCOUNT_PO) AS ATM_ACCOUNT_PO,
        SUM(L1_PO) AS L1_PO,
        SUM(L2_PO) AS L2_PO,
        /* only calc the implant accel true up if it's the last month of the quarter and
         impl_rev_ratio is >= 0.85 */
        /* note that ATM_ACCOUNT_REVENUE is not eligible for implant accel or program accel */
        /*The innermost NULLIF and ISNULL allows the equation to return values even for those who have had no revenue unit sales*/
        MAX(
            CASE
                WHEN ROUND(
                    QTD_IMPLANT_UNITS / ISNULL(NULLIF(QTD_REV_UNITS, 0), 1),
                    2
                ) >= 0.85
                AND RIGHT(YYYYMM, 2) IN ('03', '06', '09', '12') THEN QTD_SALES_MINUS_ATM_REV
                ELSE 0
            END
        ) * 0.05 AS IMPLANT_ACCEL_TRUE_UP,
        SUM(L1_L2_ATM_PO) + MAX(
            CASE
                WHEN ROUND(
                    QTD_IMPLANT_UNITS / ISNULL(NULLIF(QTD_REV_UNITS, 0), 1),
                    2
                ) >= 0.85
                AND RIGHT(YYYYMM, 2) IN ('03', '06', '09', '12') THEN QTD_SALES_MINUS_ATM_REV
                ELSE 0
            END
        ) * 0.05 AS TTL_PO,
        SUM(
            CASE
                WHEN IMPLANTED_YYYYMM = @YYYYMM THEN IMPLANT_UNITS
                ELSE 0
            END
        ) AS IMPLANT_UNITS,
        ROUND(
            MAX(QTD_IMPLANT_UNITS) / ISNULL(NULLIF(MAX(QTD_REV_UNITS), 0), 1),
            2
        ) AS QTD_IMPL_REV_RATIO,
        ROUND(
            MAX(YTD_IMPLANT_UNITS) / ISNULL(NULLIF(MAX(YTD_REV_UNITS), 0), 1),
            2
        ) AS YTD_IMPL_REV_RATIO,
        SUM(REVENUE_UNITS) AS REVENUE_UNITS
    FROM
        detail_src
    GROUP BY
        EID,
        NAME_REP,
        REGION_NM,
        YYYYMM,
        YYYYQQ,
        THRESHOLD,
        [PLAN]
),
atm_rep_calcs AS (
    SELECT
        A2.EID,
        FQ_ATM_ACCT_REV AS QTD_ATM_ACCT_REV,
        M0_ATM_ACCT_REV AS ATM_ACCT_REV,
        M0_ATM_ACCT_REV * 0.15 AS ATM_ACCT_PO,
        A2.L1_REV,
        A2.L1_REV * 0.15 AS L1_PO,
        A2.L2_REV,
        A2.L2_REV * 0.2 AS L2_PO,
        ROUND(
            (
                (FQ_ATM_ACCT_REV * 0.15) + (FQ_L1_REV * 0.15) + (FQ_L2_REV * 0.2)
            ) - TBLPO.QTD_EARNED,
            2
        ) AS L1_L2_ATM_PO
    FROM
        (
            SELECT
                *,
                CASE
                    /* SALES_COMMISSIONABLE is inclusive of all sales in the quarter through the last completed month,
                     and M0_SALES is inclusive of all sales in the month, including sales to ATM targeted accounts */
                    /* if total sales for the quarter are still less than threshold, return this month's sales minus this month's ATM acct rev */
                    WHEN SALES_COMMISSIONABLE <= THRESHOLD THEN M0_SALES - M0_ATM_ACCT_REV
                    /* if total sales for the quarter minus this month's sales are greater than threshold, return 0 */
                    WHEN SALES_COMMISSIONABLE - M0_SALES > THRESHOLD THEN 0
                    /* if total sales for the quarter minus this month's sales bring us below threshold, then
                     return only the sales (non-inclusive of ATM acct sales) that fall below threshold */
                    WHEN SALES_COMMISSIONABLE - M0_SALES < THRESHOLD THEN CASE
                        WHEN (THRESHOLD - FQ_ATM_ACCT_REV) - (
                            (SALES_COMMISSIONABLE - M0_SALES) - (FQ_ATM_ACCT_REV - M0_ATM_ACCT_REV)
                        ) > 0 THEN (THRESHOLD - FQ_ATM_ACCT_REV) - (
                            (SALES_COMMISSIONABLE - M0_SALES) - (FQ_ATM_ACCT_REV - M0_ATM_ACCT_REV)
                        )
                        ELSE THRESHOLD - FQ_ATM_ACCT_REV
                    END
                END AS L1_REV,
                CASE
                    WHEN SALES_COMMISSIONABLE <= THRESHOLD THEN 0
                    WHEN SALES_COMMISSIONABLE - M0_SALES > THRESHOLD THEN M0_SALES - M0_ATM_ACCT_REV
                    WHEN SALES_COMMISSIONABLE - M0_SALES < THRESHOLD THEN CASE
                        WHEN (THRESHOLD - FQ_ATM_ACCT_REV) - (
                            /* sales not including the current month */
                            (SALES_COMMISSIONABLE - M0_SALES) -
                            /* ATM acct rev not including the current month */
                            (FQ_ATM_ACCT_REV - M0_ATM_ACCT_REV)
                            /* result is sales not including the current month and not including ATM rev */
                        ) > 0 THEN (M0_SALES - M0_ATM_ACCT_REV) - (
                            (THRESHOLD - FQ_ATM_ACCT_REV) - (
                                (SALES_COMMISSIONABLE - M0_SALES) - (FQ_ATM_ACCT_REV - M0_ATM_ACCT_REV)
                            )
                        )
                        ELSE (M0_SALES - M0_ATM_ACCT_REV) - (THRESHOLD - FQ_ATM_ACCT_REV)
                    END
                END AS L2_REV,
                CASE
                    WHEN SALES_COMMISSIONABLE <= THRESHOLD THEN SALES_COMMISSIONABLE - FQ_ATM_ACCT_REV
                    WHEN FQ_ATM_ACCT_REV > THRESHOLD THEN 0
                    ELSE THRESHOLD - FQ_ATM_ACCT_REV
                END AS FQ_L1_REV,
                CASE
                    WHEN SALES_COMMISSIONABLE <= THRESHOLD THEN 0
                    WHEN SALES_COMMISSIONABLE - FQ_ATM_ACCT_REV = 0 THEN 0
                    ELSE SALES_COMMISSIONABLE - FQ_ATM_ACCT_REV - CASE
                        WHEN SALES_COMMISSIONABLE <= THRESHOLD THEN SALES_COMMISSIONABLE - FQ_ATM_ACCT_REV
                        WHEN FQ_ATM_ACCT_REV > THRESHOLD THEN 0
                        ELSE THRESHOLD - FQ_ATM_ACCT_REV
                    END
                END AS FQ_L2_REV
            FROM
                (
                    SELECT
                        EID,
                        SUM(SALES_COMMISSIONABLE) AS SALES_COMMISSIONABLE,
                        SUM(ATM_ACCOUNT_REVENUE) AS FQ_ATM_ACCT_REV,
                        SUM(
                            CASE
                                WHEN YYYYMM = @YYYYMM THEN SALES_COMMISSIONABLE
                                ELSE 0
                            END
                        ) AS M0_SALES,
                        SUM(
                            CASE
                                WHEN YYYYMM = @YYYYMM THEN ATM_ACCOUNT_REVENUE
                                ELSE 0
                            END
                        ) AS M0_ATM_ACCT_REV,
                        MAX(THRESHOLD) AS THRESHOLD
                    FROM
                        base
                    WHERE
                        YYYYQQ = @YYYYQQ
                        AND YYYYMM <= @YYYYMM
                    GROUP BY
                        EID
                    HAVING
                        SUM(ATM_ACCOUNT_REVENUE) <> 0
                ) AS A
        ) AS A2
        /* bring in the amount already paid this quarter */
        LEFT JOIN (
            SELECT
                EID,
                SUM(
                    CAST(
                        CASE
                            WHEN CATEGORY = 'TTL_PO' THEN VALUE
                        END AS MONEY
                    )
                ) - SUM(
                    CAST(
                        CASE
                            WHEN CATEGORY = 'CPAS_PO' THEN VALUE
                        END AS MONEY
                    )
                ) AS QTD_EARNED
            FROM
                tblPayout
            WHERE
                EID IN (
                    SELECT
                        DISTINCT EID
                    FROM
                        base
                    WHERE
                        ATM_ACCOUNT_REVENUE <> 0
                        AND YYYYQQ = @YYYYQQ
                )
                AND YYYYQQ = @YYYYQQ
                AND YYYYMM < @YYYYMM
            GROUP BY
                EID
        ) AS TBLPO ON A2.EID = TBLPO.EID
),
program_accel AS (
    SELECT
        T.SALES_CREDIT_REP_EMAIL,
        CONCAT(
            LEFT(T.CLOSE_YYYYQQ, 4),
            '_',
            CASE
                RIGHT(T.CLOSE_YYYYQQ, 1)
                WHEN '1' THEN '03'
                WHEN '2' THEN '06'
                WHEN '3' THEN '09'
                WHEN '4' THEN '12'
            END
        ) AS JOIN_KEY,
        SUM(
            (T.SALES_COMMISSIONABLE - T.ATM_ACCOUNT_REVENUE) * 0.05
        ) AS PROGRAM_ACCEL_PO
    FROM
        qry_COMP_TM_DETAIL T
        INNER JOIN tmpProgram_KPI P ON P.SFDC_ID = T.ACT_ID
        AND P.[isProgram?_EX_CHAMP] = 1
    WHERE
        LEFT(T.CLOSE_YYYYMM, 4) = CAST(@Year AS varchar(4))
        AND T.STAGENAME = 'Revenue Recognized'
    GROUP BY
        T.SALES_CREDIT_REP_EMAIL,
        CONCAT(
            LEFT(T.CLOSE_YYYYQQ, 4),
            '_',
            CASE
                RIGHT(T.CLOSE_YYYYQQ, 1)
                WHEN '1' THEN '03'
                WHEN '2' THEN '06'
                WHEN '3' THEN '09'
                WHEN '4' THEN '12'
            END
        )
),
cpas AS (
    SELECT
        ACCOUNT_OWNER_EMAIL,
        CPAS_SUBMIT_YYYYMM,
        SUM(TM_PO) AS TM_PO
    FROM
        (
            SELECT
                ISNULL(AA.OWNER_EMAIL, U.EMAIL) AS ACCOUNT_OWNER_EMAIL,
                C.CPAS_SUBMIT_YYYYMM,
                CASE
                    WHEN ROW_NUMBER() OVER (
                        PARTITION BY C.PATIENT__C
                        ORDER BY
                            C.CPAS_PA_SUB_DT
                    ) = 1
                    AND C.CPAS_SUBMIT_YYYYMM >= CONCAT(@Year, '_01') THEN 250
                    ELSE 0
                END AS TM_PO
            FROM
                qryCPAS_Cases C
                LEFT JOIN sfdcAccount A ON A.ID = C.ACT_ID
                LEFT JOIN qryAlign_Act AA ON AA.ACT_ID = C.ACT_ID
                AND C.CPAS_PA_SUB_DT BETWEEN AA.ST_DT
                AND AA.END_DT
                LEFT JOIN sfdcUser U ON U.ID = A.OWNERID
            WHERE
                C.[isExcl?] = 0
                AND C.CPAS_PA_SUB_DT IS NOT NULL
        ) X
    WHERE
        CPAS_SUBMIT_YYYYMM >= CONCAT(@Year, '_01')
    GROUP BY
        ACCOUNT_OWNER_EMAIL,
        CPAS_SUBMIT_YYYYMM
),
final_data AS (
    SELECT
        D.EID,
        D.NAME_REP,
        R.DOH,
        R.DOT,
        D.REGION_NM,
        D.YYYYMM,
        D.YYYYQQ,
        D.THRESHOLD,
        D.[PLAN],
        D.SALES,
        D.T_SPLIT_SALES,
        D.QTD_SALES,
        ISNULL(ATM.QTD_ATM_ACCT_REV, 0) AS QTD_ATM_ACCT_REV,
        D.QTD_SALES_MINUS_ATM_REV,
        D.ATM_ACCOUNT_REVENUE,
        ISNULL(ATM.L1_REV, D.L1_REV) AS L1_REV,
        ISNULL(ATM.L2_REV, D.L2_REV) AS L2_REV,
        D.ATM_ACCOUNT_PO,
        ISNULL(ATM.L1_PO, D.L1_PO) AS L1_PO,
        ISNULL(ATM.L2_PO, D.L2_PO) AS L2_PO,
        ISNULL(C.TM_PO, 0) AS CPAS_PO,
        D.IMPLANT_ACCEL_TRUE_UP,
        ISNULL(P.PROGRAM_ACCEL_PO, 0) AS PROGRAM_ACCEL_PO,
        CASE
            WHEN ATM.L1_L2_ATM_PO IS NOT NULL THEN ATM.L1_L2_ATM_PO + D.IMPLANT_ACCEL_TRUE_UP
            ELSE D.TTL_PO
        END AS BASE_TTL_PO,
        D.IMPLANT_UNITS,
        D.REVENUE_UNITS,
        D.QTD_IMPL_REV_RATIO,
        D.YTD_IMPL_REV_RATIO,
        ISNULL(G.PO_AMT, 0) AS GUARANTEE_AMT
    FROM
        detail D
        LEFT JOIN qryGuarantee G ON G.EMP_EMAIL = D.EID
        AND G.YYYYMM = D.YYYYMM
        LEFT JOIN qryRoster R ON R.REP_EMAIL = D.EID
        AND R.[isLATEST?] = 1
        AND R.ROLE = 'REP'
        LEFT JOIN program_accel P ON P.SALES_CREDIT_REP_EMAIL = D.EID
        AND P.JOIN_KEY = D.YYYYMM
        LEFT JOIN cpas C ON C.ACCOUNT_OWNER_EMAIL = D.EID
        AND C.CPAS_SUBMIT_YYYYMM = D.YYYYMM
        LEFT JOIN atm_rep_calcs ATM ON D.EID = ATM.EID
    WHERE
        D.YYYYMM = @YYYYMM
)
SELECT
    EID,
    NAME_REP,
    DOH,
    DOT,
    REGION_NM,
    YYYYMM,
    YYYYQQ,
    THRESHOLD,
    [PLAN],
    SALES,
    T_SPLIT_SALES,
    QTD_SALES,
    QTD_ATM_ACCT_REV,
    QTD_SALES_MINUS_ATM_REV,
    ATM_ACCOUNT_REVENUE,
    L1_REV,
    L2_REV,
    ATM_ACCOUNT_PO,
    L1_PO,
    L2_PO,
    CPAS_PO,
    IMPLANT_ACCEL_TRUE_UP,
    PROGRAM_ACCEL_PO,
    BASE_TTL_PO + PROGRAM_ACCEL_PO + CPAS_PO AS TTL_PO,
    IMPLANT_UNITS,
    REVENUE_UNITS,
    QTD_IMPL_REV_RATIO,
    YTD_IMPL_REV_RATIO,
    GUARANTEE_AMT,
    CASE
        WHEN GUARANTEE_AMT > BASE_TTL_PO + PROGRAM_ACCEL_PO + CPAS_PO THEN GUARANTEE_AMT - (BASE_TTL_PO + PROGRAM_ACCEL_PO + CPAS_PO)
        ELSE 0
    END AS GUARANTEE_ADJ,
    CASE
        WHEN GUARANTEE_AMT > BASE_TTL_PO + PROGRAM_ACCEL_PO + CPAS_PO THEN GUARANTEE_AMT
        ELSE BASE_TTL_PO + PROGRAM_ACCEL_PO + CPAS_PO
    END AS PO_AMT
    /******/
    -- INTO tmpTM_PO
    /******/
FROM
    final_data;