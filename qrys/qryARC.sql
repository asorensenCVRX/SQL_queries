-- CREATE VIEW qryARC AS
SELECT
    M.PHYSICIAN_ID,
    M.PHYSICIAN,
    M.YYYYMM,
    M.YYYYQQ,
    M.R12,
    M.R6,
    M.MONTH_START_DATE,
    M.COUNTER,
    -- ISNULL(R.NAME_REP, RR.NAME) AS [NAME],
    M.ACT_OWNER_EMAIL,
    -- ISNULL(R.REGION, RR.REGION) AS REGION,
    ISNULL(X.IMPLANT_UNITS, 0) AS IMPLANT_UNITS,
    ISNULL(z.[#_of_SC], 0) AS [#_of_SC],
    CASE
        WHEN SUM(ISNULL(X.IMPLANT_UNITS, 0)) OVER (PARTITION BY M.PHYSICIAN_ID) < 1 THEN 0
        ELSE 1
    END AS [HasImplanted?],
    M.ACCT,
    M.ACT_ID,
    CASE
        WHEN RIGHT(YYYYMM, 2) IN ('03', '06', '09', '12') THEN 1
        ELSE 0
    END AS [isQTRend?]
FROM
    (
        SELECT
            DISTINCT T.ACCT,
            T.ACT_ID,
            T.ACT_OWNER_EMAIL,
            T.PHYSICIAN_ID,
            T.PHYSICIAN,
            V.YYYYMM,
            V.YYYYQQ,
            V.R12,
            V.R6,
            V.MONTH_START_DATE,
            1 AS COUNTER
        FROM
            (
                /*implanted */
                SELECT
                    DISTINCT A.ACCOUNT_INDICATION__C AS ACCT,
                    A.ACT_ID,
                    A.ACT_OWNER_EMAIL,
                    A.PHYSICIAN_ID,
                    A.PHYSICIAN,
                    A.IMPLANTED_YYYYMM,
                    C.MONTH_START_DATE,
                    DATEADD(mm, 12, C.MONTH_START_DATE) AS [END]
                FROM
                    dbo.tmpOpps AS A
                    LEFT OUTER JOIN dbo.qryCalendar AS C ON A.IMPLANTED_DT = C.DT
                WHERE
                    A.OPP_COUNTRY = 'US'
                    AND A.REASON_FOR_IMPLANT__C = 'De Novo'
                    AND A.INDICATION_FOR_USE__C = 'Heart Failure - Reduced Ejection Fraction'
                    AND A.RECORD_TYPE = 'Procedure - North America'
                    AND A.STAGENAME IN ('Implant Completed', 'Revenue Recognized')
                    AND A.ISIMPL = 1
                    AND A.PHYSICIAN_ID IS NOT NULL
                GROUP BY
                    A.ACCOUNT_INDICATION__C,
                    A.ACT_ID,
                    A.ACT_OWNER_EMAIL,
                    A.PHYSICIAN_ID,
                    A.PHYSICIAN,
                    C.MONTH_START_DATE,
                    A.IMPLANTED_YYYYMM
                UNION
                /*SC And Beyond*/
                SELECT
                    DISTINCT ACCOUNT_INDICATION__C AS ACCT,
                    A.ACT_ID,
                    A.ACT_OWNER_EMAIL,
                    A.PHYSICIAN_ID,
                    A.PHYSICIAN,
                    A.CREATED_YYYYMM,
                    C.MONTH_START_DATE,
                    DATEADD(mm, 12, C.MONTH_START_DATE) AS [END]
                FROM
                    dbo.tmpOpps AS A
                    LEFT OUTER JOIN dbo.qryCalendar AS C ON A.CREATEDDATE = C.DT
                WHERE
                    A.OPP_COUNTRY = 'US'
                    AND A.REASON_FOR_IMPLANT__C = 'De Novo'
                    AND A.INDICATION_FOR_USE__C = 'Heart Failure - Reduced Ejection Fraction'
                    AND A.RECORD_TYPE = 'Procedure - North America'
                    AND A.[STAGENAME] IN (
                        'Implant Scheduled',
                        'Scheduled, Awaiting PA',
                        'Prior Authorization Completed',
                        'Prior Authorization Denied',
                        'Prior Authorization in Process',
                        'Scheduled for Surgical consult',
                        'Surgical Date Pending'
                    )
                    AND A.PHYSICIAN_ID IS NOT NULL
                GROUP BY
                    A.ACCOUNT_INDICATION__C,
                    A.ACT_ID,
                    A.ACT_OWNER_EMAIL,
                    A.PHYSICIAN_ID,
                    A.PHYSICIAN,
                    C.MONTH_START_DATE,
                    A.CREATED_YYYYMM
            ) AS T
            LEFT OUTER JOIN (
                SELECT
                    DISTINCT MONTH_START_DATE,
                    YYYYMM,
                    YYYYQQ,
                    R12,
                    R6
                FROM
                    dbo.qryCalendar
            ) AS V ON V.MONTH_START_DATE >= T.MONTH_START_DATE
            AND V.MONTH_START_DATE <= T.[END]
            AND V.MONTH_START_DATE < dateadd(yy, 1, getdate())
    ) AS M
    LEFT OUTER JOIN qryRoster AS R ON R.REP_EMAIL = M.ACT_OWNER_EMAIL
    AND R.[isLATEST?] = 1
    LEFT OUTER JOIN dbo.qryRoster_RM AS RR ON RR.EMP_EMAIL = M.ACT_OWNER_EMAIL
    LEFT OUTER JOIN (
        SELECT
            PHYSICIAN_ID,
            IMPLANTED_YYYYMM,
            SUM(IMPLANT_UNITS) AS IMPLANT_UNITS
        FROM
            dbo.tmpOpps AS A
        WHERE
            OPP_COUNTRY = 'US'
            AND REASON_FOR_IMPLANT__C = 'De Novo'
            AND INDICATION_FOR_USE__C = 'Heart Failure - Reduced Ejection Fraction'
            AND RECORD_TYPE = 'Procedure - North America'
            AND STAGENAME IN ('Implant Completed', 'Revenue Recognized')
            AND ISIMPL = 1
        GROUP BY
            PHYSICIAN_ID,
            IMPLANTED_YYYYMM
    ) AS X ON M.YYYYMM = X.IMPLANTED_YYYYMM
    AND M.PHYSICIAN_ID = X.PHYSICIAN_ID
    LEFT JOIN (
        SELECT
            A.PHYSICIAN_ID,
            A.CREATED_YYYYMM,
            COUNT(*) AS [#_of_SC]
        FROM
            dbo.tmpOpps AS A
            LEFT OUTER JOIN dbo.qryCalendar AS C ON A.CREATEDDATE = C.DT
        WHERE
            A.OPP_COUNTRY = 'US'
            AND A.REASON_FOR_IMPLANT__C = 'De Novo'
            AND A.INDICATION_FOR_USE__C = 'Heart Failure - Reduced Ejection Fraction'
            AND A.RECORD_TYPE = 'Procedure - North America'
            AND A.[STAGENAME] IN (
                'Implant Scheduled',
                'Scheduled, Awaiting PA',
                'Interested, being evaluated',
                'Prior Authorization Completed',
                'Prior Authorization Denied',
                'Prior Authorization in Process',
                'Scheduled for Surgical consult',
                'Surgical Date Pending'
            )
            AND A.PHYSICIAN_ID IS NOT NULL
        GROUP BY
            A.PHYSICIAN_ID,
            A.CREATED_YYYYMM
    ) AS Z ON m.YYYYMM = z.CREATED_YYYYMM
    AND m.PHYSICIAN_ID = z.PHYSICIAN_ID