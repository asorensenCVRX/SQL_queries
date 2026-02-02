-- CREATE VIEW dbo.qryRates_TM AS
SELECT
    TM.TERRITORY_ID,
    R.REP_EMAIL AS EID,
    TM.TIER,
    CAST(TM.[PLAN] AS MONEY) AS PLAN_FY,
    CAST(TM.THRESHOLD AS MONEY) AS THRESHOLD_FY,
    CAST(TM.THRESHOLD * 0.22 AS MONEY) AS Q1_BL,
    CAST(TM.[PLAN] * 0.22 AS MONEY) AS Q1_Q,
    CAST(TM.THRESHOLD * 0.24 AS MONEY) AS Q2_BL,
    CAST(TM.[PLAN] * 0.24 AS MONEY) AS Q2_Q,
    CAST(TM.THRESHOLD * 0.26 AS MONEY) AS Q3_BL,
    CAST(TM.[PLAN] * 0.26 AS MONEY) AS Q3_Q,
    CAST(TM.THRESHOLD * 0.28 AS MONEY) AS Q4_BL,
    CAST(TM.[PLAN] * 0.28 AS MONEY) AS Q4_Q
FROM
    dbo.tblRates_TM AS TM
    LEFT JOIN (
        SELECT
            *
        FROM
            dbo.qryRoster
        WHERE
            [isLATEST?] = 1
            AND [role] = 'REP'
            AND REP_EMAIL NOT IN (
                SELECT
                    EID
                FROM
                    dbo.tblRates_RM
                WHERE
                    REGION_ID NOT LIKE '%OFF'
            )
    ) AS R ON R.TERRITORY_ID = TM.TERRITORY_ID;

GO