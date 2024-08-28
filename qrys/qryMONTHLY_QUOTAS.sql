/* add historical baselines and quotas to tblBaseline_Quota_Historical and this query will pull them in */
SELECT
    CAL.YYYYMM,
    RATES.YYYYQQ,
    RATES.TERR_ID,
    RATES.EID,
    CASE
        WHEN BQH.YYYYQQ IS NULL THEN ISNULL(BQH.BASELINE, RATES.BL / 3)
        WHEN BQH.YYYYMM IS NULL THEN ISNULL(BQH.BASELINE / 3, RATES.BL / 3)
    END AS BASELINE,
    CASE
        WHEN BQH.YYYYQQ IS NULL THEN ISNULL(BQH.QUOTA, RATES.QUOTA / 3)
        WHEN BQH.YYYYMM IS NULL THEN ISNULL(BQH.QUOTA / 3, RATES.QUOTA / 3)
    END AS QUOTA
FROM
    (
        SELECT
            YYYYQQ,
            TERR_ID,
            EID,
            BL,
            QUOTA
        FROM
            qryRates_AM_BY_QTR
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
            LEFT(YYYYQQ, 4) = '2024'
    ) AS CAL ON RATES.YYYYQQ = CAL.YYYYQQ
    LEFT JOIN tblBaseline_Quota_Historical BQH ON BQH.EID = RATES.EID
    AND (
        (
            BQH.YYYYMM IS NOT NULL
            AND BQH.YYYYMM = CAL.YYYYMM
        )
        OR (
            BQH.YYYYQQ IS NOT NULL
            AND BQH.YYYYQQ = RATES.YYYYQQ
        )
    );