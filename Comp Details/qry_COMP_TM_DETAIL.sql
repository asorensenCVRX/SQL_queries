-- CREATE VIEW qry_COMP_TM_DETAIL AS 
WITH ROSTER AS (
    SELECT
        RL.*,
        C.*
    FROM
        qryReport_Ladder RL
        /* Bring in all months up to and including the current month.
         This is necessary to make even reps with no sales show up in the comp month. */
        CROSS JOIN (
            SELECT
                DISTINCT YYYYMM,
                YYYYQQ,
                YYYYHH
            FROM
                qryCalendar
            WHERE
                year = 2025
                AND YYYYMM <= FORMAT(GETDATE(), 'yyyy_MM') -- AND YYYYMM <= FORMAT(DATEADD(MONTH, -1, GETDATE()), 'yyyy_MM')
        ) C
    WHERE
        ROLE = 'REP'
        /* Pull in all reps from qryReport_Ladder where DOT is greater than or equal to last month 
         or is null, and DOH is before or equal to last month. */
        AND (
            FORMAT(DOT, 'yyyy-MM') >= FORMAT(DATEADD(MONTH, -1, GETDATE()), 'yyyy-MM')
            OR DOT IS NULL
        )
        AND (
            FORMAT(DOH, 'yyyy_MM') <= FORMAT(DATEADD(MONTH, -1, GETDATE()), 'yyyy_MM')
            OR DOH IS NULL
        )
),
OPPS AS (
    SELECT
        CLOSEDATE,
        CLOSE_YYYYMM,
        CLOSE_YYYYQQ,
        IMPLANTED_DT,
        IMPLANTED_YYYYMM,
        IMPLANTED_YYYYQQ,
        ACCOUNT_INDICATION__C,
        O.ACT_ID,
        O.ACT_OWNER_EMAIL,
        OPP_OWNER_EMAIL,
        O.OPP_ID,
        O.NAME,
        PHYSICIAN,
        PHYSICIAN_ID,
        /* first, bring in the email from tblAlign_Opp.
         If that's null, bring in the email from tblAlign_Act. And finally, if that is null then bring in
         ACT_OWNER_EMAIL from qryOpps. */
        ISNULL(
            ISNULL(
                AO.EMAIL,
                AA.OWNER_EMAIL
            ),
            O.ACT_OWNER_EMAIL
        ) AS SALES_CREDIT_REP_EMAIL,
        INDICATION_FOR_USE__C,
        REASON_FOR_IMPLANT__C,
        STAGENAME,
        ISIMPL,
        /* ENSURE COMP IS ONLY CALC'D FOR 'Revenue Recognized'!!! */
        CASE
            WHEN STAGENAME = 'Revenue Recognized' THEN IMPLANT_UNITS
            ELSE 0
        END AS IMPLANT_UNITS,
        CASE
            WHEN STAGENAME = 'Revenue Recognized' THEN REVENUE_UNITS
            ELSE 0
        END AS REVENUE_UNITS,
        CASE
            WHEN STAGENAME = 'Revenue Recognized' THEN SALES
            ELSE 0
        END AS SALES,
        CASE
            WHEN STAGENAME = 'Revenue Recognized' THEN ASP
            ELSE 0
        END AS ASP,
        /*****************************************************/
        T.EMAIL AS CS_PO_EMAIL,
        CASE
            WHEN T.PO_TYPE = 'revenue' THEN ISNULL(T.PO_PER, 0) * REVENUE_UNITS
            ELSE ISNULL(T.PO_PER, 0)
        END AS PO_PER,
        CASE
            WHEN T.PO_TYPE = 'revenue' THEN SALES * ISNULL(T.[PO_%], 0)
            ELSE ISNULL(T.[PO_%], 0)
        END AS [PO_%],
        T.PO_TYPE
    FROM
        tmpOpps O
        /* check tblAlign_Opp */
        LEFT JOIN tblAlign_Opp AO ON O.OPP_ID = AO.OPP_ID
        /* check tblAlign_Act */
        LEFT JOIN tblAlign_Act AA ON O.ACT_ID = AA.ACT_ID
        AND O.CLOSEDATE BETWEEN AA.ST_DT
        AND AA.END_DT
        /* check FCE payouts */
        /* join obj_id from tblFCE_TGT_PO on either account id or physician id, depending on the target */
        LEFT JOIN tblFCE_TGT_PO T ON CASE
            WHEN T.[TYPE] = 'ACCT' THEN O.ACT_ID
            WHEN T.[TYPE] = 'DOC' THEN O.PHYSICIAN_ID
        END = T.OBJ_ID
        /* if CS is paid on revenue, make sure the close date is valid for payment.
         If CS is paid on implants, make sure the impalant date is valid for payment. */
        AND CASE
            WHEN T.PO_TYPE = 'implant' THEN O.IMPLANTED_YYYYMM
            WHEN T.PO_TYPE = 'revenue' THEN O.CLOSE_YYYYMM
        END BETWEEN T.YYYYMM_START
        AND T.YYYYMM_END
        /* If po_type is implant, only join on opps that have an implant.
         If po_type is revenue, only join on opps that have revenue units */
        AND CASE
            WHEN T.PO_TYPE = 'implant' THEN O.ISIMPL
            WHEN T.PO_TYPE = 'revenue' THEN O.REVENUE_UNITS
        END >= 1
    WHERE
        OPP_STATUS = 'CLOSED'
        AND SHIPPINGCOUNTRYCODE = 'US'
        AND INDICATION_FOR_USE__C = 'Heart Failure - Reduced Ejection Fraction'
        AND (
            CLOSE_YYYY = 2025
            OR IMPLANTED_YYYY = 2025
        )
        AND REASON_FOR_IMPLANT__C IN ('De novo', 'Replacement')
        /* Must keep both 'Revenue Recognized' and 'Implant Completed' to calc CS deductions */
        AND STAGENAME IN ('Revenue Recognized', 'Implant Completed')
),
QUOTA AS (
    SELECT
        YYYYQQ,
        TERRITORY_ID,
        EID,
        SUM(THRESHOLD) AS THRESHOLD,
        SUM([PLAN]) AS [PLAN]
    FROM
        qryQuota_Monthly
    WHERE
        TERRITORY_ID NOT LIKE '%OFF%'
    GROUP BY
        YYYYQQ,
        TERRITORY_ID,
        EID
)
SELECT
    *,
    L1_REV * 0.15 AS L1_PO,
    L2_REV * 0.2 AS L2_PO
