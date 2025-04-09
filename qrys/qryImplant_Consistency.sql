-- CREATE VIEW qryImplant_Consistency AS 
WITH MonthlyImplants AS (
    -- Step 1: Extract YYYYMM as an integer
    SELECT
        DISTINCT ACT_ID,
        CAST(FORMAT(IMPLANTED_DT, 'yyyyMM') AS INT) AS YYYYMM
    FROM
        tmpOpps
    WHERE
        OPP_COUNTRY = 'US'
        AND OPP_STATUS = 'CLOSED'
        AND ISIMPL = 1
        AND INDICATION_FOR_USE__C = 'Heart Failure - Reduced Ejection Fraction' -- AND REASON_FOR_IMPLANT__C = 'De novo'
),
OrderedData AS (
    -- Step 2: Determine previous month for each account
    SELECT
        ACT_ID,
        YYYYMM,
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
ACCTS AS (
    -- Step 4: bring in all accounts and tie them to last month
    SELECT
        DISTINCT ID,
        YYYYMM,
        0 AS Consecutive_Months
    FROM
        sfdcAccount
        CROSS JOIN (
            SELECT
                DISTINCT YYYYMM
            FROM
                qryCalendar
            WHERE
                YYYYMM BETWEEN '2021_01'
                AND FORMAT(DATEADD(MONTH, -1, GETDATE()), 'yyyy_MM')
        ) AS C
    WHERE
        SHIPPINGCOUNTRYCODE = 'US'
) -- Count months in each streak group,
SELECT
    ISNULL(ACT_ID, ID) AS ACT_ID,
    ISNULL(IMPLANT_YYYYMM, YYYYMM) AS IMPLANT_YYYYMM,
    ISNULL(
        CALC.Consecutive_Months,
        ACCTS.Consecutive_Months
    ) AS CONSECUTIVE_MONTHS
FROM
    (
        SELECT
            ACT_ID AS ACT_ID,
            StreakGroups.YYYYMM AS IMPLANT_YYYYMM,
            COUNT(*) OVER (
                PARTITION BY ACT_ID,
                Streak_Group
                ORDER BY
                    StreakGroups.YYYYMM ROWS UNBOUNDED PRECEDING
            ) AS Consecutive_Months
        FROM
            StreakGroups
    ) AS CALC FULL
    OUTER JOIN ACCTS ON ACCTS.ID = CALC.ACT_ID
    AND ACCTS.YYYYMM = CALC.IMPLANT_YYYYMM