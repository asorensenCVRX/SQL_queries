-- CREATE VIEW qry_COMP_ATM_DETAIL AS 
WITH OPPS AS (
    SELECT
        CLOSEDATE,
        CLOSE_YYYYMM,
        CLOSE_YYYYQQ,
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
            AO.EMAIL,
            AA.OWNER_EMAIL,
            O.ACT_OWNER_EMAIL
        ) AS SALES_CREDIT_REP_EMAIL,
        -- AA.REP_TERR_ID,
        -- AA.ZIP_TERR_ID,
        AA.DE_FACTO_TERR_ID,
        -- ISNULL(AO.COVERAGE_TYPE, AA.COVERAGE_TYPE) AS COVERAGE_TYPE,
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
        SALES_COMMISSIONABLE,
        CASE
            WHEN STAGENAME = 'Revenue Recognized' THEN AMOUNT
            ELSE 0
        END AS AMOUNT,
        CASE
            WHEN STAGENAME = 'Revenue Recognized' THEN O.ASP
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
        )
        AND STAGENAME IN ('Revenue Recognized', 'Implant Completed')
),
ROSTER AS (
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
        [ROLE] = 'ATM'
        AND [isLATEST?] = 1
        AND FORMAT(ISNULL(DOT, '2099-12-13'), 'yyyy_MM') >= FORMAT(DATEADD(MONTH, -1, GETDATE()), 'yyyy_MM')
        AND FORMAT(ISNULL(DOH, '1900-01-01'), 'yyyy_MM') <= FORMAT(DATEADD(MONTH, -1, GETDATE()), 'yyyy_MM')
),
ATM_OPPS AS (
    SELECT
        T.EMAIL AS ATM_EMAIL,
        OPPS.*
    FROM
        OPPS
        LEFT JOIN tblACCT_TGT T ON T.OBJ_ID = OPPS.ACT_ID
        AND OPPS.CLOSE_YYYYMM BETWEEN T.YYYYMM_START
        AND T.YYYYMM_END
        AND PO_TYPE = 'MBO'
    WHERE
        T.EMAIL IS NOT NULL
)
SELECT
    ISNULL(O.ATM_EMAIL, R.REP_EMAIL) AS ATM_EMAIL,
    R.NAME_REP AS ATM_NAME,
    R.REGION,
    O.CLOSEDATE,
    ISNULL(O.CLOSE_YYYYMM, R.YYYYMM) AS CLOSE_YYYYMM,
    ISNULL(O.CLOSE_YYYYQQ, R.YYYYQQ) AS CLOSE_YYYYQQ,
    IMPLANTED_DT,
    IMPLANTED_YYYYMM,
    IMPLANTED_YYYYQQ,
    DHC_IDN_NAME__C,
    ACCOUNT_INDICATION__C,
    ACT_ID,
    ACT_OWNER_EMAIL,
    OPP_OWNER_EMAIL,
    OPP_ID,
    [NAME] AS OPP_NAME,
    PHYSICIAN,
    PHYSICIAN_ID,
    SALES_CREDIT_REP_EMAIL,
    DE_FACTO_TERR_ID,
    INDICATION_FOR_USE__C,
    REASON_FOR_IMPLANT__C,
    STAGENAME,
    ISIMPL,
    IMPLANT_UNITS,
    REVENUE_UNITS,
    SALES,
    SALES_COMMISSIONABLE,
    SALES_COMMISSIONABLE * 0.1 AS PAYOUT
FROM
    ROSTER R FULL
    OUTER JOIN ATM_OPPS O ON R.REP_EMAIL = O.ATM_EMAIL
    AND R.YYYYMM = O.CLOSE_YYYYMM