-- IF OBJECT_ID(N'dbo.tmpFCE_PO', N'U') IS NOT NULL DROP TABLE dbo.tmpFCE_PO
-- GO
SELECT
    ISNULL(A.SALES_CREDIT_FCE_EMAIL, B.EMP_EMAIL) AS [FCE_EMAIL],
    C.NAME_REP AS [NAME],
    c.REGION_NM,
    ISNULL(A.ROLE, B.ROLE) AS [ROLE],
    ISNULL(A.PAY_PERIOD, B.[YYYYMM]) AS [YYYYMM],
    (
        SELECT
            DISTINCT YYYYQQ
        FROM
            qrycalendar Q
        WHERE
            Q.YYYYMM = ISNULL(A.PAY_PERIOD, B.[YYYYMM])
    ) AS [YYYYQQ],
    isnull(M0.M0_QTY, 0) AS QTY,
    isnull(M0.M0_SALES, 0) AS SALES,
    YTD_TGT_IMPLANTS,
    A.[%_FY_QUOTA],
    isnull(A.YTD_BASE_BONUS_PAID, 0) + isnull(A.BASE_BONUS_PO, 0) AS YTD_BASE_BONUS_PAID,
    --A.FY_TGT_BONUS_PAID, 
    A.OTHER_PO,
    A.TGT_BONUS_PO,
    CPAS_SPIFF_DEDUCTION,
    ISNULL(sp.PO, 0) [CPAS_SPIFF_PO],
    A.BASE_BONUS_PO,
    (
        ISNULL(A.TGT_BONUS_PO + A.BASE_BONUS_PO, 0)
    ) + ISNULL(A.OTHER_PO, 0) AS FCE_TTL_PO,
    SALES AS FY_BASE_SALES,
    B.PO_FREQ,
    CAST(ROUND(B.PO_AMT, 2) AS MONEY) [GUR_AMT],
    --D.AMT AS [ADJUSTMENTS],
    CAST(
        ROUND(
            CASE
                WHEN PO_FREQ = 'M'
                AND B.PO_AMT > (
                    ISNULL(A.TGT_BONUS_PO + A.BASE_BONUS_PO, 0) + ISNULL(A.OTHER_PO, 0)
                ) THEN B.PO_AMT - (
                    ISNULL(A.TGT_BONUS_PO + A.BASE_BONUS_PO, 0) + ISNULL(A.OTHER_PO, 0)
                )
                ELSE 0
            END,
            2
        ) AS MONEY
    ) AS [GUR_ADJ],
    CAST(
        ROUND(
            CASE
                WHEN PO_FREQ = 'M'
                AND B.PO_AMT > (
                    ISNULL(A.TGT_BONUS_PO + A.BASE_BONUS_PO, 0) + ISNULL(A.OTHER_PO, 0)
                ) --+ ISNULL(D.AMT, 0)
                THEN B.PO_AMT
                ELSE(
                    ISNULL(A.TGT_BONUS_PO + A.BASE_BONUS_PO, 0) + ISNULL(A.OTHER_PO, 0)
                ) + ISNULL(sp.PO, 0) --+ ISNULL(D.AMT, 0)
            END,
            2
        ) AS MONEY
    ) AS [PO_AMT]
    /***** COMMENT OUT THIS *****/
    -- INTO dbo.tmpFCE_PO
    /**********/
