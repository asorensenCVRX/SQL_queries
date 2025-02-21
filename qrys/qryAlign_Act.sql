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
                qryRoster_RM
        ) THEN 'Open Territory'
        ELSE ISNULL(E.COVERAGE_TYPE, 'Normal')
    END AS COVERAGE_TYPE
FROM
    (
        SELECT
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