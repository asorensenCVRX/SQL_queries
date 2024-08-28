/** 
 TO DO LIST 
 -- acccount for HF Replacement 
 
 SET UP VARIABLE FOR MONTH 
 SET UP MONTHLY APPEND
 **/
--IF OBJECT_ID(N'dbo.tmpRM_PO', N'U') IS NOT NULL
--    DROP TABLE dbo.tmpRM_PO;
--GO
SELECT
    ISNULL(SALES_CREDIT_RM_EMAIL, B.EMP_EMAIL) AS [SALES_CREDIT_RM_EMAIL],
    C.NAME,
    ISNULL(A.ROLE, B.ROLE) AS [ROLE],
    ISNULL(A.[CLOSE_YYYYMM], B.[YYYYMM]) AS [YYYYMM],
    ISNULL(A.CLOSE_YYYYQQ, B.YYYYQQ) AS [YYYYQQ],
    A.QTY_NEW,
    A.QTY_REPLC,
    A.SALES_NEW,
    --isnull( CASE
    --     WHEN SALES_CREDIT_RM_EMAIL = 'jheimsoth@cvrx.com' THEN SUM(A.SALES_NEW) OVER(PARTITION BY replace(ISNULL(SALES_CREDIT_RM_EMAIL, B.EMP_EMAIL), 'jgarner@Cvrx.Com', 'jheimsoth@cvrx.com')) - SALES_NEW
    --     WHEN SALES_CREDIT_RM_EMAIL = 'mbrown@cvrx.com' THEN SUM(A.SALES_NEW) OVER(PARTITION BY replace(ISNULL(SALES_CREDIT_RM_EMAIL, B.EMP_EMAIL), 'ccastillo@Cvrx.Com', 'mbrown@cvrx.com')) - SALES_NEW
    --     WHEN SALES_CREDIT_RM_EMAIL = 'pknight@cvrx.com' THEN SUM(A.SALES_NEW) OVER(PARTITION BY replace(ISNULL(SALES_CREDIT_RM_EMAIL, B.EMP_EMAIL), 'kdenton@Cvrx.Com', 'pknight@cvrx.com')) - SALES_NEW
    --     ELSE NULL
    -- END,0) AS [SALES_NEW_RM], 
    A.SALES_REPLC,
    A.AD_SALES,
    B.PO_FREQ,
    B.PO_AMT [GUR_AMT],
    A.RM_L1_PO,
    A.RM_L2_PO,
    A.RM_L3_PO,
    A.AD_PO,
    A.RM_L1_REV,
    A.RM_L2_REV,
    A.RM_L3_REV,
    A.PO_HF_REPLC,
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
        AND B.PO_AMT > ISNULL(RM_TTL_PO, 0) THEN B.PO_AMT
        ELSE A.RM_TTL_PO
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
            SUM(QTY_NEW) QTY_NEW,
            SUM(QTY_REPLC) QTY_REPLC,
            SUM(SALES_NEW) SALES_NEW,
            SUM(SALES_REPLC) SALES_REPLC,
            SUM(AD_SALES) AD_SALES,
            SUM(AD_PO) AD_PO,
            SUM(RM_L1_PO) [RM_L1_PO],
            SUM(RM_L2_PO) [RM_L2_PO],
            SUM(RM_L3_PO) [RM_L3_PO],
            SUM(RM_L1_REV) [RM_L1_REV],
            SUM(RM_L2_REV) [RM_L2_REV],
            SUM(RM_L3_REV) [RM_L3_REV],
            SUM([PO_HF_REPLC]) [PO_HF_REPLC],
            SUM([PO_HF_REPLC]) + SUM(RM_L1_PO) + SUM(RM_L2_PO) + SUM(RM_L3_PO) + ISNULL(SUM(AD_PO), 0) AS [RM_TTL_PO]
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
                            SUM(A.QTY_NEW) QTY_NEW,
                            SUM(A.QTY_REPLC) QTY_REPLC,
                            SUM(A.SALES_NEW) SALES_NEW,
                            SUM(A.SALES_REPLC) SALES_REPLC,
                            --SUM(A.AD_SALES) AD_SALES, 
                            SUM(A.RM_L1_PO) [RM_L1_PO],
                            SUM(A.RM_L2_PO) [RM_L2_PO],
                            SUM(A.RM_L3_PO) [RM_L3_PO],
                            SUM(A.RM_L1_REV) [RM_L1_REV],
                            SUM(A.RM_L2_REV) [RM_L2_REV],
                            SUM(A.RM_L3_REV) [RM_L3_REV],
                            SUM(A.[PO_HF_REPLC]) [PO_HF_REPLC],
                            SUM(A.[PO_HF_REPLC]) + SUM(A.RM_L1_PO) + SUM(A.RM_L2_PO) + SUM(A.RM_L3_PO) + ISNULL(SUM(0), 0) AS [RM_TTL_PO]
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


