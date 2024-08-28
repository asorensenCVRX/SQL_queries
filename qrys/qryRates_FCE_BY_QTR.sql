-- CREATE VIEW qryRates_FCE_BY_QTR AS
SELECT
    FCE_EMAIL,
    YYYYQQ,
    QUOTA
FROM
    (
        SELECT
            FCE_EMAIL,
            QUOTA * 0.21 AS [2024_Q1],
            QUOTA * 0.25 AS [2024_Q2],
            QUOTA * 0.26 AS [2024_Q3],
            QUOTA * 0.28 AS [2024_Q4],
            QUOTA AS FY_QUOTA
        FROM
            (
                SELECT
                    FCE_EMAIL,
                    SUM(QUOTA) AS QUOTA
                FROM
                    (
                        SELECT
                            F.*,
                            CASE
                                WHEN RM.Quota IS NULL THEN AM.Quota
                                ELSE RM.Quota
                            END AS QUOTA
                        FROM
                            tblFCE_ALIGN F
                            LEFT JOIN tblRates_RM RM ON F.ID = RM.REGION_ID
                            LEFT JOIN tblRates_AM AM ON F.ID = AM.TERR_ID
                    ) AS A
                GROUP BY
                    FCE_EMAIL
            ) AS B
    ) AS SOURCE UNPIVOT (
        QUOTA FOR YYYYQQ IN ([2024_Q1], [2024_Q2], [2024_Q3], [2024_Q4])
    ) AS PVT