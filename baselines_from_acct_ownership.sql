/* Checks if there are any Tier 4 reps who have accounts with 2023 revenue. 
 If there is 2023 revenue, these reps should be at least tier 3. */
SELECT
    A.ID AS ACT_ID,
    A.[NAME] AS ACT_NAME,
    U.NAME AS OWNER_NAME,
    U.EMAIL AS OWNER_EMAIL,
    RL.TM_EMAIL,
    RL.RM_EMAIL,
    RL.AD_EMAIL,
    R.QUOTA_TIER,
    PY_REV.SALES AS [2023_ACCOUNT_SALES],
    CY_REV.SALES AS [2024_ACCOUNT_SALES],
    AO.EMAIL AS [2023_OWNER]
FROM
    sfdcAccount A
    LEFT JOIN sfdcUser U ON A.OWNERID = U.ID
    LEFT JOIN tblRates_AM R ON U.EMAIL = R.EID
    LEFT JOIN (
        SELECT
            act_id,
            sum(SALES) AS SALES
        FROM
            qryOpps
        WHERE
            CLOSE_YYYY = 2023
            AND INDICATION_FOR_USE__C = 'Heart Failure - Reduced Ejection Fraction'
        GROUP BY
            ACT_ID
        HAVING
            sum(sales) > 0
    ) PY_REV ON A.ID = PY_REV.ACT_ID
    LEFT JOIN (
        SELECT
            act_id,
            sum(SALES) AS SALES
        FROM
            qryOpps
        WHERE
            CLOSE_YYYY = 2024
            AND INDICATION_FOR_USE__C = 'Heart Failure - Reduced Ejection Fraction'
        GROUP BY
            ACT_ID
        HAVING
            sum(sales) > 0
    ) CY_REV ON A.ID = CY_REV.ACT_ID
    LEFT JOIN (
        SELECT
            EMAIL,
            ACT_ID
        FROM
            (
                SELECT
                    A.EMAIL,
                    A.ACT_ID,
                    O.ACCOUNT_INDICATION__C,
                    CLOSEDATE,
                    ROW_NUMBER() OVER(
                        PARTITION BY A.ACT_ID
                        ORDER BY
                            CLOSEDATE DESC
                    ) AS RN
                FROM
                    tblAlign_Opp A
                    INNER JOIN qryOpps O ON A.OPP_ID = O.OPP_ID
                    AND O.CLOSE_YYYY < 2024
            ) T
        WHERE
            T.RN = 1
    ) AO ON A.ID = AO.ACT_ID
    LEFT JOIN qryReport_Ladder RL ON U.NAME = RL.NAME_REP -- WHERE
    --     A.ID IN (
    --         SELECT
    --             DISTINCT act_id
    --         FROM
    --             qryOpps
    --         WHERE
    --             CLOSE_YYYY = 2023
    --         GROUP BY
    --             ACT_ID
    --         HAVING
    --             sum(sales) > 0
    --     )
ORDER BY
    4;