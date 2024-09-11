/** 
 TO DO LIST 
 !! FCE DEDUCTIONS !! 
 -- account for Splits (no splits for march )  
 -- account for MDR Fees... do this in March for Feb.. once MDR is fully built out 
 
 
 CAUTION: 
 -- QUARTERIZE THIS >> make sure that when AdventHealth Daytona and ORlando hit their $840K that the FCE Tax isnt taken from Clemmons/Wyatt retroactively.
 Remove Prior Paid witihn Period from those on Guarantee
 
 **/
-- IF OBJECT_ID(N'dbo.tmpAM_PO', N'U') IS NOT NULL DROP TABLE dbo.tmpAM_PO
-- GO
SELECT
       ISNULL(A.SALES_CREDIT_REP_EMAIL, B.EMP_EMAIL) AS [REP_EMAIL],
       C.NAME_REP AS [NAME],
       C.STATUS,
       ISNULL(A.ROLE, B.ROLE) AS [ROLE],
       ISNULL(A.[CLOSE_YYYYMM], B.[YYYYMM]) AS [YYYYMM],
       ISNULL(A.CLOSE_YYYYQQ, B.YYYYQQ) AS [YYYYQQ],
       A.QTY,
       A.SALES,
       A.AM_L1_REV,
       A.AM_L2_REV,
       A.AM_L1_PO,
       A.AM_L2_PO,
       A.FCE_DEDUCTION,
       a.SPIFF_DEDUCTION,
       ISNULL(SP.PO, 0) [CPAS_SPIFF_PO],
       ISNULL(SP2.PO, 0) [IMPLANT_SPIFF_PO],
       ISNULL(SP3.PO, 0) [BULK_SPIFF_PO],
       ISNULL(BAT.BAT_IMPLANT_PO, 0) + ISNULL(A.AM_TTL_PO, 0) [AM_TTL_PO],
       SUM(
              ISNULL(
                     ISNULL(BAT.BAT_IMPLANT_PO, 0) + ISNULL(A.AM_TTL_PO, 0),
                     0
              ) + ISNULL(D.AMT, 0)
       ) OVER(
              PARTITION BY ISNULL(A.SALES_CREDIT_REP_EMAIL, B.EMP_EMAIL),
              ISNULL(A.CLOSE_YYYYQQ, B.YYYYQQ)
              ORDER BY
                     ISNULL(A.SALES_CREDIT_REP_EMAIL, B.EMP_EMAIL),
                     ISNULL(A.[CLOSE_YYYYMM], B.[YYYYMM])
       ) AS [AM_TTL_PO_QTD],
       ISNULL(B.PO_FREQ, '') PO_FREQ,
       ISNULL(B.PO_AMT, 0) [GUR_AMT],
       ISNULL(D.AMT, 0) AS [ADJUSTMENTS],
       ISNULL(
              CASE
                     WHEN PO_FREQ = 'M'
                     AND B.PO_AMT > ISNULL(
                            ISNULL(BAT.BAT_IMPLANT_PO, 0) + ISNULL(A.AM_TTL_PO, 0),
                            0
                     ) + ISNULL(D.AMT, 0) THEN B.PO_AMT - (
                            ISNULL(
                                   ISNULL(BAT.BAT_IMPLANT_PO, 0) + ISNULL(A.AM_TTL_PO, 0),
                                   0
                            ) + ISNULL(D.AMT, 0)
                     )
                     ELSE 0
              END,
              0
       ) AS [GUR_ADJ],
       ISNULL(
              CASE
                     WHEN PO_FREQ = 'M'
                     AND B.PO_AMT > ISNULL(
                            ISNULL(BAT.BAT_IMPLANT_PO, 0) + ISNULL(A.AM_TTL_PO, 0),
                            0
                     ) + ISNULL(D.AMT, 0) THEN B.PO_AMT
                     ELSE ISNULL(BAT.BAT_IMPLANT_PO, 0) + ISNULL(A.AM_TTL_PO, 0) + ISNULL(D.AMT, 0) + ISNULL(SP.PO, 0)
              END,
              0
       ) + ISNULL(SP2.PO, 0) + ISNULL(SP3.PO, 0) AS [PO_AMT]
       /***** COMMENT OUT THIS *****/
       -- INTO dbo.tmpAM_PO
       /**********/
