-- CREATE VIEW qry_COMP_CS_DETAIL AS 
/* targeted accounts are paid ONLY ON DE NOVO, but also on implant completed.
 Region alignments are paid on de novo and replacement, but only on rev rec */
WITH SALES AS (
    SELECT
        *
    FROM
        tmpOpps
    WHERE
        (
            CLOSE_YYYY IN (2025, 2026)
            OR IMPLANTED_YYYY = '2025'
        )
        AND OPP_COUNTRY = 'US' -- AND INDICATION_FOR_USE__C = 'Heart Failure - Reduced Ejection Fraction'
        AND REASON_FOR_IMPLANT__C IN ('De novo', 'Replacement')
        AND OPP_STATUS = 'CLOSED'
        AND STAGENAME IN ('Revenue Recognized', 'Implant Completed')
),
ROSTER AS (
    SELECT
        R.*
    FROM
        qryROSTER R
    WHERE
        ROLE = 'FCE'
        AND ISNULL(DOT_YYYYMM, '2099_12') >= FORMAT(DATEADD(MONTH, -1, GETDATE()), 'yyyy_MM')
)
SELECT
    *
FROM
    (
        SELECT
            A.*,
            CASE
                WHEN FTP.PO_TYPE = 'revenue' THEN ISNULL(FTP.PO_PER, 0) * REVENUE_UNITS
                WHEN FTP.PO_TYPE = 'implant' THEN ISNULL(FTP.PO_PER, 0)
            END AS TGT_PO,
            CASE
                WHEN FTP.PO_TYPE = 'revenue' THEN SALES * ISNULL(FTP.[PO_%], 0)
                WHEN FTP.PO_TYPE = 'implant' THEN ISNULL(FTP.[PO_%], 0)
            END AS [PO_%],
            FTP.[TYPE] AS TGT_TYPE,
            FTP.PO_TYPE,
            CASE
                WHEN PO_TYPE = 'implant' THEN IMPLANTED_YYYYMM
                WHEN PO_TYPE = 'revenue' THEN CLOSE_YYYYMM
                ELSE NULL
            END AS TGT_PO_YYYYMM,
            /* This RN field ensures that CS reps with an accout target and a physician target
             that overlap on the same opp do not get double comp'd */
            CASE
                WHEN FTP.[TYPE] IS NULL THEN 0
                ELSE ROW_NUMBER() OVER (
                    PARTITION BY SALES_CREDIT_CS_EMAIL,
                    OPP_ID
                    ORDER BY
                        FTP.[TYPE]
                )
            END AS RN
        FROM
            (
                SELECT
                    RL.REP_EMAIL AS SALES_CREDIT_CS_EMAIL,
                    RL.NAME_REP,
                    RL.REGION_NM,
                    REGION_ID,
                    ISNULL(
                        EOMONTH(
                            DATEFROMPARTS(LEFT(S.YYYYMM, 4), RIGHT(S.YYYYMM, 2), 1)
                        ),
                        CLOSEDATE
                    ) AS CLOSEDATE,
                    COALESCE(
                        S.YYYYMM,
                        CLOSE_YYYYMM,
                        FORMAT(DATEADD(MONTH, -1, GETDATE()), 'yyyy_MM')
                    ) AS CLOSE_YYYYMM,
                    CASE
                        WHEN S.YYYYMM IS NOT NULL THEN CONCAT(
                            LEFT(S.YYYYMM, 4),
                            '_Q',
                            DATEPART(
                                QUARTER,
                                DATEFROMPARTS(LEFT(S.YYYYMM, 4), RIGHT(S.YYYYMM, 2), 1)
                            )
                        )
                        ELSE CLOSE_YYYYQQ
                    END AS CLOSE_YYYYQQ,
                    IMPLANTED_DT,
                    IMPLANTED_YYYYMM,
                    IMPLANTED_YYYYQQ,
                    ACCOUNT_INDICATION__C,
                    ACT_ID,
                    NAME AS OPP_NAME,
                    SALES.OPP_ID,
                    PHYSICIAN,
                    PHYSICIAN_ID,
                    CASE
                        WHEN S.SPLIT IS NOT NULL THEN S.SPLIT * SALES
                        ELSE ISNULL(SALES, 0)
                    END AS SALES,
                    -- ISNULL(SALES, 0) AS SALES,
                    CASE
                        WHEN S.SPLIT IS NOT NULL THEN S.SPLIT * SALES_COMMISSIONABLE
                        ELSE ISNULL(SALES_COMMISSIONABLE, 0)
                    END AS SALES_COMMISSIONABLE,
                    -- ISNULL(SALES_COMMISSIONABLE, 0) AS SALES_COMMISSIONABLE,
                    SUM(
                        CASE
                            WHEN STAGENAME = 'Revenue Recognized' THEN (ISNULL(SALES_COMMISSIONABLE, 0))
                            ELSE 0
                        END
                    ) OVER (
                        PARTITION BY RL.REP_EMAIL
                        ORDER BY
                            CLOSEDATE,
                            NAME
                    ) AS YTD_SALES_COMMISSIONABLE,
                    CASE
                        WHEN STAGENAME = 'Revenue Recognized' THEN 1
                        ELSE 0
                    END AS [REG_ALIGN_ELIGIBLE?],
                    CASE
                        WHEN S.SPLIT IS NOT NULL THEN S.SPLIT * IMPLANT_UNITS
                        ELSE ISNULL(IMPLANT_UNITS, 0)
                    END AS IMPLANT_UNITS,
                    -- ISNULL(IMPLANT_UNITS, 0) AS IMPLANT_UNITS,
                    CASE
                        WHEN S.SPLIT IS NOT NULL THEN S.SPLIT * REVENUE_UNITS
                        ELSE ISNULL(REVENUE_UNITS, 0)
                    END AS REVENUE_UNITS,
                    -- ISNULL(REVENUE_UNITS, 0) AS REVENUE_UNITS,
                    REASON_FOR_IMPLANT__C,
                    STAGENAME
                FROM
                    SALES FULL
                    OUTER JOIN ROSTER RL ON SALES.REG_ID = RL.REGION_ID
                    /* ensure no credit is given for sales before DOH */
                    AND SALES.CLOSE_YYYYMM >= RL.ACTIVE_YYYYMM
                    /* ensure no credit is given for sales after DOT */
                    AND SALES.CLOSEDATE <= ISNULL(DOT, '2099-12-31')
                    /* sales splits */
                    LEFT JOIN tblSalesSplits S ON S.OPP_ID = SALES.OPP_ID
                    AND S.OPP_ID NOT IN ('006UY00000PpE5lYAF', '006UY00000U6L5LYAV')
            ) AS A
            /* bring in CS targets */
            LEFT JOIN tblACCT_TGT FTP ON A.SALES_CREDIT_CS_EMAIL = FTP.EMAIL
            AND CASE
                WHEN FTP.[TYPE] = 'ACCT' THEN A.ACT_ID
                WHEN FTP.[TYPE] = 'DOC' THEN A.PHYSICIAN_ID
            END = FTP.OBJ_ID
            /* if CS is paid on revenue, make sure the close date is valid for payment.
             If CS is paid on implants, make sure the impalant date is valid for payment. */
            AND CASE
                WHEN FTP.PO_TYPE = 'implant' THEN A.IMPLANTED_YYYYMM
                WHEN FTP.PO_TYPE = 'revenue' THEN A.CLOSE_YYYYMM
            END BETWEEN FTP.YYYYMM_START
            AND FTP.YYYYMM_END
            /* If po_type is implant, only join on opps that have an implant.
             If po_type is revenue, only join on opps that have revenue units */
            AND CASE
                WHEN FTP.PO_TYPE = 'implant' THEN A.IMPLANT_UNITS
                WHEN FTP.PO_TYPE = 'revenue' THEN A.REVENUE_UNITS
            END >= 1
            /* targets are only paid on de novo */
            AND REASON_FOR_IMPLANT__C = 'De novo'
    ) AS A
WHERE
    RN IN (0, 1)