DECLARE @yyyymm VARCHAR(25);
DECLARE @year VARCHAR(25);
DECLARE @quarter VARCHAR(25);
DECLARE @role VARCHAR(25);


/***** ADJUST THESE VALUES ONLY *****/
/***** REMEMBER TO DO THIS FOR REPS, FCES AND RMS *****/
SET @yyyymm = '2024_07';
SET @year = '2024';
SET @quarter = '2024_Q3';
SET @role = 'RM';
/**************************************************/

/*** This query is an integrity check to delete existing YTD_POs for the same period they are being inserted ***/
DELETE
FROM
    tblPayout
WHERE
    yyyymm = @yyyymm
    AND [ROLE] = @role
    AND CATEGORY = 'YTD_PO';


/***************/
-- INSERT INTO
--     tblPayout
/**************/
SELECT
    @yyyymm AS YYYYMM,
    EID,
    @quarter AS YYYYQQ,
    @role AS ROLE,
    CASE
        WHEN EID IN (
            SELECT
                DISTINCT EID
            FROM
                tblPayout
            WHERE
                yyyymm = @yyyymm
                AND [STATUS] = 'ACTIVE'
        ) THEN 'ACTIVE'
        ELSE 'TERMED'
    END AS STATUS,
    VALUE,
    'YTD_PO' AS CATEGORY,
    NULL AS NOTES
FROM
    (
        SELECT
            EID,
            sum(cast(value AS float)) AS VALUE
        FROM
            tblPayout
        WHERE
            left(YYYYMM, 4) = @year
            AND CATEGORY = 'PO_AMT'
            AND ROLE = @role
        GROUP BY
            eid
    ) A
WHERE
    EID IN (
        SELECT
            DISTINCT EID
        FROM
            tblPayout
        WHERE
            yyyymm = @yyyymm
    );


-- AND EID = 'jclemmons@cvrx.com';
-- SELECT
--     *
-- FROM
--     (
--         SELECT
--             EID,
--             cast(value as float) as value,
--             CATEGORY
--         FROM
--             tblPayout
--         WHERE
--             LEFT(yyyymm, 4) = '2024'
--             AND STATUS = 'ACTIVE'
--             AND ROLE = 'REP'
--     ) AS SOURCE PIVOT (
--         SUM(value) FOR CATEGORY IN ([PO_AMT], [GUR_AMT])
--     ) AS PIVOT_TABLE;

