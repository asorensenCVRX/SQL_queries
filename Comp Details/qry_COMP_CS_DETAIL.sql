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
            CLOSE_YYYY = '2025'
            OR IMPLANTED_YYYY = '2025'
        )
        AND OPP_COUNTRY = 'US'
        AND INDICATION_FOR_USE__C = 'Heart Failure - Reduced Ejection Fraction'
        AND REASON_FOR_IMPLANT__C IN ('De novo', 'Replacement')
        AND OPP_STATUS = 'CLOSED'
        AND STAGENAME IN ('Revenue Recognized', 'Implant Completed')
)
SELECT
    A.*,
    ISNULL(FTP.PO_PER, 0) AS TGT_PO,
    FTP.[TYPE] AS TGT_TYPE,
    FTP.PO_TYPE
FROM
    (
        SELECT
            RL.REP_EMAIL AS SALES_CREDIT_CS_EMAIL,
            RL.NAME_REP,
            RL.REGION_NM,
            REGION_ID,
            CLOSEDATE,
            ISNULL(
                CLOSE_YYYYMM,
                FORMAT(DATEADD(MONTH, -1, GETDATE()), 'yyyy_MM')
            ) AS CLOSE_YYYYMM,
            CLOSE_YYYYQQ,
            IMPLANTED_DT,
            IMPLANTED_YYYYMM,
            IMPLANTED_YYYYQQ,
            ACCOUNT_INDICATION__C,
            ACT_ID,
            NAME AS OPP_NAME,
            OPP_ID,
            PHYSICIAN,
            PHYSICIAN_ID,
            ISNULL(SALES, 0) AS SALES,
            CASE
                WHEN STAGENAME = 'Revenue Recognized' THEN 1
                ELSE 0
            END AS [REG_ALIGN_ELIGIBLE?],
            ISNULL(IMPLANT_UNITS, 0) AS IMPLANT_UNITS,
            ISNULL(REVENUE_UNITS, 0) AS REVENUE_UNITS,
            REASON_FOR_IMPLANT__C,
            STAGENAME
        FROM
            SALES FULL
            OUTER JOIN (
                SELECT
                    *
                FROM
                    qryReport_Ladder
                WHERE
                    ROLE = 'FCE'
                    /* only FCEs who were termed in or after the previous month */
                     AND (
                        FORMAT(DOT, 'yyyy_MM') >= FORMAT(DATEADD(MONTH, -1, GETDATE()), 'yyyy_MM')
                        OR DOT IS NULL
                    )
                    /* only FCEs who were hired in or before the previous month */
                    AND (
                        FORMAT(DOH, 'yyyy_MM') <= FORMAT(DATEADD(MONTH, -1, GETDATE()), 'yyyy_MM')
                        OR DOH IS NULL
                    )
            ) RL ON SALES.REG_ID = RL.REGION_ID
            /* ensure no credit is given for sales before DOH */
            AND SALES.CLOSEDATE >= RL.DOH
            /* ensure no credit is given for sales after DOT */
            AND SALES.CLOSEDATE <= ISNULL(DOT, '2099-12-31')
    ) AS A
    /* bring in CS targets */
    LEFT JOIN tblFCE_TGT_PO FTP ON A.SALES_CREDIT_CS_EMAIL = FTP.EMAIL
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