-- IF OBJECT_ID(N'dbo.tmpRM_PO', N'U') IS NOT NULL DROP TABLE dbo.tmpRM_PO
-- GO
SELECT
    ISNULL(SALES_CREDIT_RM_EMAIL, B.EMP_EMAIL) AS [SALES_CREDIT_RM_EMAIL],
    C.NAME,
    ISNULL(A.ROLE, B.ROLE) AS [ROLE],
    ISNULL(A.[CLOSE_YYYYMM], B.[YYYYMM]) AS [YYYYMM],
    ISNULL(A.CLOSE_YYYYQQ, B.YYYYQQ) AS [YYYYQQ],
    A.QTY,
    A.SALES,
    --isnull( CASE
    --     WHEN SALES_CREDIT_RM_EMAIL = 'jheimsoth@cvrx.com' THEN SUM(A.SALES_NEW) OVER(PARTITION BY replace(ISNULL(SALES_CREDIT_RM_EMAIL, B.EMP_EMAIL), 'jgarner@Cvrx.Com', 'jheimsoth@cvrx.com')) - SALES_NEW
    --     WHEN SALES_CREDIT_RM_EMAIL = 'mbrown@cvrx.com' THEN SUM(A.SALES_NEW) OVER(PARTITION BY replace(ISNULL(SALES_CREDIT_RM_EMAIL, B.EMP_EMAIL), 'ccastillo@Cvrx.Com', 'mbrown@cvrx.com')) - SALES_NEW
    --     WHEN SALES_CREDIT_RM_EMAIL = 'pknight@cvrx.com' THEN SUM(A.SALES_NEW) OVER(PARTITION BY replace(ISNULL(SALES_CREDIT_RM_EMAIL, B.EMP_EMAIL), 'kdenton@Cvrx.Com', 'pknight@cvrx.com')) - SALES_NEW
    --     ELSE NULL
    -- END,0) AS [SALES_NEW_RM], 
    A.AD_SALES,
    B.PO_FREQ,
    B.PO_AMT [GUR_AMT],
    A.RM_L1_PO,
    A.RM_L2_PO,
    A.RM_L3_PO,
    ISNULL(SP.PO, 0) AS SPIFF_PO,
    A.AD_PO,
    A.RM_L1_REV,
    A.RM_L2_REV,
    A.RM_L3_REV,
    RM_TTL_PO AS [EARNED_MNTH_PO],
    SUM(RM_TTL_PO) OVER(
        PARTITION BY SALES_CREDIT_RM_EMAIL,
        ISNULL(A.CLOSE_YYYYQQ, B.YYYYQQ)
        ORDER BY
            SALES_CREDIT_RM_EMAIL,
            ISNULL(A.CLOSE_YYYYQQ, B.YYYYQQ),
            ISNULL(A.[CLOSE_YYYYMM], B.[YYYYMM])
    ) AS [EARNED_QTD_PO],
    CASE
        WHEN PO_FREQ = 'M'
        AND B.PO_AMT > ISNULL(RM_TTL_PO, 0) THEN B.PO_AMT - ISNULL(RM_TTL_PO, 0)
        ELSE 0
    END AS [GUR_ADJ],
    CASE
        WHEN PO_FREQ = 'M'
        AND B.PO_AMT > ISNULL(RM_TTL_PO + SP.PO, 0) THEN B.PO_AMT
        ELSE A.RM_TTL_PO + SP.PO
    END AS [PO_AMT],
    g.L1,
    g.L2,
    g.L3,
    [Q1_BL],
    [Q1_Q],
    [Q2_BL],
    [Q2_Q],
    [Q3_BL],
    [Q3_Q],
    [Q4_BL],
    [Q4_Q] --INTO dbo.tmpRM_PO
