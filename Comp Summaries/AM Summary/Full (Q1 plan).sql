/** 
 TO DO LIST 
 !! FCE DEDUCTIONS !! 
 -- account for Splits (no splits for march )  
 -- account for MDR Fees... do this in March for Feb.. once MDR is fully built out 
 
 
 CAUTION: 
 -- QUARTERIZE THIS >> make sure that when AdventHealth Daytona and ORlando hit their $840K that the FCE Tax isnt taken from Clemmons/Wyatt retroactively.
 Remove Prior Paid witihn Period from those on Guarantee
 
 **/
--IF OBJECT_ID(N'dbo.tmpAM_PO', N'U') IS NOT NULL DROP TABLE dbo.tmpAM_PO
--GO
SELECT
    ISNULL(A.SALES_CREDIT_REP_EMAIL, B.EMP_EMAIL) AS [REP_EMAIL],
    C.NAME_REP AS [NAME],
    C.STATUS,
    ISNULL(A.ROLE, B.ROLE) AS [ROLE],
    ISNULL(A.[CLOSE_YYYYMM], B.[YYYYMM]) AS [YYYYMM],
    ISNULL(A.CLOSE_YYYYQQ, B.YYYYQQ) AS [YYYYQQ],
    A.QTY,
    A.SALES,
    A.AM_L1A_REV,
    A.AM_L1B_REV,
    A.AM_L2_REV,
    A.AM_L3_REV,
    A.AM_L1A_PO,
    A.AM_L1B_PO,
    A.AM_L2_PO,
    A.AM_L3_PO,
    ISNULL(A.REPLC_PO, 0) REPLC_PO,
    A.FCE_DEDUCTION,
    a.SPIFF_DEDUCTION,
    ISNULL(SP.PO, 0) [CPAS_SPIFF_PO],
    ISNULL(BAT.BAT_IMPLANT_PO, 0) BAT_IMPLANT_PO,
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
    ) AS [PO_AMT] --INTO dbo.tmpAM_PO
FROM
    (
        SELECT
            S.*,
            X.FCE_DEDUCTION,
            ISNULL([AM_L1A_PO], 0) + ISNULL([AM_L1B_PO], 0) + ISNULL([AM_L2_PO], 0) + ISNULL([AM_L3_PO], 0) + ISNULL(REPLC_PO, 0) - ISNULL(FCE_DEDUCTION, 0) - ISNULL(SPIFF_DEDUCTION, 0) AM_TTL_PO
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
                    ISNULL(SUM([AM_L1A_REV]), 0) [AM_L1A_REV],
                    ISNULL(SUM([AM_L1B_REV]), 0) [AM_L1B_REV],
                    ISNULL(SUM([AM_L2_REV]), 0) [AM_L2_REV],
                    ISNULL(SUM([AM_L3_REV]), 0) [AM_L3_REV],
                    ISNULL(SUM([AM_L1A_PO]), 0) [AM_L1A_PO],
                    ISNULL(SUM([AM_L1B_PO]), 0) [AM_L1B_PO],
                    ISNULL(SUM([AM_L2_PO]), 0) [AM_L2_PO],
                    ISNULL(SUM([AM_L3_PO]), 0) [AM_L3_PO],
                    ISNULL(SUM(REPLC_PO), 0) [REPLC_PO],
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
        GROUP BY
            SPIF_PO_YYYYMM,
            EMAIL
    ) SP ON ISNULL(A.SALES_CREDIT_REP_EMAIL, B.EMP_EMAIL) = SP.EMAIL
    AND sp.SPIF_PO_YYYYMM = ISNULL(A.[CLOSE_YYYYMM], B.[YYYYMM])
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
    AND LEFT(ISNULL(A.[CLOSE_YYYYMM], B.[YYYYMM]), 4) = '2024' --AND ISNULL(A.SALES_CREDIT_REP_EMAIL, B.EMP_EMAIL) <> 'ccastillo@cvrx.com'
ORDER BY
    ISNULL(A.SALES_CREDIT_REP_EMAIL, B.EMP_EMAIL),
    ISNULL(A.[CLOSE_YYYYMM], B.[YYYYMM]);