FROM
    (
        /*** THIS IS THE GROUP BY AND PO SUBQUERY START **/
        SELECT
            (
                SELECT
                    YYYYMM
                FROM
                    qryCalendar
                WHERE
                    [DT] = CAST(DATEADD(mm, -1, GETDATE()) AS DATE)
            ) AS [PAY_PERIOD],
            C1.SALES_CREDIT_FCE_EMAIL,
            C1.NAME_REP,
            C1.ROLE,
            C2.BASE_BONUS [BASE_BONUS],
            C2.TGT_BONUS,
            c1.TGT_PO - ISNULL(
                (
                    SELECT
                        SUM(CAST([VALUE] AS MONEY))
                    FROM
                        [dbo].[qryPayout_ADJ] A
                    WHERE
                        ROLE = 'FCE'
                        AND CATEGORY = 'TGT_BONUS_PO'
                        AND YYYYMM < (
                            SELECT
                                YYYYMM
                            FROM
                                qryCalendar
                            WHERE
                                [DT] = CAST(DATEADD(mm, -1, GETDATE()) AS DATE)
                        )
                        AND c1.SALES_CREDIT_FCE_EMAIL = A.EID
                ),
                0
            ) [TGT_BONUS_PO],
            C2.BATwire_PO,
            C1.DOH,
            C1.QTY,
            YTD_TGT_IMPLANTS,
            C1.SALES,
            X.QUOTA,
            ROUND(ISNULL(C1.SALES / NULLIF(X.QUOTA, 0), 0), 3) * 100 AS [%_FY_QUOTA],
            CAST(
                ISNULL(C1.SALES / NULLIF(X.QUOTA, 0), 0) * (C2.BASE_BONUS) AS MONEY
            ) AS [FY_BASE_BONUS_EARNED],
            ISNULL(
                (
                    SELECT
                        SUM(CAST([VALUE] AS MONEY))
                    FROM
                        [dbo].[qryPayout_ADJ] A
                    WHERE
                        ROLE = 'FCE'
                        AND CATEGORY = 'BASE_BONUS_PO'
                        AND YYYYMM < (
                            SELECT
                                YYYYMM
                            FROM
                                qryCalendar
                            WHERE
                                [DT] = CAST(DATEADD(mm, -1, GETDATE()) AS DATE)
                        )
                        AND c1.SALES_CREDIT_FCE_EMAIL = A.EID
                ),
                0
            ) AS [YTD_BASE_BONUS_PAID],
            cast(
                /* calculate their payments off only Q4 sales minus Q4 payouts for previous Q4 months */
                (C1.Q4_SALES / nullif(X.QUOTA, 0)) * C2.BASE_BONUS AS money
            ) - isnull(
                (
                    SELECT
                        SUM(CAST([VALUE] AS MONEY))
                    FROM
                        [dbo].[qryPayout_ADJ] A
                    WHERE
                        ROLE = 'FCE'
                        AND CATEGORY = 'BASE_BONUS_PO'
                        AND YYYYMM < (
                            SELECT
                                YYYYMM
                            FROM
                                qryCalendar
                            WHERE
                                [DT] = CAST(DATEADD(mm, -1, GETDATE()) AS DATE)
                        )
                        AND YYYYMM >= '2024_10'
                        AND c1.SALES_CREDIT_FCE_EMAIL = a.eid
                ),
                0
            ) AS [BASE_BONUS_PO],
            ISNULL(
                (
                    SELECT
                        SUM(CAST([VALUE] AS MONEY))
                    FROM
                        [dbo].[qryPayout_ADJ] A
                    WHERE
                        ROLE = 'FCE'
                        AND CATEGORY = 'TGT_BONUS_PO'
                        AND YYYYMM < (
                            SELECT
                                YYYYMM
                            FROM
                                qryCalendar
                            WHERE
                                [DT] = CAST(DATEADD(mm, -1, GETDATE()) AS DATE)
                        )
                        AND c1.SALES_CREDIT_FCE_EMAIL = A.EID
                ),
                0
            ) AS [TGT_BONUS_PAID],
            -- c3.PO_PER [TGT_BONUS_PO], 
            OTHER_PO,
            [CPAS_SPIFF_DEDUCTION]
        FROM
            (
                SELECT
                    [SALES_CREDIT_FCE_EMAIL],
                    [NAME_REP],
                    [ROLE],
                    DOH,
                    ISNULL(SUM([QTY]), 0) [QTY],
                    ISNULL(SUM([SALES_BASE]), 0) [SALES],
                    SUM(
                        CASE
                            WHEN CLOSE_YYYYMM BETWEEN '2024_10'
                            AND '2024_12' THEN SALES_BASE
                        END
                    ) AS Q4_SALES,
                    ISNULL(SUM([isTarget?]), 0) [YTD_TGT_IMPLANTS],
                    SUM(PO_PER) [PO_PER],
                    SUM(TGT_PO) [TGT_PO],
                    SUM(CPAS_SPIFF_DEDUCTION) [CPAS_SPIFF_DEDUCTION],
                    0 OTHER_PO --SUM(CM_AUX_PO) OTHER_PO
                FROM
                    qry_COMP_FCE_DETAIL AS T
                WHERE
                    SALES_CREDIT_FCE_EMAIL IN (
                        SELECT
                            REP_EMAIL
                        FROM
                            qryRoster
                        WHERE
                            [isLATEST?] = 1
                            AND [ROLE] = 'FCE'
                    )
                GROUP BY
                    [SALES_CREDIT_FCE_EMAIL],
                    [NAME_REP],
                    [ROLE],
                    DOH
            ) AS C1
            LEFT JOIN tblFCE_COMP C2 ON c1.SALES_CREDIT_FCE_EMAIL = c2.FCE_EMAIL
            LEFT JOIN (
                SELECT
                    A.*,
                    B.QUOTA
                FROM
                    [dbo].[tblFCE_COMP] A
                    LEFT JOIN (
                        SELECT
                            A.EMAIL,
                            A.ACTIVE_YYYYMM,
                            A.DOT_YYYYMM,
                            SUM(QUOTA) [QUOTA]
                        FROM
                            (
                                SELECT
                                    A.EMAIL,
                                    A.ACTIVE_YYYYMM,
                                    A.DOT_YYYYMM,
                                    ISNULL(
                                        R.Quota,
                                        y.QUOTA_FY
                                    ) QUOTA
                                FROM
                                    qryAlign_FCE A
                                    LEFT JOIN tblRates_RM R ON R.REGION_ID = A.[KEY]
                                    LEFT JOIN qryRates_AM Y ON a.[KEY] = Y.TERR_ID
                                WHERE
                                    [TYPE] IN('REGION', 'TERR')
                            ) AS A
                        GROUP BY
                            A.EMAIL,
                            A.ACTIVE_YYYYMM,
                            A.DOT_YYYYMM
                    ) AS B ON a.FCE_EMAIL = b.EMAIL
            ) AS X ON c1.SALES_CREDIT_FCE_EMAIL = x.FCE_EMAIL
            /** THIS IS THE DETAILED GROUP BY AND PO SUBQUERY END **/
    ) AS A
    LEFT JOIN qryGuarantee B ON A.SALES_CREDIT_FCE_EMAIL = B.EMP_EMAIL
    AND A.ROLE = B.ROLE
    AND A.PAY_PERIOD = B.YYYYMM
    LEFT JOIN qryRoster C ON ISNULL(A.SALES_CREDIT_FCE_EMAIL, B.EMP_EMAIL) = C.REP_EMAIL
    AND C.ROLE = 'FCE'
    AND [isLATEST?] = 1
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
    ) AS SP ON ISNULL(A.SALES_CREDIT_FCE_EMAIL, B.EMP_EMAIL) = SP.EMAIL
    AND sp.SPIF_PO_YYYYMM = ISNULL(A.PAY_PERIOD, B.[YYYYMM])
    LEFT JOIN (
        SELECT
            SALES_CREDIT_FCE_EMAIL,
            sum(SALES_BASE) AS M0_SALES,
            SUM(QTY) AS M0_QTY
        FROM
            qry_COMP_FCE_DETAIL
        WHERE
            CLOSE_YYYYMM = (
                SELECT
                    YYYYMM
                FROM
                    qryCalendar
                WHERE
                    [DT] = CAST(DATEADD(mm, -1, GETDATE()) AS DATE)
            )
        GROUP BY
            SALES_CREDIT_FCE_EMAIL
    ) AS M0 ON M0.SALES_CREDIT_FCE_EMAIL = ISNULL(A.SALES_CREDIT_FCE_EMAIL, B.EMP_EMAIL)
