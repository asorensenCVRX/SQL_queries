-- CREATE VIEW qryRates_RM_BY_QTR AS
SELECT
    T1.EID,
    REGION_ID,
    T1.YYYYQQ,
    SUM(T1.BL) * 0.75 [75xBL],
    SUM(T1.BL) [BL],
    SUM(T1.QUOTA) - SUM(T1.BL) AS [GROWTH],
    SUM(T1.QUOTA) [QUOTA]
FROM
    (
        SELECT
            EID,
            REGION_ID,
            [QUOTA],
            NULL AS [BL],
            '2026_' + LEFT([QUARTER], 2) [YYYYQQ]
        FROM
            (
                SELECT
                    EID,
                    REGION_ID,
                    Q1_Q,
                    Q2_Q,
                    Q3_Q,
                    Q4_Q
                FROM
                    [dbo].[qryRates_RM]
            ) AS p UNPIVOT (
                [QUOTA] FOR [QUARTER] IN (Q1_Q, Q2_Q, Q3_Q, Q4_Q)
            ) AS UPVT
        UNION
        ALL
        SELECT
            EID,
            region_id,
            NULL AS [QUOTA],
            [BL],
            '2026_' + LEFT([QUARTER], 2) [YYYYQQ]
        FROM
            (
                SELECT
                    EID,
                    region_id,
                    Q1_BL,
                    Q2_BL,
                    Q3_BL,
                    Q4_BL
                FROM
                    [dbo].[qryRates_RM]
            ) AS p UNPIVOT (
                [BL] FOR [QUARTER] IN (Q1_BL, Q2_BL, Q3_BL, Q4_BL)
            ) AS UPVT
    ) AS T1
GROUP BY
    T1.EID,
    region_id,
    T1.YYYYQQ;