-- CREATE VIEW qryReport_Ladder AS
SELECT
    REP_EMAIL,
    FNAME_REP,
    LNAME_REP,
    NAME_REP,
    DOH,
    DOT,
    [STATUS],
    ROLE,
    TERRITORY_ID,
    TERR_NM,
    REGION_ID,
    REGION_NM,
    qryRoster.Tier,
    qryRoster.[isTM?],
    tblRates_AM.TM_EID AS TM_EMAIL,
    CASE
        WHEN RM_EMAIL IN (
            'jgarner@cvrx.com',
            'kdenton@cvrx.com',
            'jhorky@cvrx.com',
            'ccastillo@cvrx.com'
        ) THEN RM_EMAIL
        ELSE NULL
    END AS RM_EMAIL,
    CASE
        WHEN RM_EMAIL NOT IN (
            'jgarner@cvrx.com',
            'kdenton@cvrx.com',
            'jhorky@cvrx.com',
            'ccastillo@cvrx.com'
        ) THEN RM_EMAIL
        WHEN RM_EMAIL = 'ccastillo@cvrx.com' THEN 'mbrown@cvrx.com'
        WHEN RM_EMAIL = 'jgarner@cvrx.com' THEN 'jheimsoth@cvrx.com'
        WHEN RM_EMAIL = 'kdenton@cvrx.com' THEN 'pknight@cvrx.com'
    END AS AD_EMAIL
FROM
    qryRoster
    LEFT JOIN tblRates_AM ON qryRoster.REP_EMAIL = tblRates_AM.EID
WHERE
    [isLATEST?] = 1
UNION
SELECT
    EMP_EMAIL,
    FNAME,
    NULL,
    NAME,
    NULL,
    NULL,
    UPPER(STATUS) AS STATUS,
    CASE
        WHEN EMP_EMAIL IN (
            'jheimsoth@cvrx.com',
            'mbrown@cvrx.com',
            'pknight@cvrx.com'
        ) THEN 'AD_A'
        WHEN EMP_EMAIL IN ('kryan@cvrx.com', 'jtsokanos@cvrx.com') THEN 'AD_B'
        WHEN EMP_EMAIL IN (
            'jgarner@cvrx.com',
            'kdenton@cvrx.com',
            'jhorky@cvrx.com',
            'ccastillo@cvrx.com'
        ) THEN 'RM'
    END AS ROLE,
    NULL,
    NULL,
    TERRITORY_ID,
    REGION,
    NULL,
    NULL,
    NULL,
    NULL,
    CASE
        WHEN EMP_EMAIL = 'ccastillo@cvrx.com' THEN 'mbrown@cvrx.com'
        WHEN EMP_EMAIL = 'jgarner@cvrx.com' THEN 'jheimsoth@cvrx.com'
        WHEN EMP_EMAIL = 'kdenton@cvrx.com' THEN 'pknight@cvrx.com'
    END
FROM
    qryRoster_RM;