/** ACCT ALIGNMENT START**/
SELECT
    A.REGION,
    A.REG_ID,
    B.EMAIL [SALES_CREDIT_FCE_EMAIL],
    A.SALES_CREDIT_REP_EMAIL,
    A.OPP_ID,
    A.OPP_NAME,
    A.ACT_ID,
    1 AS [isTarget?],
    b.PO_PER,
    b.[PO_%],
    IPG,
    ACCOUNT,
    A.PHYSICIAN,
    A.PHYSICIAN_ID,
    A.SHIPPINGSTATECODE,
    CLOSEDATE,
    CLOSE_YYYYMM,
    CLOSE_YYYYQQ,
    IMPLANTED_YYYYMM,
    IMPLANTED_YYYYQQ,
    IMPLANT_UNITS,
    QTY,
    0 AS [SALES_BASE],
    ISNULL(SALES, 0) [SALES_TGT],
    ASP,
    CASE
        WHEN C.EMAIL IS NOT NULL THEN 1
        ELSE 0
    END AS [Exclude?],
    'ACCT' AS [TYPE]
FROM
    (
        SELECT
            UPPER(A.REGION) [REGION],
            A.REG_ID,
            A.SALES_CREDIT_REP_EMAIL,
            A.OPP_ID,
            ACCOUNT_INDICATION__C [ACCOUNT],
            A.ACT_ID,
            A.PHYSICIAN,
            A.PHYSICIAN_ID,
            PATIENT_IPG_SERIAL_NUMBER__C [IPG],
            A.SHIPPINGSTATECODE,
            A.SHIPPINGCITY,
            INDICATION_FOR_USE__C,
            REASON_FOR_IMPLANT__C,
            CLOSEDATE,
            CLOSE_YYYYMM,
            NAME OPP_NAME,
            CLOSE_YYYYQQ,
            IMPLANTED_YYYYMM,
            IMPLANTED_YYYYQQ,
            IMPLANT_UNITS,
            TOTALOPPORTUNITYQUANTITY AS [QTY],
            SALES,
            [ASP]
        FROM
            qryOpps A
        WHERE
            IMPLANTED_YYYY = '2024'
            AND OPP_COUNTRY = 'US'
            AND RECORD_TYPE = 'Procedure - North America'
            AND INDICATION_FOR_USE__C = 'Heart Failure - Reduced Ejection Fraction'
            AND REASON_FOR_IMPLANT__C IN ('De novo', 'Replacement')
            AND STAGENAME IN ('Implant Completed', 'Revenue Recognized')
            AND IMPLANTED_YYYYMM <= (
                SELECT
                    YYYYMM
                FROM
                    qryCalendar
                WHERE
                    [DT] = CAST(DATEADD(mm, -1, GETDATE()) AS DATE)
            )
    ) AS A
    LEFT JOIN qryAlign_FCE B ON A.ACT_ID = B.[KEY]
    AND B.TYPE = 'ACCT'
    AND A.IMPLANTED_YYYYMM BETWEEN b.ACTIVE_YYYYMM
    AND B.DOT_YYYYMM
    LEFT JOIN tblOppEx C ON A.OPP_NAME = C.OPP_NAME
    AND b.EMAIL = C.EMAIL
WHERE
    B.EMAIL IS NOT NULL
    AND ISNULL(A.PHYSICIAN_ID, 0) NOT IN (
        SELECT
            B3.[KEY]
        FROM
            qryAlign_FCE B3
        WHERE
            B3.TYPE = 'DOC'
            AND B3.EMAIL = B.EMAIL
            AND a.IMPLANTED_YYYYMM >= B3.ACTIVE_YYYYMM
    )
    /** ACCT ALIGNMENT END**/
UNION
ALL
/** DOC ALIGNMENT START **/
SELECT
    UPPER(A.REGION) [REGION],
    A.REG_ID,
    B.EMAIL [SALES_CREDIT_FCE_EMAIL],
    A.SALES_CREDIT_REP_EMAIL,
    A.OPP_ID,
    A.OPP_NAME,
    A.ACT_ID,
    1 AS [isTarget?],
    b.PO_PER,
    b.[PO_%],
    IPG,
    ACCOUNT,
    A.PHYSICIAN,
    A.PHYSICIAN_ID,
    A.SHIPPINGSTATECODE,
    CLOSEDATE,
    CLOSE_YYYYMM,
    CLOSE_YYYYQQ,
    IMPLANTED_YYYYMM,
    IMPLANTED_YYYYQQ,
    IMPLANT_UNITS,
    QTY,
    0 AS [SALES_BASE],
    ISNULL(SALES, 0) [SALES_TGT],
    ASP,
    CASE
        WHEN C.EMAIL IS NOT NULL THEN 1
        ELSE 0
    END AS [Exclude?],
    'DOC' AS [TYPE]