--	INSERT INTO dbo.tblPayout
--			 SELECT [YYYYMM], [REP_EMAIL] as [EID],YYYYQQ, [ROLE], [STATUS], [VALUE] , [CATEGORY], [Notes]
--		FROM 
--		 (
--SELECT 
--CAST(A.REP_EMAIL as varchar) as REP_EMAIL,
--CAST(A.NAME as varchar) as NAME,
--CAST(A.STATUS as varchar) as STATUS,
--CAST(A.ROLE as varchar) as ROLE,
--null as [Notes],
--CAST(A.YYYYMM as varchar) as YYYYMM,
--CAST(A.YYYYQQ as varchar) as YYYYQQ,
--CAST(A.QTY as varchar) as QTY,
--CAST(A.SALES as varchar) as SALES,
--CAST(A.AM_L1A_REV as varchar) as AM_L1A_REV,
--CAST(A.AM_L1B_REV as varchar) as AM_L1B_REV,
--CAST(A.AM_L2_REV as varchar) as AM_L2_REV,
--CAST(A.AM_L3_REV as varchar) as AM_L3_REV,
--CAST(A.AM_L1A_PO as varchar) as AM_L1A_PO,
--CAST(A.AM_L1B_PO as varchar) as AM_L1B_PO,
--CAST(A.AM_L2_PO as varchar) as AM_L2_PO,
--CAST(A.AM_L3_PO as varchar) as AM_L3_PO,
--CAST(A.REPLC_PO as varchar) as REPLC_PO,
--CAST(A.FCE_DEDUCTION as varchar) as FCE_DEDUCTION,
--CAST(A.AM_TTL_PO as varchar) as AM_TTL_PO,
--CAST(A.[SPIFF_DEDUCTION] as varchar) [SPIFF_DEDUCTION],
--      CAST(A.[CPAS_SPIFF_PO] as varchar) [CPAS_SPIFF_PO],
--      CAST(A.[BAT_IMPLANT_PO] as varchar) [BAT_IMPLANT_PO],
----CAST(A.AM_TTL_PO_QTD as varchar) as AM_TTL_PO_QTD,
--CAST(A.PO_FREQ as varchar) as PO_FREQ,
--CAST(A.GUR_AMT as varchar) as GUR_AMT,
--CAST(A.ADJUSTMENTS as varchar) as ADJUSTMENTS,
--CAST(A.GUR_ADJ as varchar) as GUR_ADJ,
--CAST(isnull(B.SI,0) as varchar) as TM_SI,
--CAST(A.PO_AMT + isnull(B.SI,0) as varchar) as PO_AMT
--FROM dbo.tmpAM_PO A
--left join (
--SELECT m.TM_EID [SALES_CREDIT_TM], 
--       [CLOSE_YYYYMM], 
--       [CLOSE_YYYYQQ], 
--	   O.TM_RATE,
--	     ISNULL(SUM([QTY]), 0) [QTY], 
--       ISNULL(SUM([SALES]), 0) [SALES], 
--	   ISNULL(SUM([SALES]), 0) * 	   O.TM_RATE as [SI]
--FROM qry_COMP_AM_DETAIL AS T
--     LEFT JOIN
--     tblRates_AM M
--     ON t.SALES_CREDIT_REP_EMAIL = M.EID
--	 LEFT JOIN
--     tblRates_AM O
--     ON m.TM_EID = O.EID
--WHERE M.TM_EID IS NOT NULL
--GROUP BY m.TM_EID, 
--         [CLOSE_YYYYMM], 
--         [CLOSE_YYYYQQ],
--		 O.TM_RATE ) as B 
--		 on a.REP_EMAIL = b.SALES_CREDIT_TM AND a.YYYYMM = b.CLOSE_YYYYMM
--) P 
--UNPIVOT 
--([VALUE] FOR [CATEGORY] IN 
--(
--       SALES, 
--       AM_L1A_REV, 
--	   AM_L1B_REV, 
--       AM_L2_REV, 
--       AM_L3_REV, 
--       AM_L1A_PO, 
--	   AM_L1B_PO, 
--       AM_L2_PO, 
--       AM_L3_PO, 
--	   REPLC_PO,
--       FCE_DEDUCTION, 
--	   TM_SI,
--       AM_TTL_PO, 
--        [SPIFF_DEDUCTION]
--      ,[CPAS_SPIFF_PO]
--      ,[BAT_IMPLANT_PO],
--       --PO_FREQ, 
--       GUR_AMT, 
--       ADJUSTMENTS, 
--       GUR_ADJ, 
--       PO_AMT,
--	   QTY
--)) as UNPVT