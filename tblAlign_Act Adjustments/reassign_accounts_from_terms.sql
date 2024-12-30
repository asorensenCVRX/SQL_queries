DECLARE @TERMED_OWNER NVARCHAR(MAX) = 'jreedy@cvrx.com';


DECLARE @TERM_DATE DATE = '2024-12-31';


DECLARE @NEW_OWNER NVARCHAR(MAX) = 'jpind@cvrx.com';


/* create a temporary dataset that can be referenced */
WITH DATA AS (
    SELECT
        DENSE_RANK() OVER(
            ORDER BY
                ACT_ID
        ) AS ACCT_NUM,
        ACT_ID,
        RANK() OVER (
            PARTITION BY ACT_ID
            ORDER BY
                ST_DT
        ) AS OWNER_NUM,
        COUNT(*) OVER (PARTITION BY ACT_ID) AS MAX_OWNER,
        OWNER_EMAIL,
        ST_DT,
        END_DT,
        [T_SPLIT_%],
        NOTES
    FROM
        tblAlign_Act
    WHERE
        ACT_ID IN (
            SELECT
                ACT_ID
            FROM
                tblAlign_Act
            WHERE
                OWNER_EMAIL = @TERMED_OWNER
        )
)
SELECT
    * INTO #TEMPtblAlign_Act from DATA;
    /**************
     *****************
     ********/
;


/* TABLE 1 */
/* shows all accounts that used to belong to the termed rep and the account movements */
SELECT
    *
FROM
    #TEMPtblAlign_Act;
;


/* TABLE 2 */
/* shows accounts that still need to be reassigned */
SELECT
    *
FROM
    #TEMPtblAlign_Act
WHERE
    (
        OWNER_EMAIL = @TERMED_OWNER
        AND END_DT = '2099-12-31'
    )
    OR (
        OWNER_NUM = MAX_OWNER
        AND END_DT <> '2099-12-31'
    );


/* TABLE 3 */
/* shows accounts where the termed owner has ownership past term date.
 For these accounts, you need to update the end_dt to the term date. */
-- UPDATE
--     tblAlign_Act
-- SET
--     END_DT = @TERM_DATE
SELECT
    *
FROM
    tblAlign_Act
WHERE
    EXISTS (
        SELECT
            1
        FROM
            #TEMPtblAlign_Act
        WHERE
            OWNER_EMAIL = @TERMED_OWNER
            AND END_DT > @TERM_DATE
            AND #TEMPtblAlign_Act.ACT_ID = tblAlign_Act.ACT_ID
            AND #TEMPtblAlign_Act.OWNER_EMAIL = tblAlign_Act.OWNER_EMAIL
    );


/* TABLE 4 */
/* use this to assign the account to a new owner */
-- INSERT INTO
--     tblAlign_Act
SELECT
    ACT_ID,
    @NEW_OWNER AS OWNER_EMAIL,
    DATEADD(DAY, 1, END_DT) AS ST_DT,
    '2099-12-31' AS END_DT,
    NULL AS [T_SPLIT_%],
    NULL AS NOTES
FROM
    #TEMPtblAlign_Act
WHERE
    (
        OWNER_EMAIL = @TERMED_OWNER
        AND END_DT = '2099-12-31'
    )
    OR (
        OWNER_NUM = MAX_OWNER
        AND END_DT <> '2099-12-31'
    );


/* drop the reference table */
DROP TABLE #TEMPtblAlign_Act;