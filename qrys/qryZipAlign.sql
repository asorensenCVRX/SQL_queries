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
            *,
            ROW_NUMBER() OVER (
                PARTITION BY TERRITORY_ID
                ORDER BY
                    ISNULL(DOT, '2099-12-31') DESC
            ) AS NUM
        FROM
            qryRoster
        WHERE
            ROLE NOT IN ('FCE', 'MDR')
    ) R ON Z.TERR_ID = R.TERRITORY_ID
    AND NUM = 1