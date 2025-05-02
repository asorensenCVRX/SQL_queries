-- CREATE VIEW qry_COMP_ASD_DETAIL AS 
WITH ROSTER AS (
    /* Pull in all reps from qryReport_Ladder where DOT is greater than or equal to last month 
     or is null, and DOH is before or equal to last month. */
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
                AND YYYYMM = FORMAT(DATEADD(MONTH, -1, GETDATE()), 'yyyy_MM')
        ) C
    WHERE
        (
            ROLE = 'REP'
            OR REP_EMAIL IN ('ldasilvacampos@cvrx.com', 'ycruea@cvrx.com')
        )
        AND (
            FORMAT(DOT, 'yyyy-MM') >= FORMAT(DATEADD(MONTH, -1, GETDATE()), 'yyyy-MM')
            OR DOT IS NULL
        )
        AND (
            FORMAT(DOH, 'yyyy_MM') <= FORMAT(DATEADD(MONTH, -1, GETDATE()), 'yyyy_MM')
            OR DOH IS NULL
        )
),
ALIGNMENT AS (
    /* use this to align termed reps */
    SELECT
        DISTINCT REP_EMAIL,
        NAME_REP,
        REGION_ID,
        RM_EMAIL,
        LEFT(REGION_NM, CHARINDEX('(', REGION_NM) - 2) AS REGION_NM
    FROM
        qryRoster
    WHERE
        role = 'REP'
        OR
        /* CS REPS WITH ACCOUNTS */
        REP_EMAIL IN ('ycruea@cvrx.com', 'jobrien@cvrx.com')
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
        COALESCE(AO.EMAIL, AA.OWNER_EMAIL, O.ACT_OWNER_EMAIL) AS SALES_CREDIT_REP_EMAIL,
        INDICATION_FOR_USE__C,
        REASON_FOR_IMPLANT__C,
        ISIMPL,
        IMPLANT_UNITS,
        REVENUE_UNITS,
        SALES,
        SALES_COMMISSIONABLE,
        AMOUNT,
        ASP
    FROM
        tmpOpps O
        /* check tblAlign_Opp */
        LEFT JOIN tblAlign_Opp AO ON O.OPP_ID = AO.OPP_ID
        /* check tblAlign_Act */
        LEFT JOIN tblAlign_Act AA ON O.ACT_ID = AA.ACT_ID
        AND O.CLOSEDATE BETWEEN AA.ST_DT
        AND AA.END_DT
    WHERE
        OPP_STATUS = 'CLOSED'
        AND SHIPPINGCOUNTRYCODE = 'US' -- AND INDICATION_FOR_USE__C = 'Heart Failure - Reduced Ejection Fraction'
        AND (
            CLOSE_YYYY = 2025
            OR IMPLANTED_YYYY = 2025
        )
        AND REASON_FOR_IMPLANT__C IN ('De novo', 'Replacement')
        AND STAGENAME = 'Revenue Recognized'
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
    L1_REV * [L1 Rate] AS L1_PO,
    L2_REV * [L2 Rate] AS L2_PO
FROM
    (
        SELECT
            *,
            CASE
                WHEN SALES_COMMISSIONABLE < 0
                AND QTD_SALES_COMMISSIONABLE <= THRESHOLD THEN SALES_COMMISSIONABLE
                WHEN QTD_SALES_COMMISSIONABLE <= THRESHOLD THEN SALES_COMMISSIONABLE
                WHEN QTD_SALES_COMMISSIONABLE - SALES_COMMISSIONABLE <= THRESHOLD THEN THRESHOLD - (QTD_SALES_COMMISSIONABLE - SALES_COMMISSIONABLE)
                ELSE 0
            END AS L1_REV,
            CASE
                WHEN SALES_COMMISSIONABLE < 0
                AND QTD_SALES_COMMISSIONABLE > THRESHOLD
                AND QTD_SALES_COMMISSIONABLE - SALES_COMMISSIONABLE > THRESHOLD THEN SALES_COMMISSIONABLE
                WHEN SALES_COMMISSIONABLE < 0
                AND QTD_SALES_COMMISSIONABLE < THRESHOLD
                AND QTD_SALES_COMMISSIONABLE - SALES_COMMISSIONABLE > THRESHOLD THEN THRESHOLD - (QTD_SALES_COMMISSIONABLE + SALES_COMMISSIONABLE)
                WHEN QTD_SALES_COMMISSIONABLE <= THRESHOLD
                OR SALES_COMMISSIONABLE = 0 THEN 0
                WHEN QTD_SALES_COMMISSIONABLE - SALES_COMMISSIONABLE > THRESHOLD
                AND QTD_SALES_COMMISSIONABLE >= THRESHOLD THEN SALES_COMMISSIONABLE
                WHEN QTD_SALES_COMMISSIONABLE >= THRESHOLD THEN QTD_SALES_COMMISSIONABLE - THRESHOLD
                ELSE NULL
            END AS L2_REV
        FROM
            (
                SELECT
                    ISNULL(ROSTER.REGION_NM, ALIGNMENT.REGION_NM) AS REGION_NM,
                    ISNULL(ROSTER.REGION_ID, ALIGNMENT.REGION_ID) AS REGION_ID,
                    ISNULL(ROSTER.RM_EMAIL, ALIGNMENT.RM_EMAIL) AS SALES_CREDIT_ASD_EMAIL,
                    SALES_CREDIT_REP_EMAIL,
                    OPPS.CLOSEDATE,
                    CLOSE_YYYYMM,
                    OPPS.CLOSE_YYYYQQ,
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
                    ISNULL(ISIMPL, 0) AS ISIMPL,
                    ISNULL(IMPLANT_UNITS, 0) AS IMPLANT_UNITS,
                    ISNULL(REVENUE_UNITS, 0) AS REVENUE_UNITS,
                    ISNULL(SALES, 0) AS SALES,
                    ISNULL(SALES_COMMISSIONABLE, 0) AS SALES_COMMISSIONABLE,
                    CASE
                        WHEN ISNULL(AMOUNT, 0) <> ISNULL(SALES, 0) THEN 1
                        ELSE 0
                    END AS [REBATE?],
                    ISNULL(ASP, 0) AS ASP,
                    QUOTA.THRESHOLD,
                    QUOTA.[PLAN],
                    [L1 Rate],
                    [L2 Rate],
                    SUM(ISNULL(SALES_COMMISSIONABLE, 0)) OVER (
                        PARTITION BY ISNULL(ROSTER.RM_EMAIL, ALIGNMENT.RM_EMAIL),
                        OPPS.CLOSE_YYYYQQ
                        ORDER BY
                            OPPS.CLOSEDATE,
                            OPPS.NAME
                    ) AS QTD_SALES_COMMISSIONABLE,
                    /* make sure implants are only counted based on impl date, not closedate */
                    SUM(ISNULL(IMPLANT_UNITS, 0)) OVER(
                        PARTITION BY ISNULL(ROSTER.RM_EMAIL, ALIGNMENT.RM_EMAIL),
                        OPPS.IMPLANTED_YYYYQQ
                        ORDER BY
                            ISNULL(OPPS.IMPLANTED_DT, OPPS.CLOSEDATE),
                            OPPS.NAME
                    ) AS QTD_IMPLANT_UNITS,
                    SUM(ISNULL(REVENUE_UNITS, 0)) OVER(
                        PARTITION BY ISNULL(ROSTER.RM_EMAIL, ALIGNMENT.RM_EMAIL),
                        OPPS.CLOSE_YYYYQQ
                        ORDER BY
                            OPPS.CLOSEDATE,
                            OPPS.NAME
                    ) AS QTD_REVENUE_UNITS
                FROM
                    ROSTER
                    RIGHT JOIN OPPS ON ROSTER.REP_EMAIL = OPPS.SALES_CREDIT_REP_EMAIL
                    AND ROSTER.YYYYMM = OPPS.CLOSE_YYYYMM
                    LEFT JOIN ALIGNMENT ON ALIGNMENT.REP_EMAIL = OPPS.SALES_CREDIT_REP_EMAIL
                    LEFT JOIN tblRates_RM R ON R.REGION_ID = ISNULL(ROSTER.REGION_ID, ALIGNMENT.REGION_ID)
                    LEFT JOIN QUOTA ON ISNULL(ROSTER.RM_EMAIL, ALIGNMENT.RM_EMAIL) = QUOTA.EID
                    AND OPPS.CLOSE_YYYYQQ = QUOTA.YYYYQQ
            ) AS A
        WHERE
            CLOSE_YYYYMM <= FORMAT(DATEADD(MONTH, -1, GETDATE()), 'yyyy_MM')
    ) AS B