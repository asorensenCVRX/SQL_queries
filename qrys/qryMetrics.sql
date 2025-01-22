-- CREATE VIEW qryMetrics AS 
SELECT
    '7. HF Opportunities Created' [Metric],
    dbo.ConvertToTitleCase(ACT_OWNER_REGION) [Region],
    OPP_OWNER_NAME,
    ACT_OWNER_NAME,
    ISNULL(cast(r.Tier AS varchar(15)), 'Other Role') ACT_OWNER_TIER,
    NAME [OPP_NAME],
    STAGENAME [STAGE],
    ACCOUNT_INDICATION__C [ACCOUNT],
    1 AS Counter,
    CASE
        WHEN r.tier = 1 THEN 1
        ELSE 0
    END AS T1,
    CASE
        WHEN r.tier = 2 THEN 1
        ELSE 0
    END AS T2,
    CASE
        WHEN r.tier = 3 THEN 1
        ELSE 0
    END AS T3,
    CASE
        WHEN r.tier = 4 THEN 1
        ELSE 0
    END AS T4,
    CREATEDDATE [DATE],
    CREATEDDATE_WK [WEEK],
    c.[12_24_36_WEEKS] [WEEK_12_24_36],
    c.[WEEK_#],
    CREATED_YYYYMM [YYYYMM],
    CREATED_YYYYQQ [YYYYQQ],
    CREATED_YYYY [YYYY]
FROM
    tmpOpps T
    LEFT JOIN qryRoster R ON t.ACT_OWNER_EMAIL = r.REP_EMAIL
    AND r.[isLATEST?] = 1
    LEFT JOIN qrycalendar C ON T.CREATEDDATE = c.DT
WHERE
    RECORD_TYPE = 'Procedure - North America'
UNION
ALL
SELECT
    '6. Initial Consults' [Metric],
    dbo.ConvertToTitleCase(ACT_OWNER_REGION) [Region],
    OPP_OWNER_NAME,
    ACT_OWNER_NAME,
    ISNULL(cast(r.Tier AS varchar(15)), 'Other Role') ACT_OWNER_TIER,
    NAME [OPP_NAME],
    STAGENAME [STAGE],
    ACCOUNT_INDICATION__C [ACCOUNT],
    1 AS Counter,
    CASE
        WHEN r.tier = 1 THEN 1
        ELSE 0
    END AS T1,
    CASE
        WHEN r.tier = 2 THEN 1
        ELSE 0
    END AS T2,
    CASE
        WHEN r.tier = 3 THEN 1
        ELSE 0
    END AS T3,
    CASE
        WHEN r.tier = 4 THEN 1
        ELSE 0
    END AS T4,
    INITIAL_CONSULT_DT [DATE],
    INITIAL_CONSULT_WK [WEEK],
    c.[12_24_36_WEEKS] [WEEK_12_24_36],
    c.[WEEK_#],
    INITIAL_CONSULT_YYYYMM [YYYYMM],
    INITIAL_CONSULT_YYYYQQ [YYYYQQ],
    INITIAL_CONSULT_YR [YYYY]
FROM
    tmpOpps T
    LEFT JOIN qryRoster R ON t.ACT_OWNER_EMAIL = r.REP_EMAIL
    AND r.[isLATEST?] = 1
    LEFT JOIN qrycalendar C ON T.INITIAL_CONSULT_DT = c.DT
WHERE
    INITIAL_CONSULT_DT IS NOT NULL
    AND RECORD_TYPE = 'Procedure - North America'
UNION
ALL
SELECT
    '5. Prior Auth Submits' [Metric],
    dbo.ConvertToTitleCase(ACT_OWNER_REGION) [Region],
    OPP_OWNER_NAME,
    ACT_OWNER_NAME,
    ISNULL(cast(r.Tier AS varchar(15)), 'Other Role') ACT_OWNER_TIER,
    NAME [OPP_NAME],
    STAGENAME [STAGE],
    ACCOUNT_INDICATION__C [ACCOUNT],
    1 AS Counter,
    CASE
        WHEN r.tier = 1 THEN 1
        ELSE 0
    END AS T1,
    CASE
        WHEN r.tier = 2 THEN 1
        ELSE 0
    END AS T2,
    CASE
        WHEN r.tier = 3 THEN 1
        ELSE 0
    END AS T3,
    CASE
        WHEN r.tier = 4 THEN 1
        ELSE 0
    END AS T4,
    PRIOR_AUTH_DT [DATE],
    PRIOR_AUTH_IN_PROCESS_WK [WEEK],
    t.PRIOR_AUTH_IN_PROCESS_12_24_36 [WEEK_12_24_36],
    [WEEK_#],
    PRIOR_AUTH_IN_PROCESS_YYYYMM [YYYYMM],
    PRIOR_AUTH_IN_PROCESS_YYYYQQ [YYYYQQ],
    PRIOR_AUTH_IN_PROCESS_YR [YYYY]
FROM
    tmpOpps T
    LEFT JOIN qryRoster R ON t.ACT_OWNER_EMAIL = r.REP_EMAIL
    AND r.[isLATEST?] = 1
    LEFT JOIN qrycalendar C ON T.PRIOR_AUTH_DT = c.DT
WHERE
    PRIOR_AUTH_DT IS NOT NULL
    AND RECORD_TYPE = 'Procedure - North America'
UNION
ALL
SELECT
    '4. Scheduled Surgical Consults' [Metric],
    dbo.ConvertToTitleCase(ACT_OWNER_REGION) [Region],
    OPP_OWNER_NAME,
    ACT_OWNER_NAME,
    ISNULL(cast(r.Tier AS varchar(15)), 'Other Role') ACT_OWNER_TIER,
    NAME [OPP_NAME],
    STAGENAME [STAGE],
    ACCOUNT_INDICATION__C [ACCOUNT],
    1 AS Counter,
    CASE
        WHEN r.tier = 1 THEN 1
        ELSE 0
    END AS T1,
    CASE
        WHEN r.tier = 2 THEN 1
        ELSE 0
    END AS T2,
    CASE
        WHEN r.tier = 3 THEN 1
        ELSE 0
    END AS T3,
    CASE
        WHEN r.tier = 4 THEN 1
        ELSE 0
    END AS T4,
    SURGICAL_CONSULT_DT [DATE],
    SURGICAL_CONSULT_WK [WEEK],
    c.[12_24_36_WEEKS] [WEEK_12_24_36],
    [WEEK_#],
    SURGICAL_CONSULT_YYYYMM [YYYYMM],
    SURGICAL_CONSULT_YYYYQQ [YYYYQQ],
    SURGICAL_CONSULT_YR [YYYY]
FROM
    tmpOpps T
    LEFT JOIN qryRoster R ON t.ACT_OWNER_EMAIL = r.REP_EMAIL
    AND r.[isLATEST?] = 1
    LEFT JOIN qrycalendar C ON T.SURGICAL_CONSULT_DT = c.DT
WHERE
    SURGICAL_CONSULT_DT IS NOT NULL
    AND RECORD_TYPE = 'Procedure - North America'
UNION
ALL
SELECT
    '3. Scheduled Implants' [Metric],
    dbo.ConvertToTitleCase(ACT_OWNER_REGION) [Region],
    OPP_OWNER_NAME,
    ACT_OWNER_NAME,
    ISNULL(cast(r.Tier AS varchar(15)), 'Other Role') ACT_OWNER_TIER,
    NAME [OPP_NAME],
    STAGENAME [STAGE],
    ACCOUNT_INDICATION__C [ACCOUNT],
    1 AS Counter,
    CASE
        WHEN r.tier = 1 THEN 1
        ELSE 0
    END AS T1,
    CASE
        WHEN r.tier = 2 THEN 1
        ELSE 0
    END AS T2,
    CASE
        WHEN r.tier = 3 THEN 1
        ELSE 0
    END AS T3,
    CASE
        WHEN r.tier = 4 THEN 1
        ELSE 0
    END AS T4,
    IMPLANT_SCHEDULED_DT [DATE],
    IMPLANT_SCHEDULED_WK [WEEK],
    IMPLANT_SCHEDULED_12_24_36_WEEKS [WEEK_12_24_36],
    [IMPLANT_SCHEDULED_WK_#],
    IMPLANT_SCHEDULED_YYYYMM [YYYYMM],
    IMPLANT_SCHEDULED_YYYYQQ [YYYYQQ],
    IMPLANT_SCHEDULED_YR [YYYY]
FROM
    tmpOpps T
    LEFT JOIN qryRoster R ON t.ACT_OWNER_EMAIL = r.REP_EMAIL
    AND r.[isLATEST?] = 1
    LEFT JOIN qrycalendar C ON T.IMPLANT_SCHEDULED_DT = c.DT
WHERE
    IMPLANT_SCHEDULED_DT IS NOT NULL
    AND RECORD_TYPE = 'Procedure - North America'
UNION
ALL
SELECT
    '1. Implants' [Metric],
    dbo.ConvertToTitleCase(ACT_OWNER_REGION) [Region],
    OPP_OWNER_NAME,
    ACT_OWNER_NAME,
    ISNULL(cast(r.Tier AS varchar(15)), 'Other Role') ACT_OWNER_TIER,
    NAME [OPP_NAME],
    STAGENAME [STAGE],
    ACCOUNT_INDICATION__C [ACCOUNT],
    1 AS Counter,
    CASE
        WHEN r.tier = 1 THEN 1
        ELSE 0
    END AS T1,
    CASE
        WHEN r.tier = 2 THEN 1
        ELSE 0
    END AS T2,
    CASE
        WHEN r.tier = 3 THEN 1
        ELSE 0
    END AS T3,
    CASE
        WHEN r.tier = 4 THEN 1
        ELSE 0
    END AS T4,
    t.IMPLANTED_DT [DATE],
    c.[WK_LBL] [WEEK],
    c.[12_24_36_WEEKS] [WEEK_12_24_36],
    c.[WEEK_#],
    IMPLANTED_YYYYMM [YYYYMM],
    IMPLANTED_YYYYQQ [YYYYQQ],
    c.[YEAR] [YYYY]
FROM
    tmpOpps T
    LEFT JOIN qryRoster R ON t.ACT_OWNER_EMAIL = r.REP_EMAIL
    AND r.[isLATEST?] = 1
    LEFT JOIN qrycalendar C ON T.IMPLANTED_DT = c.DT
WHERE
    RECORD_TYPE = 'Procedure - North America'
    AND ISIMPL = 1
    AND STAGENAME IN ('Revenue Recognized', 'Implant Completed')
UNION
ALL
SELECT
    '2. Revenue Units' [Metric],
    dbo.ConvertToTitleCase(ACT_OWNER_REGION) [Region],
    OPP_OWNER_NAME,
    ACT_OWNER_NAME,
    ISNULL(cast(r.Tier AS varchar(15)), 'Other Role') ACT_OWNER_TIER,
    NAME [OPP_NAME],
    STAGENAME [STAGE],
    ACCOUNT_INDICATION__C [ACCOUNT],
    REVENUE_UNITS AS Counter,
    CASE
        WHEN r.tier = 1 THEN 1
        ELSE 0
    END AS T1,
    CASE
        WHEN r.tier = 2 THEN 1
        ELSE 0
    END AS T2,
    CASE
        WHEN r.tier = 3 THEN 1
        ELSE 0
    END AS T3,
    CASE
        WHEN r.tier = 4 THEN 1
        ELSE 0
    END AS T4,
    t.[CLOSEDATE] [DATE],
    c.[WK_LBL] [WEEK],
    c.[12_24_36_WEEKS] [WEEK_12_24_36],
    c.[WEEK_#],
    CLOSE_YYYYMM [YYYYMM],
    CLOSE_YYYYQQ [YYYYQQ],
    c.[YEAR] [YYYY]
FROM
    tmpOpps T
    LEFT JOIN qryRoster R ON t.ACT_OWNER_EMAIL = r.REP_EMAIL
    AND r.[isLATEST?] = 1
    LEFT JOIN qrycalendar C ON T.CLOSEDATE = c.DT
WHERE
    STAGENAME IN ('Revenue Recognized')
    AND OPP_COUNTRY = 'US'