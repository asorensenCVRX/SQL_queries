SELECT
    *,
    [August implants] + [September implants] + [October implants] + [November implants] + [December implants] AS [implants after 8/1]
FROM
    (
        SELECT
            R.REP_EMAIL,
            SUM(
                CASE
                    WHEN IMPLANTED_YYYYMM BETWEEN '2024_01'
                    AND '2024_07' THEN IMPLANT_UNITS
                    ELSE 0
                END
            ) AS [implants prior to 8/1],
            SUM(
                CASE
                    WHEN IMPLANTED_YYYYMM = '2024_08' THEN IMPLANT_UNITS
                    ELSE 0
                END
            ) AS [August implants],
            SUM(
                CASE
                    WHEN IMPLANTED_YYYYMM = '2024_09' THEN IMPLANT_UNITS
                    ELSE 0
                END
            ) AS [September implants],
            SUM(
                CASE
                    WHEN IMPLANTED_YYYYMM = '2024_10' THEN IMPLANT_UNITS
                    ELSE 0
                END
            ) AS [October implants],
            SUM(
                CASE
                    WHEN IMPLANTED_YYYYMM = '2024_11' THEN IMPLANT_UNITS
                    ELSE 0
                END
            ) AS [November implants],
            SUM(
                CASE
                    WHEN IMPLANTED_YYYYMM = '2024_12' THEN IMPLANT_UNITS
                    ELSE 0
                END
            ) AS [December implants]
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
                     If that's null, bring in the sales_credit_rep_email from qryOpps */
                    isnull(
                        ISNULL(
                            splits.REP_EMAIL,
                            ISNULL(
                                AO.EMAIL,
                                O.SALES_CREDIT_REP_EMAIL
                            )
                        ),
                        O.OPP_OWNER_EMAIL
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
                WHERE
                    OPP_STATUS = 'CLOSED'
                    AND SHIPPINGCOUNTRYCODE = 'US'
                    AND INDICATION_FOR_USE__C = 'Heart Failure - Reduced Ejection Fraction'
                    AND ISIMPL = 1
                    AND REASON_FOR_IMPLANT__C = 'De novo'
            ) opps
            RIGHT JOIN (
                SELECT
                    DISTINCT REP_EMAIL AS REP_EMAIL
                FROM
                    qryRoster
                WHERE
                    REP_EMAIL IN (
                        'bfagan@cvrx.com',
                        'ashapiro@cvrx.com',
                        'cmaxson@cvrx.com',
                        'dabbring@cvrx.com',
                        'jelinburg@cvrx.com',
                        'jhall@cvrx.com',
                        'jlowery@cvrx.com',
                        'jsmith@cvrx.com',
                        'jtalbert@cvrx.com',
                        'pdickerson@cvrx.com',
                        'sfuller@cvrx.com',
                        'sharrienger@cvrx.com',
                        'tbarker@cvrx.com',
                        'tkirk@cvrx.com',
                        'wsteinhoff@cvrx.com',
                        'dwalusis@cvrx.com',
                        'bkelly@cvrx.com',
                        'glink@cvrx.com',
                        'rdegeus@cvrx.com',
                        'scroxdale@cvrx.com',
                        'tvaccaro@cvrx.com',
                        'jviduna@cvrx.com',
                        'dking@cvrx.com',
                        'dabesamis@cvrx.com'
                    )
            ) R ON R.REP_EMAIL = opps.SALES_CREDIT_REP_EMAIL
        GROUP BY
            REP_EMAIL
    ) AS A