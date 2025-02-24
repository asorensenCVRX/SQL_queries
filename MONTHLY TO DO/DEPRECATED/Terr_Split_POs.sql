/*****/
-- INSERT INTO
--     tblSalesSplits
    /*****/
SELECT
    OPP_ID,
    OG_OWNER,
    'REP' AS ROLE,
    CAST('0.' + LEFT([OG_OWNER_%_CREDIT], 2) AS FLOAT) AS SPLIT,
    NULL AS AMT,
    NULL AS ASP,
    NULL AS YYYYMM,
    'OWNER BEFORE TERRITORY SPLIT; ' + [OG_OWNER_%_CREDIT] + ' CREDIT' AS NOTES
FROM
    qryTerritory_Split
WHERE
    sales IS NOT NULL
    AND sales <> 0
    AND NOT EXISTS (
        SELECT
            1
        FROM
            tblSalesSplits
        WHERE
            tblSalesSplits.OPP_ID = qryTerritory_Split.OPP_ID
            AND tblSalesSplits.SALES_CREDIT_REP_EMAIL = qryTerritory_Split.OG_OWNER
    )
    AND CLOSE_YYYYMM < FORMAT(GETDATE(), 'yyyy_MM')
UNION
ALL
SELECT
    OPP_ID,
    SALES_CREDIT_REP_EMAIL,
    'REP' AS ROLE,
    1 AS SPLIT,
    NULL AS AMT,
    NULL AS ASP,
    NULL AS YYYYMM,
    'NEW ACCOUNT OWNER AFTER TERRITORY SPLIT; FULL CREDIT' AS NOTES
FROM
    qryTerritory_Split
WHERE
    sales IS NOT NULL
    AND sales <> 0
    AND NOT EXISTS (
        SELECT
            1
        FROM
            tblSalesSplits
        WHERE
            tblSalesSplits.OPP_ID = qryTerritory_Split.OPP_ID
            AND tblSalesSplits.SALES_CREDIT_REP_EMAIL = qryTerritory_Split.OG_OWNER
    )
    AND CLOSE_YYYYMM < FORMAT(GETDATE(), 'yyyy_MM')