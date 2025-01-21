-- CREATE VIEW qryZipAlign AS
SELECT
    Z.*,
    R.TERRITORY AS TERR_NAME,
    R.REGION,
    R.REGION_ID,
    REP_EMAIL,
    LNAME_REP,
    FNAME_REP,
    NAME_REP
FROM
    tblZipAlign Z
    LEFT JOIN (
        SELECT
            *
        FROM
            qryRoster
        WHERE
            ROLE NOT IN ('FCE', 'MDR')
            AND [isLATEST?] = 1
            AND [STATUS] = 'ACTIVE'
    ) R ON Z.TERR_ID = R.TERRITORY_ID