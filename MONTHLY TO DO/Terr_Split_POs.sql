WITH OPPS AS (
    SELECT
        *
    FROM
        (
            SELECT
                CLOSEDATE,
                CLOSE_YYYYMM,
                IMPLANTED_YYYYMM,
                ACCOUNT_INDICATION__C,
                O.ACT_ID,
                O.OPP_ID,
                O.NAME,
                PHYSICIAN,
                PHYSICIAN_ID,
                OPP_OWNER_EMAIL,
                /* first, bring in the emails on the splits table. If those are null, bring in the email from tblAlign_Opp.
                 If that's null, bring in the sales_credit_rep_email from qryOpps.
                 Finally, if that's null, bring in the AM_FOR_CREDIT_EMAIL from qryOpps. */
                ISNULL(
                    ISNULL(
                        splits.REP_EMAIL,
                        ISNULL(
                            AO.EMAIL,
                            O.SALES_CREDIT_REP_EMAIL
                        )
                    ),
                    O.AM_FOR_CREDIT_EMAIL
                ) AS SALES_CREDIT_REP_EMAIL,
                INDICATION_FOR_USE__C,
                REASON_FOR_IMPLANT__C,
                ISIMPL,
                CASE
                    WHEN splits.SPLIT IS NOT NULL THEN 1
                    ELSE 0
                END AS [isSPLIT?],
                splits.SPLIT,
                CASE
                    WHEN splits.SPLIT IS NOT NULL THEN IMPLANT_UNITS * SPLIT
                    ELSE IMPLANT_UNITS
                END AS IMPLANT_UNITS,
                CASE
                    WHEN splits.SPLIT IS NOT NULL THEN REVENUE_UNITS * SPLIT
                    ELSE REVENUE_UNITS
                END AS REVENUE_UNITS,
                CASE
                    WHEN splits.SPLIT IS NOT NULL THEN SALES * SPLIT
                    ELSE SALES
                END AS SALES,
                ASP,
                T.EMAIL AS FCE_PO_EMAIL,
                T.PO_PER,
                T.[PO_%]
            FROM
                qryOpps O
                /* check tblAlign_Opp */
                LEFT JOIN tblAlign_Opp AO ON O.OPP_ID = AO.OPP_ID
                /* check account splits */
                LEFT JOIN tblActSplits splits ON O.ACT_ID = splits.ACT_ID
                AND CLOSE_YYYYMM BETWEEN splits.YYYYMM_ST
                AND splits.YYYYMM_END
                /* check FCE payouts */
                LEFT JOIN tblFCE_TGT_PO T ON CASE
                    WHEN T.[TYPE] = 'ACCT' THEN O.ACT_ID
                    WHEN T.[TYPE] = 'DOC' THEN O.PHYSICIAN_ID
                END = T.OBJ_ID
                AND O.CLOSE_YYYYMM BETWEEN T.YYYYMM_START
                AND T.YYYYMM_END
                AND O.ISIMPL = 1
            WHERE
                OPP_STATUS = 'CLOSED'
                AND SHIPPINGCOUNTRYCODE = 'US'
                AND INDICATION_FOR_USE__C = 'Heart Failure - Reduced Ejection Fraction'
        ) A
)
SELECT
    TS.ORIGINAL_OWNER AS OG_OWNER,
    TS.ST_DATE AS SPLIT_START,
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
    INNER JOIN tblTerr_Split TS ON OPPS.ACT_ID = TS.ACT_ID
    AND OPPS.CLOSEDATE BETWEEN TS.ST_DATE
    AND DATEADD(DAY, 270, TS.ST_DATE)