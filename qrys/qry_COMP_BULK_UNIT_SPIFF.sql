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
     Finally, if that's null, bring in the AM_FOR_CREDIT_EMAIL from qryRevRec. */
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
    R.ROLE,
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
    REVENUE_UNITS * 1750 AS SPIFF_PO
FROM
    qryRevRec O
    /* check tblAlign_Opp */
    LEFT JOIN tblAlign_Opp AO ON O.OPP_ID = AO.OPP_ID
    /* check account splits */
    LEFT JOIN tblActSplits splits ON O.ACT_ID = splits.ACT_ID
    AND CLOSE_YYYYMM BETWEEN splits.YYYYMM_ST
    AND splits.YYYYMM_END
    LEFT JOIN qryRoster R ON ISNULL(
        ISNULL(
            splits.REP_EMAIL,
            ISNULL(
                AO.EMAIL,
                O.SALES_CREDIT_REP_EMAIL
            )
        ),
        O.AM_FOR_CREDIT_EMAIL
    ) = R.REP_EMAIL
    AND O.CLOSE_YYYYMM BETWEEN R.ACTIVE_YYYYMM
    AND ISNULL(R.DOT_YYYYMM, '2099_12')
WHERE
    OPP_COUNTRY = 'US'
    AND INDICATION_FOR_USE__C = 'Heart Failure - Reduced Ejection Fraction'
    AND (
        CLOSE_YYYYQQ = '2024_Q4'
        OR CLOSE_YYYYMM = '2024_09'
    )
    AND CLOSE_YYYYMM <> FORMAT(GETDATE(), 'yyyy_MM')
    AND REVENUE_UNITS >= 3;