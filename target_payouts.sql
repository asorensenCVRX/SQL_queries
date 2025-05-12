WITH R AS (
    SELECT
        [ROLE],
        NAME_REP,
        REP_EMAIL,
        TERRITORY_ID,
        DOH,
        DOT
    FROM
        qryRoster
    WHERE
        [isLATEST?] = 1
        AND [ROLE] = 'REP'
        AND [STATUS] = 'ACTIVE'
),
RATES AS (
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
)
SELECT
    *,
    L1_PO + L2_PO AS [2025_TARGET_PO]
FROM
    (
        SELECT
            R.*,
            ROUND(CAST(RATES.THRESHOLD AS MONEY), 2) AS THRESHOLD,
            ROUND(CAST(RATES.[PLAN] AS MONEY), 2) AS [PLAN],
            ROUND(CAST(THRESHOLD *.2 AS MONEY), 2) AS L1_PO,
            ROUND(CAST(([PLAN] - THRESHOLD) *.25 AS MONEY), 2) AS L2_PO
        FROM
            R
            LEFT JOIN RATES ON R.REP_EMAIL = RATES.EID
    ) AS A