-- CREATE VIEW qryTerritory_Split AS 
WITH OPPS AS (
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
        ISIMPL,
        IMPLANT_UNITS,
        REVENUE_UNITS,
        SALES,
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
        AND SHIPPINGCOUNTRYCODE = 'US'
        AND INDICATION_FOR_USE__C = 'Heart Failure - Reduced Ejection Fraction'
        AND REASON_FOR_IMPLANT__C IN ('De novo', 'Replacement')
        AND STAGENAME = 'Revenue Recognized'
        AND sales <> 0
),
TS AS (
    SELECT
        T.*,
        ISNULL(R.DOT, '2099-12-31') AS DOT
    FROM
        tblTerr_Split T
        LEFT JOIN qryRoster R ON T.ORIGINAL_OWNER = R.REP_EMAIL
        AND R.[isLATEST?] = 1
)
SELECT
    TS.ORIGINAL_OWNER AS OG_OWNER,
    TS.DOT AS OG_OWNER_DOT,
    TS.ST_DATE AS SPLIT_START,
    -- DATEADD(DAY, 270, TS.ST_DATE) AS SPLIT_END,
    CASE
        WHEN OPPS.CLOSEDATE BETWEEN TS.ST_DATE
        AND DATEADD(DAY, 90, TS.ST_DATE) THEN '90%'
        WHEN opps.CLOSEDATE BETWEEN DATEADD(DAY, 91, TS.ST_DATE)
        AND DATEADD(DAY, 180, TS.ST_DATE) THEN '60%'
        WHEN opps.CLOSEDATE BETWEEN DATEADD(DAY, 181, TS.ST_DATE)
        AND DATEADD(DAY, 270, TS.ST_DATE) THEN '25%'
    END AS [OG_OWNER_%_CREDIT],
    CASE
        WHEN OPPS.CLOSEDATE BETWEEN TS.ST_DATE
        AND DATEADD(DAY, 90, TS.ST_DATE) THEN SALES * 0.9
        WHEN opps.CLOSEDATE BETWEEN DATEADD(DAY, 91, TS.ST_DATE)
        AND DATEADD(DAY, 180, TS.ST_DATE) THEN SALES * 0.6
        WHEN opps.CLOSEDATE BETWEEN DATEADD(DAY, 181, TS.ST_DATE)
        AND DATEADD(DAY, 270, TS.ST_DATE) THEN SALES * 0.25
    END AS [OG_OWNER_SALES_CREDIT],
    OPPS.*
FROM
    OPPS
    INNER JOIN TS ON OPPS.ACT_ID = TS.ACT_ID
    AND OPPS.SALES_CREDIT_REP_EMAIL <> TS.ORIGINAL_OWNER
    AND OPPS.CLOSEDATE BETWEEN TS.ST_DATE
    /* ensure splits end at termination date of original owner, if applicable */
    AND CASE
        WHEN TS.DOT < DATEADD(DAY, 270, TS.ST_DATE) THEN TS.DOT
        ELSE DATEADD(DAY, 270, TS.ST_DATE)
    END