FROM
    (
        SELECT
            A.REGION,
            A.REG_ID,
            A.SALES_CREDIT_REP_EMAIL,
            A.OPP_ID,
            ACCOUNT_INDICATION__C [ACCOUNT],
            A.ACT_ID,
            A.PHYSICIAN,
            A.PHYSICIAN_ID,
            PATIENT_IPG_SERIAL_NUMBER__C [IPG],
            A.SHIPPINGSTATECODE,
            A.SHIPPINGCITY,
            INDICATION_FOR_USE__C,
            REASON_FOR_IMPLANT__C,
            CLOSEDATE,
            CLOSE_YYYYMM,
            NAME OPP_NAME,
            CLOSE_YYYYQQ,
            IMPLANTED_YYYYMM,
            IMPLANTED_YYYYQQ,
            IMPLANT_UNITS,
            TOTALOPPORTUNITYQUANTITY AS [QTY],
            SALES,
            [ASP]
        FROM
            qryOpps A
        WHERE
            IMPLANTED_YYYY = '2024'
            AND OPP_COUNTRY = 'US'
            AND RECORD_TYPE = 'Procedure - North America'
            AND INDICATION_FOR_USE__C = 'Heart Failure - Reduced Ejection Fraction'
            AND REASON_FOR_IMPLANT__C IN ('De novo', 'Replacement')
            AND STAGENAME IN ('Implant Completed', 'Revenue Recognized')
            AND IMPLANTED_YYYYMM <= (
                SELECT
                    YYYYMM
                FROM
                    qryCalendar
                WHERE
                    [DT] = CAST(DATEADD(mm, -1, GETDATE()) AS DATE)
            )
    ) AS A
    LEFT JOIN qryAlign_FCE B ON A.PHYSICIAN_ID = B.[KEY]
    AND B.TYPE = 'DOC'
    AND A.IMPLANTED_YYYYMM BETWEEN b.ACTIVE_YYYYMM
    AND B.DOT_YYYYMM
    LEFT JOIN tblOppEx C ON A.OPP_NAME = C.OPP_NAME
    AND b.EMAIL = C.EMAIL
WHERE
    B.EMAIL IS NOT NULL
    /** DOC ALIGNMENT END **/
UNION
ALL
/** REGION ALIGNMENT START **/
SELECT
    REGION,
    REG_ID,
    B.EMAIL [SALES_CREDIT_FCE_EMAIL],
    A.SALES_CREDIT_REP_EMAIL,
    A.OPP_ID,
    A.OPP_NAME,
    A.ACT_ID,
    NULL AS [isTarget],
    NULL AS [PO_PER],
    NULL AS [PO_%],
    IPG,
    ACCOUNT,
    A.PHYSICIAN,
    A.PHYSICIAN_ID,
    A.SHIPPINGSTATECODE,
    A.CLOSEDATE,
    A.CLOSE_YYYYMM,
    A.CLOSE_YYYYQQ,
    IMPLANTED_YYYYMM,
    IMPLANTED_YYYYQQ,
    IMPLANT_UNITS,
    A.QTY,
    ISNULL(SALES, 0) AS [SALES_BASE],
    0 AS [SALES_TGT],
    A.ASP,
    CASE
        WHEN C.EMAIL IS NOT NULL THEN 1
        ELSE 0
    END AS [Exclude?],
    'REGION_HF' AS [TYPE]