FROM
    (
        SELECT
            *,
            CASE
                /*Solve: if this sales is negative and we're still below threshold then sales  */
                WHEN ISNULL(sales, 0) < 0
                AND ISNULL(QTD_SALES, 0) <= THRESHOLD THEN SALES
                /*Solve: if were not currently above threshold then all Sales are in L1 still */
                WHEN ISNULL(QTD_SALES, 0) <= THRESHOLD THEN ISNULL(sales, 0)
                /*Solve:   if we were NOT already above threshold then return a portion/all of this sale up to threshold*/
                WHEN (ISNULL(QTD_SALES, 0) - ISNULL(sales, 0)) <= THRESHOLD THEN THRESHOLD - (ISNULL(QTD_SALES, 0) - ISNULL(sales, 0))
                ELSE 0
            END AS L1_REV,
            CASE
                /*Solve: if this sales is negative and we're currently l2 and previously were in l2 then sales  */
                WHEN ISNULL(sales, 0) < 0
                AND ISNULL(QTD_SALES, 0) > THRESHOLD
                AND ISNULL(QTD_SALES, 0) - ISNULL(sales, 0) > THRESHOLD THEN sales
                /*Solve: if this sales is negative and we're no longer above threshold but we were before this line item then   */
                WHEN ISNULL(sales, 0) < 0
                AND ISNULL(QTD_SALES, 0) < THRESHOLD
                AND ISNULL(
                    QTD_SALES,
                    0
                ) - ISNULL(sales, 0) > THRESHOLD THEN (THRESHOLD - ISNULL(QTD_SALES, 0)) + ISNULL(sales, 0)
                /*Solve: if we're already passed quota before this record OR sales is still below Q4BL at this line then 0 sales get passed. */
                WHEN (ISNULL(QTD_SALES, 0)) <= THRESHOLD
                OR ISNULL(SALES, 0) = 0 THEN 0
                /*Solve: if we were already at/passed threshold then sales */
                WHEN (ISNULL(QTD_SALES, 0) - ISNULL(sales, 0)) > THRESHOLD
                AND ISNULL(QTD_SALES, 0) >= THRESHOLD THEN sales
                /*Solve: if we are now at/passed threshold and currently less than quota then take the sales over the threshold */
                WHEN ISNULL(QTD_SALES, 0) >= THRESHOLD THEN ISNULL(QTD_SALES, 0) - THRESHOLD
                ELSE NULL
            END L2_REV,
            QTD_IMPLANT_UNITS / COALESCE(NULLIF(QTD_REVENUE_UNITS, 0), 1) AS QTD_IMPL_REV_RATIO
        FROM
            (
                SELECT
                    ISNULL(OPPS.SALES_CREDIT_REP_EMAIL, ROSTER.REP_EMAIL) AS SALES_CREDIT_REP_EMAIL,
                    NAME_REP,
                    REGION_NM,
                    REGION_ID,
                    OPPS.CLOSEDATE,
                    ISNULL(OPPS.CLOSE_YYYYMM, ROSTER.YYYYMM) AS CLOSE_YYYYMM,
                    ISNULL(OPPS.CLOSE_YYYYQQ, ROSTER.YYYYQQ) AS CLOSE_YYYYQQ,
                    OPPS.IMPLANTED_DT,
                    OPPS.IMPLANTED_YYYYMM,
                    OPPS.IMPLANTED_YYYYQQ,
                    OPPS.ACCOUNT_INDICATION__C,
                    OPPS.ACT_ID,
                    OPPS.NAME AS OPP_NAME,
                    OPPS.OPP_ID,
                    OPPS.PHYSICIAN,
                    OPPS.PHYSICIAN_ID,
                    OPPS.INDICATION_FOR_USE__C,
                    OPPS.REASON_FOR_IMPLANT__C,
                    STAGENAME,
                    ISNULL(ISIMPL, 0) AS ISIMPL,
                    ISNULL(IMPLANT_UNITS, 0) AS IMPLANT_UNITS,
                    ISNULL(REVENUE_UNITS, 0) AS REVENUE_UNITS,
                    ISNULL(SALES, 0) AS SALES,
                    ISNULL(ASP, 0) AS ASP,
                    THRESHOLD,
                    [PLAN],
                    SUM(ISNULL(SALES, 0)) OVER (
                        PARTITION BY ISNULL(OPPS.SALES_CREDIT_REP_EMAIL, ROSTER.REP_EMAIL),
                        ISNULL(OPPS.CLOSE_YYYYQQ, ROSTER.YYYYQQ)
                        ORDER BY
                            OPPS.CLOSEDATE,
                            OPPS.NAME
                    ) AS QTD_SALES,
                    /* make sure implants are only counted based on impl date, not closedate */
                    SUM(ISNULL(IMPLANT_UNITS, 0)) OVER(
                        PARTITION BY ISNULL(OPPS.SALES_CREDIT_REP_EMAIL, ROSTER.REP_EMAIL),
                        ISNULL(OPPS.IMPLANTED_YYYYQQ, ROSTER.YYYYQQ)
                        ORDER BY
                            ISNULL(OPPS.IMPLANTED_DT, OPPS.CLOSEDATE),
                            OPPS.NAME
                    ) AS QTD_IMPLANT_UNITS,
                    SUM(ISNULL(REVENUE_UNITS, 0)) OVER(
                        PARTITION BY ISNULL(OPPS.SALES_CREDIT_REP_EMAIL, ROSTER.REP_EMAIL),
                        ISNULL(OPPS.CLOSE_YYYYQQ, ROSTER.YYYYQQ)
                        ORDER BY
                            OPPS.CLOSEDATE,
                            OPPS.NAME
                    ) AS QTD_REVENUE_UNITS,
                    CS_PO_EMAIL,
                    ISNULL(PO_PER, 0) AS [CS_PO_$],
                    ISNULL([PO_%], 0) AS [CS_PO_%],
                    PO_TYPE AS CS_PO_TYPE,
                    CASE
                        WHEN PO_TYPE = 'implant' THEN IMPLANTED_YYYYMM
                        WHEN PO_TYPE = 'revenue' THEN CLOSE_YYYYMM
                        ELSE NULL
                    END AS CS_PO_YYYYMM
                FROM
                    ROSTER FULL
                    OUTER JOIN OPPS ON ROSTER.REP_EMAIL = OPPS.SALES_CREDIT_REP_EMAIL
                    AND ROSTER.YYYYMM = OPPS.CLOSE_YYYYMM
                    LEFT JOIN QUOTA ON ISNULL(OPPS.SALES_CREDIT_REP_EMAIL, ROSTER.REP_EMAIL) = QUOTA.EID
                    AND ISNULL(OPPS.CLOSE_YYYYQQ, ROSTER.YYYYQQ) = QUOTA.YYYYQQ
            ) AS A
    ) AS B