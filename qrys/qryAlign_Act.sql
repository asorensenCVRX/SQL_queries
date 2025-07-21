-- CREATE VIEW qryAlign_Act AS 
WITH REP_TERR AS (
    SELECT
        A.*
    FROM
        (
            SELECT
                TERRITORY_ID,
                REP_EMAIL,
                ROW_NUMBER() OVER (
                    PARTITION BY REP_EMAIL
                    ORDER BY
                        DOT
                ) [COUNT]
            FROM
                qryRoster
            WHERE
                role = 'REP'
        ) A
    WHERE
        COUNT = 1
),
ACCT AS (
    SELECT
        NAME,
        ID,
        DHC_IDN_NAME__C,
        LEFT(SHIPPINGPOSTALCODE, 5) AS ZIP
    FROM
        sfdcAccount
    WHERE
        SHIPPINGCOUNTRYCODE = 'US'
)
SELECT
    A.*,
    Z.TERR_ID AS ZIP_TERR_ID,
    CASE
        WHEN A.REP_TERR_ID <> Z.TERR_ID THEN 1
        ELSE 0
    END AS [TERR_MISMATCH?],
    CASE
        WHEN OWNER_EMAIL IN (
            SELECT
                EMP_EMAIL
            FROM
                tblRoster
            WHERE
                [ROLE] IN ('FCE', 'RM')
        ) THEN CASE
            /* this statement solves for CS reps who own accounts then are promoted to a TM role while still maintaining those accounts */
            WHEN EXISTS (
                SELECT
                    1
                FROM
                    tblRoster R
                WHERE
                    R.EMP_EMAIL = A.OWNER_EMAIL
                    AND [ROLE] = 'REP'
                    AND A.END_DT BETWEEN R.START_DT
                    AND R.END_DT
            ) THEN ISNULL(E.COVERAGE_TYPE, 'Normal')
            /* this statement assigns accounts as 'Open Territory' when the account is taken over by someone in a CS role */
            WHEN EXISTS(
                SELECT
                    1
                FROM
                    tblRoster R
                WHERE
                    R.EMP_EMAIL = A.OWNER_EMAIL
                    AND [ROLE] IN ('FCE', 'RM')
                    AND A.ST_DT BETWEEN R.START_DT
                    AND R.END_DT
            ) THEN 'Open Territory'
            ELSE ISNULL(E.COVERAGE_TYPE, 'Normal')
        END
        ELSE ISNULL(E.COVERAGE_TYPE, 'Normal')
    END AS COVERAGE_TYPE
FROM
    (
        SELECT
            ACCT.NAME,
            A.ACT_ID,
            CAST(
                CASE
                    WHEN LEN(ACCT.ZIP) = 4 THEN CONCAT(0, ZIP)
                    ELSE ACCT.ZIP
                END AS VARCHAR(5)
            ) AS ZIP,
            A.OWNER_EMAIL,
            A.ST_DT,
            A.END_DT,
            REP_TERR.TERRITORY_ID AS REP_TERR_ID
        FROM
            tblAlign_Act A
            LEFT JOIN REP_TERR ON A.OWNER_EMAIL = REP_TERR.REP_EMAIL
            LEFT JOIN ACCT ON A.ACT_ID = ACCT.ID
    ) AS A
    LEFT JOIN tblZipAlign Z ON Z.ZIP_CODE = A.ZIP
    LEFT JOIN tblAct_Exceptions E ON A.ACT_ID = E.SFDC_ID
    AND A.REP_TERR_ID = E.TERR_ID
    AND A.REP_TERR_ID <> Z.TERR_ID
    AND (
        A.ST_DT BETWEEN ISNULL(E.[START], '2025-01-01')
        AND ISNULL(E.[END], '2099-12-31')
        OR END_DT BETWEEN ISNULL(E.[START], '2025-01-01')
        AND ISNULL(E.[END], '2099-12-31')
    )