WHERE
    ISNULL(A.ROLE, B.ROLE) = 'FCE'
    AND ISNULL(A.SALES_CREDIT_FCE_EMAIL, B.EMP_EMAIL) IS NOT NULL
    AND ISNULL(c.DOT_YYYYMM, '2099_12') >= (
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
--     [FCE_EMAIL] AS [EID],
--     [YYYYQQ],
--     [ROLE],
--     'ACTIVE' AS [STATUS],
--     [VALUE],
--     [CATEGORY],
--     NULL AS [NOTES]
-- FROM
--     (
--         SELECT
--             CAST(A.FCE_EMAIL AS varchar(max)) AS FCE_EMAIL,
--             CAST(A.NAME AS varchar(max)) AS NAME,
--             CAST(A.ROLE AS varchar(max)) AS ROLE,
--             CAST(A.YYYYMM AS varchar(max)) AS YYYYMM,
--             CAST(A.YYYYQQ AS varchar(max)) AS YYYYQQ,
--             CAST(A.QTY AS varchar(max)) AS QTY,
--             CAST(CAST(A.SALES AS money) AS varchar(max)) AS SALES,
--             CAST(A.YTD_TGT_IMPLANTS AS varchar(max)) AS YTD_TGT_IMPLANTS,
--             CAST(A.[%_FY_QUOTA] AS varchar(max)) [%_FY_QUOTA],
--             --  CAST(a.[H2_%_TGT_QUOTA] as varchar(max)) [H2_%_TGT_QUOTA],
--             CAST(A.TGT_BONUS_PO AS varchar(max)) AS TGT_BONUS_PO,
--             CAST(A.BASE_BONUS_PO AS varchar(max)) AS BASE_BONUS_PAID,
--             --CAST(A.YTD_TGT_BONUS_PAID as varchar(max)) as H2_TGT_BONUS_PAID, 
--             CAST(A.BASE_BONUS_PO AS varchar(max)) AS BASE_BONUS_PO,
--             CAST(A.FCE_TTL_PO AS varchar(max)) AS FCE_TTL_PO,
--             --CAST(A.H2_TARGET_SALES as varchar(max)) as H2_TARGET_SALES,
--             CAST(CAST(A.FY_BASE_SALES AS money) AS varchar(max)) AS FY_BASE_SALES,
--             CAST(A.PO_FREQ AS varchar(max)) AS PO_FREQ,
--             CAST(A.GUR_AMT AS varchar(max)) AS GUR_AMT,
--             CAST(A.GUR_ADJ AS varchar(max)) AS GUR_ADJ,
--             CAST(A.PO_AMT AS varchar(max)) AS PO_AMT,
--             CAST(A.OTHER_PO AS varchar(max)) AS OTHER_PO,
--             cast(A.CPAS_SPIFF_PO AS varchar(max)) AS CPAS_SPIFF_PO,
--             cast(A.YTD_BASE_BONUS_PAID AS varchar(max)) AS YTD_BASE_BONUS_PAID
--         FROM
--             dbo.tmpFCE_PO A
--             /**************use to insert only specific people*********************/
--         -- WHERE
--         --     FCE_EMAIL IN ('vmonroe@cvrx.com')
--             /********************END********************/
--     ) P UNPIVOT (
--         [VALUE] FOR [CATEGORY] IN (
--             QTY,
--             SALES,
--             --[H2_%_TGT_QUOTA],
--             --H2_TGT_BONUS_PAID,
--             YTD_BASE_BONUS_PAID,
--             CPAS_SPIFF_PO,
--             TGT_BONUS_PO,
--             BASE_BONUS_PO,
--             FCE_TTL_PO,
--             YTD_TGT_IMPLANTS,
--             FY_BASE_SALES,
--             GUR_AMT,
--             GUR_ADJ,
--             PO_AMT
--         )
--     ) AS UNPVT;