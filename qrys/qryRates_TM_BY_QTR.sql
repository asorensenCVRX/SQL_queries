-- CREATE VIEW qryRates_TM_BY_QTR AS
SELECT
    T1.TERRITORY_ID,
    T1.EID,
    T1.YYYYQQ,
    SUM(T1.THRESHOLD) [THRESHOLD],
    SUM(T1.[PLAN]) - SUM(T1.THRESHOLD) AS [GROWTH],
    SUM(T1.[PLAN]) AS [PLAN]
FROM
    (
        SELECT
            TERRITORY_ID,
            EID,
            [PLAN],
            NULL AS [THRESHOLD],
            '2026_' + LEFT([QUARTER], 2) [YYYYQQ]
        FROM
            (
                SELECT
                    TERRITORY_ID,
                    EID,
                    Q1_Q,
                    Q2_Q,
                    Q3_Q,
                    Q4_Q
                FROM
                    [dbo].[qryRates_TM]
            ) AS p UNPIVOT (
                [PLAN] FOR [QUARTER] IN (Q1_Q, Q2_Q, Q3_Q, Q4_Q)
            ) AS UPVT
        UNION
        ALL
        SELECT
            TERRITORY_ID,
            EID,
            NULL AS [QUOTA],
            [THRESHOLD],
            '2026_' + LEFT([QUARTER], 2) [YYYYQQ]
        FROM
            (
                SELECT
                    TERRITORY_ID,
                    EID,
                    Q1_BL,
                    Q2_BL,
                    Q3_BL,
                    Q4_BL
                FROM
                    [dbo].[qryRates_TM]
            ) AS p UNPIVOT (
                [THRESHOLD] FOR [QUARTER] IN (Q1_BL, Q2_BL, Q3_BL, Q4_BL)
            ) AS UPVT
    ) AS T1
GROUP BY
    T1.TERRITORY_ID,
    T1.EID,
    T1.YYYYQQ;