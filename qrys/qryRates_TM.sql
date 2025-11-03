-- CREATE VIEW qryRates_TM AS
SELECT
    TM.TERRITORY_ID,
    R.REP_EMAIL AS EID,
    TM.TIER,
    CAST([PLAN] AS MONEY) AS PLAN_FY,
    CAST(THRESHOLD AS MONEY) AS THRESHOLD_FY,
    CAST(THRESHOLD * 0.224130424 AS MONEY) AS Q1_BL,
    CAST([PLAN] * 0.224130424 AS MONEY) AS Q1_Q,
    CAST(THRESHOLD * 0.240626965 AS MONEY) AS Q2_BL,
    CAST([PLAN] * 0.240626965 AS MONEY) AS Q2_Q,
    CAST(THRESHOLD * 0.258623192 AS MONEY) AS Q3_BL,
    CAST([PLAN] * 0.258623192 AS MONEY) AS Q3_Q,
    CAST(THRESHOLD * 0.276619419 AS MONEY) AS Q4_BL,
    CAST([PLAN] * 0.276619419 AS MONEY) AS Q4_Q
FROM
    tblRates_TM TM
    LEFT JOIN (
        SELECT
            *
        FROM
            qryRoster
        WHERE
            [isLATEST?] = 1
            AND role = 'REP'
            AND REP_EMAIL NOT IN (
                SELECT
                    EID
                FROM
                    tblRates_RM
                WHERE
                    REGION_ID NOT LIKE '%OFF'
            )
    ) R ON R.TERRITORY_ID = TM.TERRITORY_ID