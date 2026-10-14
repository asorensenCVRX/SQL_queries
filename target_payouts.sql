WITH R AS (
    SELECT
        REPLACE([ROLE], 'REP', 'TM') AS [ROLE],
        NAME_REP,
        REP_EMAIL,
        TERRITORY_ID,
        TERRITORY,
        REGION,
        -- DOH,
        -- DOT,
        ROLE_START_DT
    FROM
        qryRoster
    WHERE
        [isLATEST?] = 1
        AND [ROLE] = 'REP'
        AND [STATUS] = 'ACTIVE'
),
P_RATES AS (
    SELECT
        EID,
        TERRITORY_ID,
        SUM(THRESHOLD) AS THRESHOLD,
        SUM([PLAN]) AS [PLAN]
    FROM
        qryQuota_Monthly
    GROUP BY
        EID,
        TERRITORY_ID
),
Q0 AS (
    SELECT
        R.*,
        ROUND(CAST(P_RATES.THRESHOLD AS MONEY), 2) AS PRORATED_THRESHOLD,
        ROUND(CAST(P_RATES.[PLAN] AS MONEY), 2) AS [PRORATED_PLAN],
        ROUND(CAST(P_RATES.THRESHOLD *.2 AS MONEY), 2) AS PRORATED_L1_PO,
        ROUND(
            CAST(
                (P_RATES.[PLAN] - P_RATES.THRESHOLD) *.25 AS MONEY
            ),
            2
        ) AS PRORATED_L2_PO
    FROM
        R
        LEFT JOIN P_RATES ON R.REP_EMAIL = P_RATES.EID
),
Q1 AS (
    SELECT
        Q0.*,
        PRORATED_L1_PO + PRORATED_L2_PO AS [PRORATED_2026_TARGET_PO],
        ROUND(CAST(T.THRESHOLD AS MONEY), 2) AS FY_THRESHOLD,
        ROUND(CAST(T.[PLAN] AS MONEY), 2) AS FY_PLAN,
        ROUND(CAST(T.THRESHOLD *.2 AS MONEY), 2) AS FY_L1_PO,
        ROUND(
            CAST(
                (T.[PLAN] - T.THRESHOLD) *.25 AS MONEY
            ),
            2
        ) AS FY_L2_PO
    FROM
        Q0
        LEFT JOIN tblRates_TM T ON Q0.TERRITORY_ID = T.TERRITORY_ID
)
SELECT
    *,
    FY_L1_PO + FY_L2_PO AS [FY_2026_TARGET_PO]
FROM
    Q1