--between '2021_10' AND '2021_12'
----INSERT INTO dbo.tblPayout
--      SELECT [YYYYMM], 
--             [SALES_CREDIT_RM_EMAIL] AS [EID], 
--             YYYYQQ, 
--             [ROLE], 
--             'ACTIVE' AS [STATUS], 
--             [VALUE], 
--             [CATEGORY], 
--             [NOTES]
--      FROM
--      (
--          SELECT CAST(A.[SALES_CREDIT_RM_EMAIL] AS VARCHAR) AS [SALES_CREDIT_RM_EMAIL], 
--                 CAST(A.[NAME] AS VARCHAR) AS [NAME], 
--                 CAST(A.[ROLE] AS VARCHAR) AS [ROLE], 
--                 NULL AS [Notes], 
--                 CAST(A.[YYYYMM] AS VARCHAR) AS [YYYYMM], 
--                 CAST(A.[YYYYQQ] AS VARCHAR) AS [YYYYQQ], 
--                 CAST(A.[QTY_NEW] AS VARCHAR) AS [QTY_NEW], 
--                 CAST(A.[QTY_REPLC] AS VARCHAR) AS [QTY_REPLC], 
--                 CAST(A.[SALES_NEW] AS VARCHAR) AS [SALES_NEW], 
--                 CAST(A.[SALES_REPLC] AS VARCHAR) AS [SALES_REPLC], 
--                 CAST(A.[PO_FREQ] AS VARCHAR) AS [PO_FREQ], 
--                 CAST(A.[GUR_AMT] AS VARCHAR) AS [GUR_AMT], 
--                 CAST(A.[GUR_ADJ] AS VARCHAR) AS [GUR_ADJ], 
--                 CAST(A.[RM_L1_PO] AS VARCHAR) AS [RM_L1_PO], 
--                 CAST(A.[RM_L2_PO] AS VARCHAR) AS [RM_L2_PO], 
--		   CAST(A.[RM_L3_PO] AS VARCHAR) AS [RM_L3_PO], 
--                 CAST(A.[RM_L1_REV] AS VARCHAR) AS [RM_L1_REV], 
--                 CAST(A.[RM_L2_REV] AS VARCHAR) AS [RM_L2_REV], 
--		   CAST(A.[RM_L3_REV] AS VARCHAR) AS [RM_L3_REV], 
--                 CAST(A.[PO_HF_REPLC] AS VARCHAR) AS [PO_HF_REPLC], 
--                 CAST(A.AD_PO AS VARCHAR) AS [AD_PO], 
--                 CAST(A.[EARNED_MNTH_PO] AS VARCHAR) AS [EARNED_MNTH_PO], 
--                 CAST(A.[EARNED_QTD_PO] AS VARCHAR) AS [EARNED_QTD_PO], 
--                 CAST(A.[PO_AMT] AS VARCHAR) AS [PO_AMT]
--          FROM dbo.tmpRM_PO A
--      ) P UNPIVOT([VALUE] FOR [CATEGORY] IN([QTY_NEW], 
--                                            [QTY_REPLC], 
--                                            [SALES_NEW], 
--                                            [SALES_REPLC], 
--                                            [PO_FREQ], 
--                                            [GUR_AMT], 
--                                            [GUR_ADJ], 
--                                            [RM_L1_PO], 
--                                            [RM_L2_PO], 
--									  [RM_L3_PO], 
--									  [AD_PO],
--                                            [RM_L1_REV], 
--                                            [RM_L2_REV], 
--									  [RM_L3_REV],
--                                            [PO_HF_REPLC], 
--                                            [EARNED_MNTH_PO], 
--                                            [EARNED_QTD_PO], 
--                                            [PO_AMT])) AS UNPV