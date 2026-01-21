-- CREATE VIEW qryImplant_Consistency AS 
WITH MonthlyImplants AS (
    -- Step 1: Extract YYYYMM as an integer
    SELECT
        ACT_ID,
        CAST(FORMAT(IMPLANTED_DT, 'yyyyMM') AS INT) AS YYYYMM,
        SUM(IMPLANT_UNITS) [IMPLANT_UNITS]
    FROM
        tmpOpps
    WHERE
        OPP_COUNTRY = 'US'
        AND OPP_STATUS = 'CLOSED'
        AND ISIMPL = 1
        AND INDICATION_FOR_USE__C = 'Heart Failure - Reduced Ejection Fraction' -- AND REASON_FOR_IMPLANT__C = 'De novo'
    GROUP BY
        ACT_ID,
        CAST(FORMAT(IMPLANTED_DT, 'yyyyMM') AS INT)
),
OrderedData AS (
    -- Step 2: Determine previous month for each account
    SELECT
        ACT_ID,
        YYYYMM,
        IMPLANT_UNITS,
        LAG(YYYYMM) OVER (
            PARTITION BY ACT_ID
            ORDER BY
                YYYYMM
        ) AS Prev_YYYYMM,
        -- Calculate expected previous month correctly
        CASE
            WHEN YYYYMM % 100 = 1 THEN (YYYYMM / 100 - 1) * 100 + 12 -- If January, previous is last December
            ELSE YYYYMM - 1 -- Otherwise, just subtract 1
        END AS Expected_Prev_YYYYMM
    FROM
        MonthlyImplants
),
StreakGroups AS (
    -- Step 3: Identify gaps in monthly sequence and create a streak group
    SELECT
        ACT_ID,
        CONCAT(Left(YYYYMM, 4), '_', RIGHT(YYYYMM, 2)) AS YYYYMM,
        IMPLANT_UNITS,
        SUM(
            CASE
                WHEN Prev_YYYYMM IS NULL
                OR Prev_YYYYMM <> Expected_Prev_YYYYMM THEN 1
                ELSE 0
            END
        ) OVER (
            PARTITION BY ACT_ID
            ORDER BY
                OrderedData.YYYYMM ROWS UNBOUNDED PRECEDING
        ) AS Streak_Group
    FROM
        OrderedData
),
MNTHS AS (
    -- Generate all months for each account in MonthlyImplants from the month of their first implant to last month
    SELECT
        DISTINCT I.ACT_ID,
        C.YYYYMM,
        0 AS Consecutive_Months
    FROM
        MonthlyImplants AS I
        CROSS JOIN (
            SELECT
                DISTINCT YYYYMM
            FROM
                qryCalendar
            WHERE
                YYYYMM <= FORMAT(GETDATE(), 'yyyy_MM')
        ) AS C
    WHERE
        C.YYYYMM >= (
            SELECT
                MIN(
                    CONCAT(
                        LEFT(CONVERT(varchar(6), MI.YYYYMM), 4),
                        '_',
                        RIGHT(CONVERT(varchar(6), MI.YYYYMM), 2)
                    )
                )
            FROM
                MonthlyImplants AS MI
            WHERE
                MI.ACT_ID = I.ACT_ID
        )
),
Q AS (
    SELECT
        ISNULL(CALC.ACT_ID, MNTHS.ACT_ID) AS ACT_ID,
        ISNULL(IMPLANT_YYYYMM, YYYYMM) AS IMPLANT_YYYYMM,
        isnull(IMPLANT_UNITS, 0) [IMPLANT_UNITS],
        ISNULL(
            CALC.Consecutive_Months,
            MNTHS.Consecutive_Months
        ) AS CONSECUTIVE_MONTHS
    FROM
        (
            SELECT
                ACT_ID AS ACT_ID,
                StreakGroups.YYYYMM AS IMPLANT_YYYYMM,
                IMPLANT_UNITS,
                -- Count months in each streak group
                COUNT(*) OVER (
                    PARTITION BY ACT_ID,
                    Streak_Group
                    ORDER BY
                        StreakGroups.YYYYMM ROWS UNBOUNDED PRECEDING
                ) AS Consecutive_Months
            FROM
                StreakGroups
        ) AS CALC FULL
        OUTER JOIN MNTHS ON MNTHS.ACT_ID = CALC.ACT_ID
        AND MNTHS.YYYYMM = CALC.IMPLANT_YYYYMM
)
SELECT
    *,
    IMPLANTS_R6 / 6.0 AS R6_AVG_IMPL
FROM
    (
        SELECT
            *,
            SUM(IMPLANT_UNITS) OVER (
                PARTITION BY ACT_ID
                ORDER BY
                    IMPLANT_YYYYMM ROWS BETWEEN 5 PRECEDING
                    AND CURRENT ROW
            ) AS IMPLANTS_R6,
            SUM(
                CASE
                    WHEN CONSECUTIVE_MONTHS <> 0 THEN 1
                    ELSE 0
                END
            ) OVER (
                PARTITION BY ACT_ID
                ORDER BY
                    IMPLANT_YYYYMM ROWS BETWEEN 5 PRECEDING
                    AND CURRENT ROW
            ) AS R6_MONTHS_W_IMPLANT
        FROM
            Q
    ) AS A