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
),
E AS (
    SELECT
        *,
        CASE
            WHEN OVERLAP_FLAG = 1 THEN (
                SELECT
                    top 1 y.TERR_ID
                FROM
                    tblAct_Exceptions y
                WHERE
                    y.SFDC_ID = a.SFDC_ID
                    AND Y.COVERAGE_TYPE = 'Ownership Override'
                ORDER BY
                    Y.START
            )
        END AS OWNERSHIP_OVERRIDE_TERR_ID
    FROM
        (
            SELECT
                r.*,
                CASE
                    WHEN EXISTS (
                        SELECT
                            1
                        FROM
                            tblAct_Exceptions AS x
                        WHERE
                            x.SFDC_ID = r.SFDC_ID
                            AND x.START <= COALESCE(r.[END], CONVERT(date, '9999-12-31'))
                            AND r.START <= COALESCE(x.[END], CONVERT(date, '9999-12-31'))
                            AND NOT (
                                ISNULL(x.TERR_ID, '') = ISNULL(r.TERR_ID, '')
                                AND ISNULL(x.COVERAGE_TYPE, '') = ISNULL(r.COVERAGE_TYPE, '')
                                AND x.START = r.START
                                AND ISNULL(x.[END], '9999-12-31') = ISNULL(r.[END], '9999-12-31')
                            )
                    ) THEN 1
                    ELSE 0
                END AS OVERLAP_FLAG
            FROM
                tblAct_Exceptions AS r
        ) AS A
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
    END AS COVERAGE_TYPE,
    CASE
        WHEN E.COVERAGE_TYPE <> 'Open Territory' THEN ISNULL(E.TERR_ID, Z.TERR_ID)
        WHEN E.COVERAGE_TYPE = 'Open Territory'
        AND E.OVERLAP_FLAG = 1 THEN OWNERSHIP_OVERRIDE_TERR_ID
        ELSE Z.TERR_ID
    END AS DE_FACTO_TERR_ID
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
    LEFT JOIN E ON A.ACT_ID = E.SFDC_ID
    AND A.REP_TERR_ID = E.TERR_ID
    AND (
        A.ST_DT BETWEEN ISNULL(E.[START], '2025-01-01')
        AND ISNULL(E.[END], '2099-12-31')
        OR END_DT BETWEEN ISNULL(E.[START], '2025-01-01')
        AND ISNULL(E.[END], '2099-12-31')
    )