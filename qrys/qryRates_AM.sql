-- CREATE VIEW qryRates_AM AS
SELECT
    A.TERR_ID,
    A.EID,
    A.[isTM?],
    A.TM_EID,
    A.Tier,
    A.QUOTA_TIER,
    CAST([L1A] AS FLOAT) AS L1A,
    CAST([L1B] AS FLOAT) AS L1B,
    CAST([L2] AS FLOAT) AS L2,
    CAST([L3] AS FLOAT) AS L3,
    CAST(A.Quota AS MONEY) AS QUOTA_FY,
    CAST(A.Baseline AS MONEY) AS BL_FY,
    CAST(A.Baseline * 0.21 AS MONEY) AS Q1_BL,
    CAST(A.Quota * 0.21 AS MONEY) AS Q1_Q,
    CAST(A.Baseline * 0.25 AS MONEY) AS Q2_BL,
    CAST(A.Quota * 0.25 AS MONEY) AS Q2_Q,
    CAST(A.Baseline * 0.26 AS MONEY) AS Q3_BL,
    CAST(A.Quota * 0.26 AS MONEY) AS Q3_Q,
    CAST(A.Baseline * 0.28 AS MONEY) AS Q4_BL,
    CAST(A.Quota * 0.28 AS MONEY) AS Q4_Q,
    CAST(A.TGT_PO AS MONEY) AS TGT_PO,
    A.[GROWTH_%_24]
FROM
    dbo.tblRates_AM AS A
    LEFT OUTER JOIN (
        SELECT
            DISTINCT TM_EID
        FROM
            dbo.tblRates_AM
        WHERE
            (TM_EID IS NOT NULL)
            AND TM_EID <> 'ccraigo@cvrx.com'
    ) AS B ON A.EID = B.TM_EID
WHERE
    A.EID NOT IN (
        SELECT
            EID
        FROM
            tblRates_AM_EX
    ) -- UNION
    -- ALL
    -- SELECT
    --     *
    -- FROM
    --     tblrates_AM_EX;