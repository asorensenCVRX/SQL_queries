SELECT
    EMP_EMAIL,
    FNAME,
    LNAME,
    NAME,
    ROLE,
    Tier,
    TERRITORY_ID,
    REGION,
    START_DT,
    END_DT,
    STATUS
FROM
    (
        SELECT
            R.EMP_EMAIL,
            E.FNAME,
            E.LNAME,
            E.NAME,
            R.ROLE,
            RM.Tier,
            R.TERRITORY_ID,
            T.REGION,
            R.START_DT,
            R.END_DT,
            CASE
                WHEN END_DT <= GETDATE() THEN 'TERMED'
                ELSE 'ACTIVE'
            END AS STATUS
        FROM
            dbo.tblRoster AS R
            LEFT OUTER JOIN dbo.qryEmployee AS E ON R.EMP_EMAIL = E.[WORK E-MAIL]
            LEFT OUTER JOIN dbo.tblRates_RM AS RM ON R.EMP_EMAIL = RM.EID
            LEFT OUTER JOIN (
                SELECT
                    DISTINCT REGION_ID,
                    REGION
                FROM
                    dbo.tblTerritory
            ) AS T ON T.REGION_ID = R.TERRITORY_ID
        WHERE
            (R.ROLE = 'RM')
    ) AS A
WHERE
    (STATUS = 'ACTIVE')