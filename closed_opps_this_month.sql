SELECT
    CLOSE_YYYYMM,
    IMPLANTED_YYYYMM,
    o.ACT_ID AS act,
    ACCOUNT_INDICATION__C,
    OPP_ID,
    o.[NAME] AS OPP_NAME,
    OPP_OWNER_EMAIL,
    ISNULL(splits.REP_EMAIL, AM_FOR_CREDIT_EMAIL) AS AM_FOR_CREDIT_EMAIL,
    ACT_OWNER_NAME,
    ACT_OWNER_EMAIL,
    CASE
        WHEN SPLIT IS NOT NULL THEN SPLIT * IMPLANT_UNITS
        ELSE IMPLANT_UNITS
    END AS IMPLANT_UNITS,
    CASE
        WHEN SPLIT IS NOT NULL THEN SPLIT * REVENUE_UNITS
        ELSE REVENUE_UNITS
    END AS REVENUE_UNITS,
    CASE
        WHEN SPLIT IS NOT NULL THEN SPLIT * SALES
        ELSE SALES
    END AS SALES,
    ISIMPL,
    CASE
        WHEN splits.SPLIT IS NOT NULL THEN 1
        ELSE 0
    END AS [isSPLIT?],
    REASON_FOR_IMPLANT__C,
    PHYSICIAN,
    [PHYSICIAN_ID],
    T.EMAIL AS FCE_PO_EMAIL,
    T.PO_PER,
    T.[PO_%]
FROM
    qryOpps O
    LEFT JOIN tblFCE_TGT_PO T ON CASE
        WHEN T.[TYPE] = 'ACCT' THEN O.ACT_ID
        WHEN T.[TYPE] = 'DOC' THEN O.PHYSICIAN_ID
    END = T.OBJ_ID
    AND O.IMPLANTED_YYYYMM BETWEEN T.YYYYMM_START
    AND T.YYYYMM_END
    AND O.ISIMPL = 1
    AND REASON_FOR_IMPLANT__C = 'De novo'
    LEFT JOIN tblActSplits splits ON splits.ACT_ID = O.ACT_ID
    AND O.CLOSE_YYYYMM BETWEEN splits.YYYYMM_ST
    AND splits.YYYYMM_END
WHERE
    OPP_STATUS = 'CLOSED'
    AND SHIPPINGCOUNTRYCODE = 'US'
    AND (
        CLOSE_YYYYMM = FORMAT(GETDATE(), 'yyyy_MM')
        OR IMPLANTED_YYYYMM = FORMAT(GETDATE(), 'yyyy_MM')
    )