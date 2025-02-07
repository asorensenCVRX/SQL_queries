SELECT
    *,
    L1_PO + L2_PO AS PO_AMT
    /******/
    -- INTO tmpASD_PO
    /*****/
FROM
    (
        SELECT
            CLOSE_YYYYMM,
            REGION_NM,
            REGION_ID,
            SALES_CREDIT_ASD_EMAIL,
            THRESHOLD,
            [PLAN],
            SUM(IMPLANT_UNITS) AS IMPLANT_UNITS,
            SUM(REVENUE_UNITS) AS REVENUE_UNITS,
            SUM(SALES) AS SALES,
            SUM([L1_REV]) AS L1_REV,
            [L1 Rate],
            SUM(L2_REV) AS L2_REV,
            [L2 Rate],
            SUM(L1_PO) AS L1_PO,
            SUM(L2_PO) AS L2_PO --add spiff po
        FROM
            qry_COMP_ASD_DETAIL
        WHERE
            CLOSE_YYYYMM <= FORMAT(DATEADD(MONTH, -1, GETDATE()), 'yyyy_MM')
        GROUP BY
            CLOSE_YYYYMM,
            REGION_NM,
            REGION_ID,
            SALES_CREDIT_ASD_EMAIL,
            THRESHOLD,
            [PLAN],
            [L1 Rate],
            [L2 Rate]
    ) AS A