FROM
       (
              SELECT
                     S.*,
                     X.FCE_DEDUCTION,
                     ISNULL([AM_L1_PO], 0) + ISNULL([AM_L2_PO], 0) - ISNULL(FCE_DEDUCTION, 0) - ISNULL(SPIFF_DEDUCTION, 0) AM_TTL_PO
              FROM
                     (
                            SELECT
                                   [SALES_CREDIT_REP_EMAIL],
                                   [NAME_REP],
                                   [ROLE],
                                   [CLOSE_YYYYMM],
                                   [CLOSE_YYYYQQ],
                                   ISNULL(SUM([QTY]), 0) [QTY],
                                   ISNULL(SUM([SALES]), 0) [SALES],
                                   ISNULL(SUM([AM_L1_REV]), 0) [AM_L1_REV],
                                   ISNULL(SUM([AM_L2_REV]), 0) [AM_L2_REV],
                                   ISNULL(SUM([AM_L1_PO]), 0) [AM_L1_PO],
                                   ISNULL(SUM([AM_L2_PO]), 0) [AM_L2_PO],
                                   ISNULL(SUM(SPIFF_DEDUCTION), 0) AS [SPIFF_DEDUCTION]
                            FROM
                                   qry_COMP_AM_DETAIL AS T
                            GROUP BY
                                   [SALES_CREDIT_REP_EMAIL],
                                   [NAME_REP],
                                   [ROLE],
                                   [CLOSE_YYYYMM],
                                   [CLOSE_YYYYQQ]
                     ) AS S
                     LEFT JOIN (
                            SELECT
                                   SUM(A.TGT_PO) [FCE_DEDUCTION],
                                   ACT_OWNER_EMAIL,
                                   IMPLANTED_YYYYMM
                            FROM
                                   (
                                          SELECT
                                                 OPP_ID,
                                                 SUM(TGT_PO) [TGT_PO]
                                          FROM
                                                 [dbo].[qry_COMP_FCE_DETAIL]
                                          WHERE
                                                 TGT_PO > 0
                                          GROUP BY
                                                 OPP_ID
                                   ) AS A
                                   LEFT JOIN tmpOpps O ON a.OPP_ID = o.OPP_ID
                            GROUP BY
                                   ACT_OWNER_EMAIL,
                                   IMPLANTED_YYYYMM
                     ) X ON s.SALES_CREDIT_REP_EMAIL = x.ACT_OWNER_EMAIL
                     AND s.CLOSE_YYYYMM = x.IMPLANTED_YYYYMM
       ) AS A FULL
       JOIN qryGuarantee B ON A.SALES_CREDIT_REP_EMAIL = B.EMP_EMAIL
       AND A.ROLE = B.ROLE
       AND A.CLOSE_YYYYMM = B.YYYYMM
       LEFT JOIN qryRoster C ON ISNULL(A.SALES_CREDIT_REP_EMAIL, B.EMP_EMAIL) = C.REP_EMAIL
       AND A.CLOSE_YYYYMM BETWEEN C.DOH_YYYYMM
       AND ISNULL(C.DOT_YYYYMM, '2099_12')
       AND [isLATEST?] = 1
       AND C.[ROLE] = 'REP'
       LEFT JOIN tblSalesSplits D ON D.AMT IS NOT NULL
       AND D.SALES_CREDIT_REP_EMAIL <> 'OPP_ADJ'
       AND ISNULL(A.SALES_CREDIT_REP_EMAIL, B.EMP_EMAIL) = D.SALES_CREDIT_REP_EMAIL
       AND D.YYYYMM = ISNULL(A.[CLOSE_YYYYMM], B.[YYYYMM])
       LEFT JOIN (
              SELECT
                     AM_FOR_CREDIT_EMAIL OWNER_EMAIL,
                     IMPLANTED_YYYYMM Close_YYYYMM,
                     --SUM(IMPLANT_UNITS), 
                     SUM(IMPLANT_UNITS) * 3750 BAT_IMPLANT_PO
              FROM
                     [dbo].[qryOpps] A
              WHERE
                     A.REASON_FOR_IMPLANT__C = 'De Novo - BATwire'
                     AND ISIMPL = 1
                     AND IMPLANTED_YYYY = '2024'
              GROUP BY
                     AM_FOR_CREDIT_EMAIL,
                     IMPLANTED_YYYYMM
       ) AS BAT ON ISNULL(A.SALES_CREDIT_REP_EMAIL, B.EMP_EMAIL) = BAT.OWNER_EMAIL
       AND BAT.Close_YYYYMM = ISNULL(A.[CLOSE_YYYYMM], B.[YYYYMM])
       LEFT JOIN (
              SELECT
                     SPIF_PO_YYYYMM,
                     ISNULL(SUM(PO), 0) [PO],
                     EMAIL
              FROM
                     [dbo].[tblCPAS_PO]
              WHERE
                     SPIF_TYPE = 'CPAS'
              GROUP BY
                     SPIF_PO_YYYYMM,
                     EMAIL
       ) SP ON ISNULL(A.SALES_CREDIT_REP_EMAIL, B.EMP_EMAIL) = SP.EMAIL
       AND sp.SPIF_PO_YYYYMM = ISNULL(A.[CLOSE_YYYYMM], B.[YYYYMM])
       LEFT JOIN (
              SELECT
                     SPIF_PO_YYYYMM,
                     ISNULL(SUM(PO), 0) [PO],
                     EMAIL
              FROM
                     [dbo].[tblCPAS_PO]
              WHERE
                     SPIF_TYPE = 'IMPLANT'
              GROUP BY
                     SPIF_PO_YYYYMM,
                     EMAIL
       ) SP2 ON ISNULL(A.SALES_CREDIT_REP_EMAIL, B.EMP_EMAIL) = SP2.EMAIL
       AND sp2.SPIF_PO_YYYYMM = ISNULL(A.[CLOSE_YYYYMM], B.[YYYYMM])
       LEFT JOIN (
              SELECT
                     SPIF_PO_YYYYMM,
                     ISNULL(SUM(PO), 0) [PO],
                     EMAIL
              FROM
                     [dbo].[tblCPAS_PO]
              WHERE
                     SPIF_TYPE = 'BULK'
              GROUP BY
                     SPIF_PO_YYYYMM,
                     EMAIL
       ) SP3 ON ISNULL(A.SALES_CREDIT_REP_EMAIL, B.EMP_EMAIL) = SP3.EMAIL
       AND SP3.SPIF_PO_YYYYMM = ISNULL(A.CLOSE_YYYYMM, B.YYYYMM)
