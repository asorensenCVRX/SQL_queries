-- CREATE VIEW qryReport_Ladder AS
SELECT
    REP_EMAIL,
    FNAME_REP,
    LNAME_REP,
    NAME_REP,
    CAST(DOH AS DATE) AS DOH,
    DOT,
    [STATUS],
    ROLE,
    TERRITORY_ID,
    TERR_NM,
    REGION_ID,
    LEFT(REGION_NM, CHARINDEX('(', REGION_NM) -2) AS REGION_NM,
    REGION_NM AS REGION_NM_FULL,
    qryRoster.Tier,
    RM_EMAIL
FROM
    qryRoster
    LEFT JOIN tblRates_AM ON qryRoster.REP_EMAIL = tblRates_AM.EID
WHERE
    [isLATEST?] = 1
    AND REP_EMAIL NOT IN (
        SELECT
            EMP_EMAIL
        FROM
            qryRoster_RM
    )
    AND ROLE <> 'MDR'
UNION
SELECT
    EMP_EMAIL,
    FNAME,
    SUBSTRING(
        RM.NAME,
        CHARINDEX(' ', RM.NAME) + 1,
        LEN(RM.NAME) - CHARINDEX(' ', RM.NAME)
    ) AS LNAME_REP,
    RM.NAME,
    CAST(E.DOH AS DATE) AS DOH,
    CAST(E.DOT AS DATE) AS DOT,
    UPPER(STATUS) AS STATUS,
    ROLE,
    NULL,
    NULL,
    TERRITORY_ID,
    REGION,
    REGION + ' (' + UPPER(
        SUBSTRING(
            RM.NAME,
            CHARINDEX(' ', RM.NAME) + 1,
            LEN(RM.NAME) - CHARINDEX(' ', RM.NAME)
        )
    ) + ')',
    NULL,
    NULL
FROM
    qryRoster_RM RM
    LEFT JOIN tblEmployee E ON E.[WORK E-MAIL] = RM.EMP_EMAIL