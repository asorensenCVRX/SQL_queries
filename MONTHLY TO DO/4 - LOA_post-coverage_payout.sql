WITH OPPS AS (
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
)
/******/
-- INSERT INTO
--     tblSalesSplits
/******/
SELECT
    OPPS.OPP_ID,
    A.REP_EMAIL AS SALES_CREDIT_REP_EMAIL,
    'REP' AS ROLE,
    0.5 AS SPLIT,
    NULL AS AMT,
    NULL AS ASP,
    NULL AS YYYYMM,
    'POST-LOA PAYOUT' AS NOTES
FROM
    OPPS
    INNER JOIN tblActSplits A ON OPPS.ACT_ID = A.ACT_ID
    AND [LOA_Coverage?] = 1
    AND OPPS.CLOSEDATE BETWEEN LOA_END
    AND DATEADD(MONTH, 3, LOA_END)
    AND REVENUE_UNITS >= 1
WHERE
    NOT EXISTS (
        SELECT
            1
        FROM
            tblSalesSplits
        WHERE
            tblSalesSplits.OPP_ID = OPPS.OPP_ID
            AND tblSalesSplits.SALES_CREDIT_REP_EMAIL = A.REP_EMAIL
    )
    AND OPPS.CLOSE_YYYYMM < FORMAT(GETDATE(), 'yyyy_MM')
UNION
ALL
SELECT
    OPPS.OPP_ID,
    OPPS.SALES_CREDIT_REP_EMAIL,
    'REP' AS ROLE,
    1 AS SPLIT,
    NULL AS AMT,
    NULL AS ASP,
    NULL AS YYYYMM,
    'FULL CREDIT POST-LOA' AS NOTES
FROM
    OPPS
    INNER JOIN tblActSplits A ON OPPS.ACT_ID = A.ACT_ID
    AND [LOA_Coverage?] = 1
    AND OPPS.CLOSEDATE BETWEEN LOA_END
    AND DATEADD(MONTH, 3, LOA_END)
    AND REVENUE_UNITS >= 1
WHERE
    NOT EXISTS (
        SELECT
            1
        FROM
            tblSalesSplits
        WHERE
            tblSalesSplits.OPP_ID = OPPS.OPP_ID
            AND tblSalesSplits.SALES_CREDIT_REP_EMAIL = A.REP_EMAIL
    )
    AND OPPS.CLOSE_YYYYMM < FORMAT(GETDATE(), 'yyyy_MM')