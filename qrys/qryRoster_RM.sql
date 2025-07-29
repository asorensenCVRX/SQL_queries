-- CREATE VIEW qryRoster_RM AS
SELECT
    *
FROM
    (
        SELECT
            R.EMP_EMAIL,
            E.FNAME,
            E.LNAME,
            E.FNAME + ' ' + E.LNAME AS NAME,
            R.ROLE,
            RM.TIER,
            R.TERRITORY_ID,
            T.REGION,
            R.START_DT,
            R.END_DT,
            CASE
                WHEN END_DT <= GETDATE() THEN 'TERMED'
                ELSE 'ACTIVE'
            END AS [STATUS]
        FROM
            tblRoster R
            LEFT JOIN qryEmployee AS E ON R.EMP_EMAIL = E.[WORK E-MAIL]
            LEFT JOIN tblRates_RM RM ON R.EMP_EMAIL = RM.EID
            LEFT JOIN (
                SELECT
                    DISTINCT REGION_ID,
                    REGION
                FROM
                    tblTerritory
            ) T ON T.REGION_ID = R.TERRITORY_ID
        WHERE
            role = 'RM'
    ) AS A
WHERE
    [STATUS] = 'ACTIVE'