FROM
    (
        /****************************************************** 
         THIS IS THE AGGREGATE MONTHLY SALES BY RM START 
         *******************************************************/
        SELECT
            SALES_CREDIT_RM_EMAIL,
            [ROLE],
            [CLOSE_YYYYMM],
            [CLOSE_YYYYQQ],
            SUM(QTY) QTY,
            SUM(SALES) SALES,
            SUM(AD_SALES) AD_SALES,
            SUM(AD_PO) AD_PO,
            SUM(RM_L1_PO) [RM_L1_PO],
            SUM(RM_L2_PO) [RM_L2_PO],
            SUM(RM_L3_PO) [RM_L3_PO],
            SUM(RM_L1_REV) [RM_L1_REV],
            SUM(RM_L2_REV) [RM_L2_REV],
            SUM(RM_L3_REV) [RM_L3_REV],
            SUM(RM_L1_PO) + SUM(RM_L2_PO) + SUM(RM_L3_PO) + ISNULL(SUM(AD_PO), 0) AS [RM_TTL_PO]
        FROM
            /*********************************************** 
             THIS IS THE DETAIL SUBQUERY START
             ************************************************/
            (
                SELECT
                    x.*,
                    z.AD_SALES * x.[L1] AS [AD_PO],
                    z.AD_SALES
                FROM
                    (
                        SELECT
                            A.SALES_CREDIT_RM_EMAIL,
                            A.[ROLE],
                            A.[CLOSE_YYYYMM],
                            A.[CLOSE_YYYYQQ],
                            A.L1,
                            SUM(A.QTY) QTY,
                            SUM(A.SALES) SALES,
                            --SUM(A.AD_SALES) AD_SALES, 
                            SUM(A.RM_L1_PO) [RM_L1_PO],
                            SUM(A.RM_L2_PO) [RM_L2_PO],
                            SUM(A.RM_L3_PO) [RM_L3_PO],
                            SUM(A.RM_L1_REV) [RM_L1_REV],
                            SUM(A.RM_L2_REV) [RM_L2_REV],
                            SUM(A.RM_L3_REV) [RM_L3_REV],
                            SUM(A.RM_L1_PO) + SUM(A.RM_L2_PO) + SUM(A.RM_L3_PO) + ISNULL(SUM(0), 0) AS [RM_TTL_PO]
                        FROM
                            qry_COMP_RM_DETAIL AS A
                        GROUP BY
                            A.SALES_CREDIT_RM_EMAIL,
                            A.[ROLE],
                            A.L1,
                            A.[CLOSE_YYYYMM],
                            A.[CLOSE_YYYYQQ]
                    ) AS x
                    LEFT JOIN (
                        SELECT
                            AD_EID,
                            [ROLE],
                            [CLOSE_YYYYMM],
                            [CLOSE_YYYYQQ],
                            SUM(AD_SALES) AD_SALES
                        FROM
                            qry_COMP_RM_DETAIL
                        GROUP BY
                            AD_EID,
                            [ROLE],
                            [CLOSE_YYYYMM],
                            [CLOSE_YYYYQQ]
                    ) AS Z ON x.SALES_CREDIT_RM_EMAIL = z.AD_EID
                    AND x.CLOSE_YYYYMM = z.CLOSE_YYYYMM
            )
            /*********************************************** 
             THIS IS THE DETAIL SUBQUERY END 
             ************************************************/
            AS T
        GROUP BY
            SALES_CREDIT_RM_EMAIL,
            [ROLE],
            [CLOSE_YYYYMM],
            [CLOSE_YYYYQQ]
            /****************************************************** 
             THIS IS THE AGGREGATE MONTHLY SALES BY RM END
             *******************************************************/
    ) AS A FULL
    JOIN qryGuarantee B ON A.SALES_CREDIT_RM_EMAIL = B.EMP_EMAIL
    AND A.ROLE = B.ROLE
    AND A.CLOSE_YYYYMM = B.YYYYMM
    LEFT JOIN qryRoster_RM C ON ISNULL(SALES_CREDIT_RM_EMAIL, B.EMP_EMAIL) = C.EMP_EMAIL
    LEFT JOIN qryRates_RM G ON a.SALES_CREDIT_RM_EMAIL = g.EID
    LEFT JOIN (
        SELECT
            SPIF_PO_YYYYMM,
            ISNULL(SUM(PO), 0) [PO],
            EMAIL
        FROM
            [dbo].[tblCPAS_PO]
        GROUP BY
            SPIF_PO_YYYYMM,
            EMAIL
    ) SP ON A.SALES_CREDIT_RM_EMAIL = SP.EMAIL
    AND SP.SPIF_PO_YYYYMM = ISNULL(A.[CLOSE_YYYYMM], B.[YYYYMM])
