-- CREATE VIEW qryQuota_Monthly as
/* add historical baselines and quotas to tblBaseline_Quota_Historical and this query will pull them in */
SELECT
    A.*,
    CASE
        WHEN YYYYQQ = '2024_Q4'
        AND RA.QUOTA_TIER IN ('Tier 1', 'Tier 2') THEN A.BASELINE - (A.BASELINE * 0.33)
        WHEN YYYYQQ = '2024_Q4'
        AND RA.QUOTA_TIER = 'Tier 3' THEN A.BASELINE - (A.BASELINE * 0.5)
        WHEN YYYYQQ = '2024_Q4'
        AND QUOTA_TIER = 'Tier 4' THEN A.BASELINE
    END AS Q4BL
FROM
    (
        SELECT
            CAL.YYYYMM,
            RATES.YYYYQQ,
            RATES.TERR_ID,
            RATES.EID,
            CASE
                WHEN Q.YYYYQQ IS NULL THEN ISNULL(Q.BASELINE, RATES.BL / 3)
                WHEN Q.YYYYMM IS NULL THEN ISNULL(Q.BASELINE / 3, RATES.BL / 3)
            END AS BASELINE,
            CASE
                WHEN Q.YYYYQQ IS NULL THEN ISNULL(Q.QUOTA, RATES.QUOTA / 3)
                WHEN Q.YYYYMM IS NULL THEN ISNULL(Q.QUOTA / 3, RATES.QUOTA / 3)
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
            LEFT JOIN tblQuota Q ON Q.EID = RATES.EID
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
    ) AS A
    LEFT JOIN tblRates_AM RA ON A.EID = RA.EID