WHERE
       ISNULL(A.Role, B.ROLE) = 'REP'
       AND ISNULL(A.[CLOSE_YYYYMM], B.[YYYYMM]) = (
              SELECT
                     YYYYMM
              FROM
                     qryCalendar
              WHERE
                     [DT] = CAST(DATEADD(mm, -1, GETDATE()) AS DATE)
       )
       AND LEFT(ISNULL(A.[CLOSE_YYYYMM], B.[YYYYMM]), 4) = '2024'
ORDER BY
       ISNULL(A.SALES_CREDIT_REP_EMAIL, B.EMP_EMAIL),
       ISNULL(A.[CLOSE_YYYYMM], B.[YYYYMM]);


-- INSERT INTO
--        dbo.tblPayout
-- SELECT
--        [YYYYMM],
--        [REP_EMAIL] AS [EID],
--        YYYYQQ,
--        [ROLE],
--        [STATUS],
--        [VALUE],
--        [CATEGORY],
--        [Notes]
-- FROM
--        (
--               SELECT
--                      CAST(A.REP_EMAIL AS varchar) AS REP_EMAIL,
--                      CAST(A.NAME AS varchar) AS NAME,
--                      CAST(A.STATUS AS varchar) AS STATUS,
--                      CAST(A.ROLE AS varchar) AS ROLE,
--                      NULL AS [Notes],
--                      CAST(A.YYYYMM AS varchar) AS YYYYMM,
--                      CAST(A.YYYYQQ AS varchar) AS YYYYQQ,
--                      CAST(A.QTY AS varchar) AS QTY,
--                      CAST(A.SALES AS varchar) AS SALES,
--                      CAST(A.AM_L1_REV AS varchar) AS AM_L1_REV,
--                      CAST(A.AM_L2_REV AS varchar) AS AM_L2_REV,
--                      CAST(A.AM_L1_PO AS varchar) AS AM_L1_PO,
--                      CAST(A.AM_L2_PO AS varchar) AS AM_L2_PO,
--                      CAST(A.FCE_DEDUCTION AS varchar) AS FCE_DEDUCTION,
--                      CAST(A.AM_TTL_PO AS varchar) AS AM_TTL_PO,
--                      CAST(A.[CPAS_SPIFF_PO] AS varchar) [CPAS_SPIFF_PO],
--                      CAST(A.IMPLANT_SPIFF_PO AS VARCHAR) [IMPLANT_SPIFF_PO],
--                      CAST(A.BULK_SPIFF_PO AS VARCHAR) [BULK_SPIFF_PO],
--                      --CAST(A.AM_TTL_PO_QTD as varchar) as AM_TTL_PO_QTD,
--                      CAST(A.PO_FREQ AS varchar) AS PO_FREQ,
--                      CAST(A.GUR_AMT AS varchar) AS GUR_AMT,
--                      CAST(A.ADJUSTMENTS AS varchar) AS ADJUSTMENTS,
--                      CAST(A.GUR_ADJ AS varchar) AS GUR_ADJ,
--                      CAST(A.PO_AMT AS varchar) AS PO_AMT
--               FROM
--                      dbo.tmpAM_PO A
--                      LEFT JOIN (
--                             SELECT
--                                    m.TM_EID [SALES_CREDIT_TM],
--                                    [CLOSE_YYYYMM],
--                                    [CLOSE_YYYYQQ],
--                                    O.TM_RATE,
--                                    ISNULL(SUM([QTY]), 0) [QTY],
--                                    ISNULL(SUM([SALES]), 0) [SALES]
--                             FROM
--                                    qry_COMP_AM_DETAIL AS T
--                                    LEFT JOIN tblRates_AM M ON t.SALES_CREDIT_REP_EMAIL = M.EID
--                                    LEFT JOIN tblRates_AM O ON m.TM_EID = O.EID
--                             WHERE
--                                    M.TM_EID IS NOT NULL
--                             GROUP BY
--                                    m.TM_EID,
--                                    [CLOSE_YYYYMM],
--                                    [CLOSE_YYYYQQ],
--                                    O.TM_RATE
--                      ) AS B ON a.REP_EMAIL = b.SALES_CREDIT_TM
--                      AND a.YYYYMM = b.CLOSE_YYYYMM
--        ) P UNPIVOT (
--               [VALUE] FOR [CATEGORY] IN (
--                      SALES,
--                      AM_L1_REV,
--                      AM_L2_REV,
--                      AM_L1_PO,
--                      AM_L2_PO,
--                      FCE_DEDUCTION,
--                      AM_TTL_PO,
--                      [CPAS_SPIFF_PO],
--                      [IMPLANT_SPIFF_PO],
--                      [BULK_SPIFF_PO],
--                      --PO_FREQ, 
--                      GUR_AMT,
--                      ADJUSTMENTS,
--                      GUR_ADJ,
--                      PO_AMT,
--                      QTY
--               )
--        ) AS UNPVT