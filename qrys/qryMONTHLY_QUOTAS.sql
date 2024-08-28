SELECT
    CAL.YYYYMM,
    RATES.YYYYQQ,
    RATES.TERR_ID,
    RATES.EID,
    RATES.BL / 3 AS BL,
    RATES.QUOTA / 3 AS QUOTA
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
WHERE
    EID = 'lmincey@cvrx.com'