FROM
    (
        SELECT
            A.REGION,
            A.REG_ID,
            A.SALES_CREDIT_REP_EMAIL,
            A.OPP_ID,
            ACCOUNT_INDICATION__C [ACCOUNT],
            A.ACT_ID,
            A.PHYSICIAN,
            A.PHYSICIAN_ID,
            PATIENT_IPG_SERIAL_NUMBER__C [IPG],
            A.SHIPPINGSTATECODE,
            A.SHIPPINGCITY,
            INDICATION_FOR_USE__C,
            REASON_FOR_IMPLANT__C,
            CLOSEDATE,
            CLOSE_YYYYMM,
            NAME OPP_NAME,
            CLOSE_YYYYQQ,
            IMPLANTED_YYYYMM,
            IMPLANTED_YYYYQQ,
            IMPLANT_UNITS,
            TOTALOPPORTUNITYQUANTITY AS [QTY],
            SALES,
            [ASP]
        FROM
            qryRevRec A
        WHERE
            CLOSE_YYYY = '2024'
            AND OPP_COUNTRY = 'US'
            AND SALES <> 0
            AND INDICATION_FOR_USE__C = 'Heart Failure - Reduced Ejection Fraction'
            AND REASON_FOR_IMPLANT__C IN ('De novo', 'Replacement')
            AND CLOSE_YYYYMM <= (
                SELECT
                    YYYYMM
                FROM
                    qryCalendar
                WHERE
                    [DT] = CAST(DATEADD(mm, -1, GETDATE()) AS DATE)
            )
    ) AS A
    LEFT JOIN qryAlign_FCE B ON A.REG_ID = B.[KEY]
    AND B.TYPE = 'REGION'
    AND A.CLOSE_YYYYMM BETWEEN b.ACTIVE_YYYYMM
    AND B.DOT_YYYYMM
    LEFT JOIN tblOppEx C ON A.OPP_NAME = C.OPP_NAME
    AND b.EMAIL = C.EMAIL
WHERE
    B.EMAIL IS NOT NULL
    /** REGIONAL HF END  **/
UNION
ALL
/** TERRITORY ALIGNMENT START **/
SELECT
    REGION,
    REG_ID,
    B.EMAIL [SALES_CREDIT_FCE_EMAIL],
    A.SALES_CREDIT_REP_EMAIL,
    A.OPP_ID,
    A.OPP_NAME,
    A.ACT_ID,
    NULL AS [isTarget],
    NULL AS [PO_PER],
    NULL AS [PO_%],
    IPG,
    ACCOUNT,
    A.PHYSICIAN,
    A.PHYSICIAN_ID,
    A.SHIPPINGSTATECODE,
    A.CLOSEDATE,
    A.CLOSE_YYYYMM,
    A.CLOSE_YYYYQQ,
    IMPLANTED_YYYYMM,
    IMPLANTED_YYYYQQ,
    IMPLANT_UNITS,
    A.QTY,
    ISNULL(SALES, 0) AS [SALES_BASE],
    0 AS [SALES_TGT],
    A.ASP,
    CASE
        WHEN C.EMAIL IS NOT NULL THEN 1
        ELSE 0
    END AS [Exclude?],
    'TERRITORY_HF' AS [TYPE]
FROM
    (
        SELECT
            A.REGION,
            A.REG_ID,
            A.SALES_CREDIT_REP_EMAIL,
            r.TERRITORY_ID,
            A.OPP_ID,
            ACCOUNT_INDICATION__C [ACCOUNT],
            A.ACT_ID,
            A.PHYSICIAN,
            A.PHYSICIAN_ID,
            PATIENT_IPG_SERIAL_NUMBER__C [IPG],
            A.SHIPPINGSTATECODE,
            A.SHIPPINGCITY,
            INDICATION_FOR_USE__C,
            REASON_FOR_IMPLANT__C,
            CLOSEDATE,
            CLOSE_YYYYMM,
            NAME OPP_NAME,
            CLOSE_YYYYQQ,
            IMPLANTED_YYYYMM,
            IMPLANTED_YYYYQQ,
            IMPLANT_UNITS,
            TOTALOPPORTUNITYQUANTITY AS [QTY],
            SALES,
            [ASP]
        FROM
            qryRevRec A
            LEFT JOIN qryRoster R ON a.SALES_CREDIT_REP_EMAIL = r.REP_EMAIL
            AND R.[isLATEST?] = 1
        WHERE
            CLOSE_YYYY = '2024'
            AND OPP_COUNTRY = 'US'
            AND SALES <> 0
            AND INDICATION_FOR_USE__C = 'Heart Failure - Reduced Ejection Fraction'
            AND REASON_FOR_IMPLANT__C IN ('De novo', 'Replacement')
            AND CLOSE_YYYYMM <= (
                SELECT
                    YYYYMM
                FROM
                    qryCalendar
                WHERE
                    [DT] = CAST(DATEADD(mm, -1, GETDATE()) AS DATE)
            )
    ) AS A
    LEFT JOIN qryAlign_FCE B ON A.TERRITORY_ID = B.[KEY]
    AND B.TYPE = 'TERR'
    AND A.CLOSE_YYYYMM BETWEEN b.ACTIVE_YYYYMM
    AND B.DOT_YYYYMM
    LEFT JOIN tblOppEx C ON A.OPP_NAME = C.OPP_NAME
    AND b.EMAIL = C.EMAIL
WHERE
    B.EMAIL IS NOT NULL
    /*territory align end*/