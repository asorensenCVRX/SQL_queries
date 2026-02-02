-- CREATE VIEW qryQuota_Monthly as
/* Update baselines and quotas in tblQuotas and this query will pull them in */
SELECT
    CAL.YYYYMM,
    RATES.YYYYQQ,
    RATES.TERRITORY_ID,
    RATES.EID,
    CASE
        WHEN Q.YYYYQQ IS NULL THEN CASE
            WHEN CAL.YYYYMM < ACTIVE_YYYYMM THEN ISNULL(Q.BASELINE, 0)
            ELSE ISNULL(Q.BASELINE, RATES.THRESHOLD / 3)
        END
        WHEN Q.YYYYMM IS NULL THEN ISNULL(Q.BASELINE / 3, RATES.THRESHOLD / 3)
    END AS THRESHOLD,
    CASE
        WHEN Q.YYYYQQ IS NULL THEN CASE
            WHEN CAL.YYYYMM < ACTIVE_YYYYMM THEN ISNULL(Q.QUOTA, 0)
            ELSE ISNULL(Q.QUOTA, RATES.[PLAN] / 3)
        END
        WHEN Q.YYYYMM IS NULL THEN ISNULL(Q.QUOTA / 3, RATES.[PLAN] / 3)
    END AS [PLAN]
FROM
    (
        SELECT
            YYYYQQ,
            TERRITORY_ID,
            EID,
            THRESHOLD,
            [PLAN]
        FROM
            qryRates_TM_BY_QTR
        UNION
        SELECT
            YYYYQQ,
            RR.REGION_ID,
            RBQ.EID,
            BL,
            RBQ.QUOTA
        FROM
            qryRates_RM_BY_QTR RBQ
            LEFT JOIN tblRates_RM RR ON RBQ.EID = RR.EID
    ) AS RATES
    LEFT JOIN (
        SELECT
            DISTINCT YYYYMM,
            YYYYQQ
        FROM
            qryCalendar
        WHERE
            LEFT(YYYYQQ, 4) = '2026'
    ) AS CAL ON RATES.YYYYQQ = CAL.YYYYQQ
    LEFT JOIN tblQuota Q ON Q.TERR_ID = RATES.TERRITORY_ID
    AND (
        (
            Q.YYYYMM IS NOT NULL
            AND Q.YYYYMM = CAL.YYYYMM
        )
        OR (
            Q.YYYYQQ IS NOT NULL
            AND Q.YYYYQQ = RATES.YYYYQQ
        )
    )
    LEFT JOIN qryRoster R ON RATES.EID = R.REP_EMAIL
    AND R.[isLATEST?] = 1
    AND R.ROLE = 'REP'
    AND REP_EMAIL NOT IN (
        SELECT
            EMP_EMAIL
        FROM
            qryRoster_RM
    )