WHERE
    ISNULL(A.Role, B.ROLE) = 'RM'
    AND ISNULL(A.[CLOSE_YYYYMM], B.[YYYYMM]) = (
        SELECT
            YYYYMM
        FROM
            qryCalendar
        WHERE
            [DT] = CAST(DATEADD(mm, -1, GETDATE()) AS DATE)
    );


-- INSERT INTO
--     dbo.tblPayout
-- SELECT
--     [YYYYMM],
--     [SALES_CREDIT_RM_EMAIL] AS [EID],
--     YYYYQQ,
--     [ROLE],
--     'ACTIVE' AS [STATUS],
--     [VALUE],
--     [CATEGORY],
--     [NOTES]
-- FROM
--     (
--         SELECT
--             CAST(A.[SALES_CREDIT_RM_EMAIL] AS VARCHAR) AS [SALES_CREDIT_RM_EMAIL],
--             CAST(A.[NAME] AS VARCHAR) AS [NAME],
--             CAST(A.[ROLE] AS VARCHAR) AS [ROLE],
--             NULL AS [Notes],
--             CAST(A.[YYYYMM] AS VARCHAR) AS [YYYYMM],
--             CAST(A.[YYYYQQ] AS VARCHAR) AS [YYYYQQ],
--             CAST(A.[QTY] AS VARCHAR) AS [QTY],
--             CAST(A.[SALES] AS VARCHAR) AS [SALES],
--             CAST(A.[PO_FREQ] AS VARCHAR) AS [PO_FREQ],
--             CAST(A.[GUR_AMT] AS VARCHAR) AS [GUR_AMT],
--             CAST(A.[GUR_ADJ] AS VARCHAR) AS [GUR_ADJ],
--             CAST(A.[RM_L1_PO] AS VARCHAR) AS [RM_L1_PO],
--             CAST(A.[RM_L2_PO] AS VARCHAR) AS [RM_L2_PO],
--             CAST(A.[RM_L3_PO] AS VARCHAR) AS [RM_L3_PO],
--             CAST(A.[RM_L1_REV] AS VARCHAR) AS [RM_L1_REV],
--             CAST(A.[RM_L2_REV] AS VARCHAR) AS [RM_L2_REV],
--             CAST(A.[RM_L3_REV] AS VARCHAR) AS [RM_L3_REV],
--             CAST(A.AD_PO AS VARCHAR) AS [AD_PO],
--             CAST(A.[EARNED_MNTH_PO] AS VARCHAR) AS [EARNED_MNTH_PO],
--             CAST(A.[EARNED_QTD_PO] AS VARCHAR) AS [EARNED_QTD_PO],
--             CAST(A.[PO_AMT] AS VARCHAR) AS [PO_AMT],
--             CAST(A.[SPIFF_PO] AS VARCHAR) AS [SPIFF_PO]
--         FROM
--             dbo.tmpRM_PO A
--     ) P UNPIVOT(
--         [VALUE] FOR [CATEGORY] IN(
--             [QTY],
--             [SALES],
--             [PO_FREQ],
--             [GUR_AMT],
--             [GUR_ADJ],
--             [RM_L1_PO],
--             [RM_L2_PO],
--             [RM_L3_PO],
--             [AD_PO],
--             [RM_L1_REV],
--             [RM_L2_REV],
--             [RM_L3_REV],
--             [EARNED_MNTH_PO],
--             [EARNED_QTD_PO],
--             [PO_AMT],
--             [SPIFF_PO]
--         )
--     ) AS UNPV