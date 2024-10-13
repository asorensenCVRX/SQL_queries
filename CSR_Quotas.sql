SELECT
    FA.FCE_EMAIL,
    SUM(BL) AS BL,
    SUM(QUOTA) AS QUOTA
FROM
    tblFCE_ALIGN FA
    LEFT JOIN (
        SELECT
            EID,
            TERR_ID,
            SUM(BASELINE) AS BL,
            SUM(QUOTA) AS QUOTA
        FROM
            qryQuota_Monthly
        GROUP BY
            EID,
            TERR_ID
    ) AS Q ON FA.ID = Q.TERR_ID
GROUP BY
    FCE_EMAIL