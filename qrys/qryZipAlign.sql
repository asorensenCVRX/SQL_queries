-- CREATE VIEW qryZipAlign AS
SELECT
    Z.*,
    R.TERRITORY AS TERR_NAME,
    R.REGION,
    R.REGION_ID,
    CASE
        WHEN DOT <= GETDATE() THEN NULL
        ELSE REP_EMAIL
    END AS REP_EMAIL,
    CASE
        WHEN DOT <= GETDATE() THEN CONCAT(R.TERRITORY, ' (OPEN)')
        ELSE LNAME_REP
    END AS LNAME_REP,
    CASE
        WHEN DOT <= GETDATE() THEN CONCAT(R.TERRITORY, ' (OPEN)')
        ELSE FNAME_REP
    END AS FNAME_REP,
    CASE
        WHEN DOT <= GETDATE() THEN CONCAT(R.TERRITORY, ' (OPEN)')
        ELSE NAME_REP
    END AS NAME_REP
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