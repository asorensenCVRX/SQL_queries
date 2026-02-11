-- CREATE VIEW qry_COMP_TM_DETAIL AS 
WITH ROSTER AS (
    SELECT
        R.*,
        C.*
    FROM
        qryRoster R
        /* Bring in all months up to and including the current month.
         This is necessary to make even reps with no sales show up in the comp month. */
        CROSS JOIN (
            SELECT
                DISTINCT YYYYMM,
                MONTH_END_DATE,
                YYYYQQ,
                YYYYHH
            FROM
                qryCalendar
            WHERE
                year = 2026
                AND YYYYMM = FORMAT(DATEADD(MONTH, -1, GETDATE()), 'yyyy_MM')
        ) C
    WHERE
        (
            ROLE = 'REP'
            -- OR REP_EMAIL IN (
            --     'ldasilvacampos@cvrx.com',
            --     'bkelly@cvrx.com',
            --     'bsepulvado@cvrx.com',
            --     'egorman@cvrx.com'
            -- )
        )
        /* Pull in all reps from qryReport_Ladder where DOT is greater than or equal to last month 
         or is null, and DOH is before or equal to last month. */
        AND FORMAT(ISNULL(DOT, '2099-12-13'), 'yyyy_MM') >= FORMAT(DATEADD(MONTH, -1, GETDATE()), 'yyyy_MM')
        AND FORMAT(ISNULL(DOH, '1900-01-01'), 'yyyy_MM') <= FORMAT(DATEADD(MONTH, -1, GETDATE()), 'yyyy_MM')
),
ALIGNMENT AS (
    /* use this to align termed reps */
    SELECT
        DISTINCT REP_EMAIL,
        NAME_REP,
        REGION_ID,
        LEFT(REGION_NM, CHARINDEX('(', REGION_NM) - 2) AS REGION_NM
    FROM
        qryRoster
    WHERE
        [isLATEST?] = 1 -- role = 'REP'
        -- /* CS reps with accounts */
        -- OR REP_EMAIL IN ('jobrien@cvrx.com', 'ycruea@cvrx.com')
),
OPPS AS (
    SELECT
        /* DISTINCT must be included so that if a CS has an account target and a physician target that overlap on an opp
         they are not double counted. */
        DISTINCT ISNULL(
            EOMONTH(
                DATEFROMPARTS(LEFT(S.YYYYMM, 4), RIGHT(S.YYYYMM, 2), 1)
            ),
            CLOSEDATE
        ) AS CLOSEDATE,
        ISNULL(S.YYYYMM, CLOSE_YYYYMM) AS CLOSE_YYYYMM,
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
        DHC_IDN_NAME__C,
        ACCOUNT_INDICATION__C,
        O.ACT_ID,
        O.ACT_OWNER_EMAIL,
        OPP_OWNER_EMAIL,
        O.OPP_ID,
        O.NAME,
        PHYSICIAN,
        PHYSICIAN_ID,
        /* first, bring in the email from tblSalesSplits. If that's null, bring in tblAlign_Opp.
         If that's null, bring in the email from tblAlign_Act. And finally, if that is null then bring in
         ACT_OWNER_EMAIL from qryOpps. */
        COALESCE(
            S.SALES_CREDIT_REP_EMAIL,
            AO.EMAIL,
            AA.OWNER_EMAIL,
            O.ACT_OWNER_EMAIL
        ) AS SALES_CREDIT_REP_EMAIL,
        AA.REP_TERR_ID,
        AA.ZIP_TERR_ID,
        AA.DE_FACTO_TERR_ID,
        ISNULL(AO.COVERAGE_TYPE, AA.COVERAGE_TYPE) AS COVERAGE_TYPE,
        INDICATION_FOR_USE__C,
        REASON_FOR_IMPLANT__C,
        STAGENAME,
        ISIMPL,
        /* ENSURE COMP IS ONLY CALC'D FOR 'Revenue Recognized'!!! */
        CASE
            WHEN STAGENAME = 'Revenue Recognized'
            AND S.SPLIT IS NOT NULL THEN IMPLANT_UNITS * S.SPLIT
            WHEN STAGENAME = 'Revenue Recognized'
            AND S.SPLIT IS NULL THEN IMPLANT_UNITS
            ELSE 0
        END AS IMPLANT_UNITS,
        CASE
            WHEN STAGENAME = 'Revenue Recognized'
            AND S.SPLIT IS NOT NULL THEN REVENUE_UNITS * S.SPLIT
            WHEN STAGENAME = 'Revenue Recognized'
            AND S.SPLIT IS NULL THEN REVENUE_UNITS
            ELSE 0
        END AS REVENUE_UNITS,
        CASE
            WHEN STAGENAME = 'Revenue Recognized'
            AND S.SPLIT IS NOT NULL THEN SALES * S.SPLIT
            WHEN STAGENAME = 'Revenue Recognized'
            AND S.SPLIT IS NULL THEN SALES
            ELSE 0
        END AS SALES,
        CASE
            WHEN S.SPLIT IS NOT NULL THEN SALES_COMMISSIONABLE * S.SPLIT
            ELSE SALES_COMMISSIONABLE
        END AS SALES_COMMISSIONABLE,
        CASE
            WHEN STAGENAME = 'Revenue Recognized'
            AND S.SPLIT IS NOT NULL THEN AMOUNT * S.SPLIT
            WHEN STAGENAME = 'Revenue Recognized'
            AND S.SPLIT IS NULL THEN AMOUNT
            ELSE 0
        END AS AMOUNT,
        CASE
            WHEN STAGENAME = 'Revenue Recognized'
            AND S.SPLIT IS NOT NULL THEN O.ASP * S.SPLIT
            WHEN STAGENAME = 'Revenue Recognized'
            AND S.SPLIT IS NULL THEN O.ASP
            ELSE 0
        END AS ASP
        /*****************************************************/
    FROM
        tmpOpps O
        /* check tblAlign_Opp */
        LEFT JOIN tblAlign_Opp AO ON O.OPP_ID = AO.OPP_ID
        /* check tblAlign_Act */
        LEFT JOIN qryAlign_Act AA ON O.ACT_ID = AA.ACT_ID
        AND O.CLOSEDATE BETWEEN AA.ST_DT
        AND AA.END_DT
        /* bring in tblSalesSplits so credit for opps can be shared */
        LEFT JOIN tblSalesSplits S ON O.OPP_ID = S.OPP_ID
    WHERE
        OPP_STATUS = 'CLOSED'
        AND SHIPPINGCOUNTRYCODE = 'US'
        AND INDICATION_FOR_USE__C IN (
            'Heart Failure - Reduced Ejection Fraction',
            'Hypertension'
        )
        AND (
            CLOSE_YYYY = 2026
            OR IMPLANTED_YYYY = 2026
        ) -- AND REASON_FOR_IMPLANT__C IN ('De novo', 'Replacement')
        /* Must keep both 'Revenue Recognized' and 'Implant Completed' to calc CS deductions */
        AND STAGENAME IN ('Revenue Recognized', 'Implant Completed')
        /* Bring in t-splits */
    UNION
    ALL
    SELECT
        CLOSEDATE,
        CLOSE_YYYYMM,
        CLOSE_YYYYQQ,
        IMPLANTED_DT,
        IMPLANTED_YYYYMM,
        IMPLANTED_YYYYQQ,
        NULL,
        ACCOUNT_INDICATION__C,
        ACT_ID,
        ACT_OWNER_EMAIL,
        OPP_OWNER_EMAIL,
        OPP_ID,
        [NAME],
        PHYSICIAN,
        PHYSICIAN_ID,
        OG_OWNER,
        NULL,
        NULL,
        NULL,
        'T-Split' AS COVERAGE_TYPE,
        INDICATION_FOR_USE__C,
        REASON_FOR_IMPLANT__C,
        NULL AS STAGENAME,
        ISIMPL,
        0 AS IMPLANT_UNITS,
        0 AS REVENUE_UNITS,
        OG_OWNER_SALES_CREDIT,
        OG_OWNER_SALES_CREDIT,
        NULL,
        ASP
    FROM
        qryTerritory_Split
    WHERE
        YEAR(CLOSEDATE) = 2026
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
),
OPPS2 AS (
    SELECT
        ISNULL(OPPS.SALES_CREDIT_REP_EMAIL, ROSTER.REP_EMAIL) AS SALES_CREDIT_REP_EMAIL,
        ISNULL(ALIGNMENT.NAME_REP, ROSTER.NAME_REP) AS NAME_REP,
        OPPS.COVERAGE_TYPE,
        OPPS.REP_TERR_ID,
        OPPS.ZIP_TERR_ID,
        OPPS.DE_FACTO_TERR_ID,
        ISNULL(ALIGNMENT.REGION_NM, ROSTER.REGION) AS REGION_NM,
        ISNULL(ALIGNMENT.REGION_ID, ROSTER.REGION_ID) AS REGION_ID,
        OPPS.CLOSEDATE,
        ISNULL(OPPS.CLOSE_YYYYMM, ROSTER.YYYYMM) AS CLOSE_YYYYMM,
        ISNULL(OPPS.CLOSE_YYYYQQ, ROSTER.YYYYQQ) AS CLOSE_YYYYQQ,
        OPPS.IMPLANTED_DT,
        OPPS.IMPLANTED_YYYYMM,
        OPPS.IMPLANTED_YYYYQQ,
        OPPS.DHC_IDN_NAME__C,
        OPPS.ACCOUNT_INDICATION__C,
        OPPS.ACT_ID,
        OPPS.NAME AS OPP_NAME,
        OPPS.OPP_ID,
        OPPS.OPP_OWNER_EMAIL,
        OPPS.PHYSICIAN,
        OPPS.PHYSICIAN_ID,
        OPPS.INDICATION_FOR_USE__C,
        OPPS.REASON_FOR_IMPLANT__C,
        OPPS.STAGENAME,
        ISNULL(OPPS.ISIMPL, 0) AS ISIMPL,
        ISNULL(OPPS.IMPLANT_UNITS, 0) AS IMPLANT_UNITS,
        CASE
            WHEN OPPS.INDICATION_FOR_USE__C = 'Heart Failure - Reduced Ejection Fraction' THEN ISNULL(OPPS.IMPLANT_UNITS, 0)
            ELSE 0
        END AS IMPLANT_UNITS_FOR_RATIO,
        ISNULL(OPPS.REVENUE_UNITS, 0) AS REVENUE_UNITS,
        CASE
            WHEN OPPS.INDICATION_FOR_USE__C = 'Heart Failure - Reduced Ejection Fraction' THEN CASE
                WHEN OPPS.DHC_IDN_NAME__C IN (
                    'HCA Healthcare',
                    'Department of Veterans Affairs'
                )
                AND OPPS.IMPLANT_UNITS <> 0 THEN 1
                WHEN OPPS.DHC_IDN_NAME__C IN (
                    'HCA Healthcare',
                    'Department of Veterans Affairs'
                )
                AND OPPS.IMPLANT_UNITS = 0 THEN 0
                ELSE ISNULL(OPPS.REVENUE_UNITS, 0)
            END
            ELSE 0
        END AS REV_UNITS_FOR_RATIO,
        ISNULL(OPPS.SALES, 0) AS SALES,
        ISNULL(OPPS.SALES_COMMISSIONABLE, 0) AS SALES_COMMISSIONABLE,
        CASE
            WHEN ISNULL(AMOUNT, 0) <> OPPS.SALES THEN 1
            ELSE 0
        END AS [REBATE?],
        ISNULL(ASP, 0) AS ASP,
        THRESHOLD,
        [PLAN],
        SUM(ISNULL(OPPS.SALES_COMMISSIONABLE, 0)) OVER (
            PARTITION BY ISNULL(OPPS.SALES_CREDIT_REP_EMAIL, ROSTER.REP_EMAIL),
            ISNULL(OPPS.CLOSE_YYYYQQ, ROSTER.YYYYQQ)
            ORDER BY
                ISNULL(OPPS.CLOSEDATE, ROSTER.MONTH_END_DATE),
                ISNULL(OPPS.NAME, 'ZZZ')
        ) AS QTD_SALES_COMISSIONABLE,
        /* make sure implants are only counted based on impl date, not closedate */
        SUM(ISNULL(OPPS.IMPLANT_UNITS, 0)) OVER(
            PARTITION BY ISNULL(OPPS.SALES_CREDIT_REP_EMAIL, ROSTER.REP_EMAIL),
            ISNULL(OPPS.IMPLANTED_YYYYQQ, ROSTER.YYYYQQ)
            ORDER BY
                ISNULL(OPPS.IMPLANTED_DT, OPPS.CLOSEDATE),
                OPPS.NAME
        ) AS QTD_IMPLANT_UNITS,
        SUM(ISNULL(OPPS.REVENUE_UNITS, 0)) OVER(
            PARTITION BY ISNULL(OPPS.SALES_CREDIT_REP_EMAIL, ROSTER.REP_EMAIL),
            ISNULL(OPPS.CLOSE_YYYYQQ, ROSTER.YYYYQQ)
            ORDER BY
                OPPS.CLOSEDATE,
                OPPS.NAME
        ) AS QTD_REVENUE_UNITS,
        ATM.ATM_EMAIL
    FROM
        ROSTER FULL
        OUTER JOIN OPPS ON ROSTER.REP_EMAIL = OPPS.SALES_CREDIT_REP_EMAIL
        AND OPPS.CLOSE_YYYYMM = ROSTER.YYYYMM
        LEFT JOIN QUOTA ON ISNULL(OPPS.SALES_CREDIT_REP_EMAIL, ROSTER.REP_EMAIL) = QUOTA.EID
        AND ISNULL(OPPS.CLOSE_YYYYQQ, ROSTER.YYYYQQ) = QUOTA.YYYYQQ
        LEFT JOIN ALIGNMENT ON OPPS.SALES_CREDIT_REP_EMAIL = ALIGNMENT.REP_EMAIL
        LEFT JOIN qry_COMP_ATM_DETAIL ATM ON ATM.OPP_ID = OPPS.OPP_ID
),
CALC AS (
    SELECT
        *,
        /*sales to an ATM targeted account*/
        CASE
            WHEN ATM_EMAIL IS NOT NULL THEN SALES_COMMISSIONABLE
            ELSE 0
        END AS ATM_ACCOUNT_REVENUE,
        CASE
            /* L1_REV value is 0 if there is an ATM who gets credit */
            WHEN ATM_EMAIL IS NOT NULL THEN 0
            ELSE CASE
                /* If a rep's ACTIVE_YYYYMM is next month, but the rep has sales, ensure those sales are L1 revenue */
                WHEN THRESHOLD = 0 THEN SALES_COMMISSIONABLE
                /*triggers only if ATM_EMAIL is null AND THRESHOLD <> 0*/
                ELSE CASE
                    /*if this sale is negative and we're still below threshold then sales*/
                    WHEN ISNULL(SALES_COMMISSIONABLE, 0) < 0
                    AND ISNULL(QTD_SALES_COMISSIONABLE, 0) <= THRESHOLD THEN SALES_COMMISSIONABLE
                    /*if we are not currently above threshold then all sales are in L1 still*/
                    WHEN ISNULL(QTD_SALES_COMISSIONABLE, 0) <= THRESHOLD THEN ISNULL(SALES_COMMISSIONABLE, 0)
                    /*if we were NOT already above threshold then return a portion/all of this sale up to threshold*/
                    WHEN (
                        ISNULL(QTD_SALES_COMISSIONABLE, 0) - ISNULL(SALES_COMMISSIONABLE, 0)
                    ) <= THRESHOLD THEN THRESHOLD - (
                        ISNULL(QTD_SALES_COMISSIONABLE, 0) - ISNULL(SALES_COMMISSIONABLE, 0)
                    )
                    ELSE 0
                END
            END
        END AS L1_REV,
        CASE
            /* L2_REV value is 0 if there is an ATM who gets credit */
            WHEN ATM_EMAIL IS NOT NULL THEN 0
            ELSE CASE
                WHEN THRESHOLD = 0 THEN 0
                /*triggers only if ATM_EMAIL is null AND THRESHOLD <> 0*/
                ELSE CASE
                    /*Solve: if this sales is negative and we're currently l2 and previously were in l2 then sales  */
                    WHEN ISNULL(SALES_COMMISSIONABLE, 0) < 0
                    AND ISNULL(QTD_SALES_COMISSIONABLE, 0) > THRESHOLD
                    AND ISNULL(QTD_SALES_COMISSIONABLE, 0) - ISNULL(SALES_COMMISSIONABLE, 0) > THRESHOLD THEN SALES_COMMISSIONABLE
                    /*Solve: if this sales is negative and we're no longer above threshold but we were before this line item then   */
                    WHEN ISNULL(SALES_COMMISSIONABLE, 0) < 0
                    AND ISNULL(QTD_SALES_COMISSIONABLE, 0) < THRESHOLD
                    AND ISNULL(
                        QTD_SALES_COMISSIONABLE,
                        0
                    ) - ISNULL(SALES_COMMISSIONABLE, 0) > THRESHOLD THEN (THRESHOLD - ISNULL(QTD_SALES_COMISSIONABLE, 0)) + ISNULL(SALES_COMMISSIONABLE, 0)
                    /*Solve: if we're already passed quota before this record OR sales is still below Q4BL at this line then 0 sales get passed. */
                    WHEN (ISNULL(QTD_SALES_COMISSIONABLE, 0)) <= THRESHOLD
                    OR ISNULL(SALES_COMMISSIONABLE, 0) = 0 THEN 0
                    /*Solve: if we were already at/passed threshold then sales */
                    WHEN (
                        ISNULL(QTD_SALES_COMISSIONABLE, 0) - ISNULL(SALES_COMMISSIONABLE, 0)
                    ) > THRESHOLD
                    AND ISNULL(QTD_SALES_COMISSIONABLE, 0) >= THRESHOLD THEN SALES_COMMISSIONABLE
                    /*Solve: if we are now at/passed threshold and currently less than quota then take the sales over the threshold */
                    WHEN ISNULL(QTD_SALES_COMISSIONABLE, 0) >= THRESHOLD THEN ISNULL(QTD_SALES_COMISSIONABLE, 0) - THRESHOLD
                    ELSE 0
                END
            END
        END L2_REV,
        QTD_IMPLANT_UNITS / COALESCE(NULLIF(QTD_REVENUE_UNITS, 0), 1) AS QTD_IMPL_REV_RATIO
    FROM
        OPPS2
)
SELECT
    *,
    ATM_ACCOUNT_REVENUE * 0.15 AS ATM_ACCOUNT_PO,
    L1_REV * 0.15 AS L1_PO,
    L2_REV * 0.2 AS L2_PO
FROM
    CALC