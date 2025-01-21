IF OBJECT_ID(N'dbo.tmp_COMP_AM_DETAIL', N'U') IS NOT NULL DROP TABLE dbo.tmp_COMP_AM_DETAIL
GO
    /****************************** 
     THIS IS THE DETAIL SUBQUERY START
     *******************************/
SELECT
    [SALES_CREDIT_REP_EMAIL],
    [isSale?],
    [NAME_REP],
    [ROLE],
    [REGION_NM],
    [ISIMPL],
    [CLOSEDATE],
    [OPP_NAME],
    [OPP_ID],
    [REFERRAL COUNT],
    [ACT_NAME],
    [ACT_ID],
    [SPLIT],
    [SPLIT_ACT],
    [CLOSE_YYYYMM],
    [CLOSE_YYYYQQ],
    INDICATION_FOR_USE__C,
    REASON_FOR_IMPLANT__C,
    [ASP],
    [QTY],
    [QTD_UNITS],
    QTD_IMPLANTS,
    [SALES],
    /* add in flag that shows if the opp revenue is different from the invoice amt (denotes a rebate) */
    CASE
        WHEN OPP_ID IN (
            SELECT
                DISTINCT ID
            FROM
                sfdcOpps
            WHERE
                AMOUNT <> IMPLANT_REVENUE__C
                OR AMOUNT IS NULL
        )
        OR [SALES] < 0 THEN 1
        ELSE 0
    END AS [hasREBATE?],
    [QTD_SALES],
    [QTD_SALES - SALES],
    NULL AS [75xBL],
    [BL],
    Q4BL,
    [QUOTA],
    QUOTA_TIER,
    isnull([AM_L1_REV], 0) AS AM_L1_REV,
    isnull([AM_L2_REV], 0) AS AM_L2_REV,
    0.15 AS L1,
    0.25 AS L2,
    [PHYSICIAN],
    [PHYSICIAN_ID],
    CAST(isnull(M.AM_L1_REV, 0) * 0.15 AS MONEY) AS AM_L1_PO,
    isnull(
        CAST(
            CASE
                /* if QTD_IMPLANTS < 3 then return L2 rev * 0.15 */
                WHEN QTD_IMPLANTS < 3 THEN isnull(M.AM_L2_REV, 0) * 0.15
                /* once QTD_IMPLANTS hits 3, true-up past L2_rev so all L2 rev from dollar 1 is paid at 0.25 */
                WHEN (
                    (
                        QTD_IMPLANTS = 3
                        AND LAG(QTD_IMPLANTS) OVER (
                            PARTITION BY SALES_CREDIT_REP_EMAIL
                            ORDER BY
                                CLOSEDATE
                        ) IN (2, 2.5)
                    )
                    OR (
                        QTD_IMPLANTS = 3.5
                        AND LAG(QTD_IMPLANTS) OVER (
                            PARTITION BY SALES_CREDIT_REP_EMAIL
                            ORDER BY
                                CLOSEDATE
                        ) = 2.5
                    )
                ) THEN (
                    /* take all L2 revenue for the quarter (not including the current sale) and multiply by 0.25 */
                    SUM(isnull(M.AM_L2_REV, 0) * 0.25) OVER (
                        PARTITION BY SALES_CREDIT_REP_EMAIL
                        ORDER BY
                            CLOSEDATE ROWS BETWEEN UNBOUNDED PRECEDING
                            AND 1 PRECEDING
                    )
                    /* take all L2 revenue for the quarter (not including the current sale) and multiply by 0.15, then subtract this number 
                     (the amount being subtracted is the amount already paid) */
                    - SUM(isnull(M.AM_L2_REV, 0) * 0.15) OVER (
                        PARTITION BY SALES_CREDIT_REP_EMAIL
                        ORDER BY
                            CLOSEDATE ROWS BETWEEN UNBOUNDED PRECEDING
                            AND 1 PRECEDING
                    )
                )
                /* add in the PO for the current sale at 0.25 */
                + (M.AM_L2_REV * 0.25)
                /* when QTD_IMPLANTS > 3, return L2 rev * 0.25 */
                ELSE isnull(M.AM_L2_REV, 0) * 0.25
            END AS MONEY
        ),
        0
    ) AS AM_L2_PO,
    MAX(QTD_IMPLANTS) OVER (
        PARTITION BY SALES_CREDIT_REP_EMAIL,
        CLOSE_YYYYQQ
    ) AS TOTAL_Q0_IMPLANTS
    /***********/
    INTO tmp_COMP_AM_DETAIL
    /**********/
FROM
    (
        SELECT
            B.SALES_CREDIT_REP_EMAIL,
            CASE
                WHEN ISNULL(sales, 0) <> 0 THEN 1
                ELSE 0
            END AS [isSale?],
            C.NAME_REP,
            C.ROLE,
            C.REGION_NM,
            ISIMPL,
            B.CLOSEDATE,
            B.OPP_NAME,
            b.OPP_ID,
            B.[REFERRAL COUNT],
            B.ACT_NAME,
            b.ACT_ID,
            B.SPLIT,
            B.SPLIT_ACT,
            B.CLOSE_YYYYMM,
            B.CLOSE_YYYYQQ,
            INDICATION_FOR_USE__C,
            REASON_FOR_IMPLANT__C,
            B.ASP,
            ISNULL(B.QTY, 0) [QTY],
            ISNULL(B.QTD_UNITS, 0) [QTD_UNITS],
            ISNULL(QTD_IMPLANTS, 0) [QTD_IMPLANTS],
            ISNULL(B.SALES, 0) SALES,
            B.QTD_SALES,
            ISNULL(QTD_SALES, 0) - ISNULL(SALES, 0) [QTD_SALES - SALES],
            u.BL,
            u.Q4BL,
            u.QUOTA,
            CASE
                /*Solve: if this sales is negative and we're still below baseline then sales  */
                WHEN ISNULL(sales, 0) < 0
                AND ISNULL(QTD_SALES, 0) <= u.Q4BL THEN SALES
                /*Solve: if were not currently above baseline then all Sales are in L1 still */
                WHEN ISNULL(QTD_SALES, 0) <= U.Q4BL THEN ISNULL(sales, 0)
                /*Solve:   if we were NOT already above Q4BL then return a portion/all of this sale up to Q4BL*/
                WHEN (ISNULL(QTD_SALES, 0) - ISNULL(sales, 0)) <= U.Q4BL THEN U.Q4BL - (ISNULL(QTD_SALES, 0) - ISNULL(sales, 0))
                ELSE 0
            END AS AM_L1_REV,
            CASE
                /*Solve: if this sales is negative and we're currently l2 and previously were in l2 then sales  */
                WHEN ISNULL(sales, 0) < 0
                AND ISNULL(QTD_SALES, 0) > u.[Q4BL]
                AND ISNULL(QTD_SALES, 0) - ISNULL(sales, 0) > u.[Q4BL] THEN sales
                /*Solve: if this sales is negative and we're no longer above baseline but we were before this line item then   */
                WHEN ISNULL(sales, 0) < 0
                AND ISNULL(QTD_SALES, 0) < u.[Q4BL]
                AND ISNULL(
                    QTD_SALES,
                    0
                ) - ISNULL(sales, 0) > u.[Q4BL] THEN (u.[Q4BL] - ISNULL(QTD_SALES, 0)) + ISNULL(sales, 0)
                /*Solve: if we're already passed quota before this record OR sales is still below Q4BL at this line then 0 sales get passed. */
                WHEN (ISNULL(QTD_SALES, 0)) <= u.[Q4BL]
                OR ISNULL(SALES, 0) = 0 THEN 0
                /*Solve: if we were already at/passed Baseline then sales */
                WHEN (ISNULL(QTD_SALES, 0) - ISNULL(sales, 0)) > u.[Q4BL]
                AND ISNULL(QTD_SALES, 0) >= u.[Q4BL] THEN sales
                /*Solve: if we are now at/passed Baseline and currently less than quota then take the sales over the baseline */
                WHEN ISNULL(QTD_SALES, 0) >= u.[Q4BL] THEN ISNULL(QTD_SALES, 0) - u.[Q4BL]
                ELSE NULL
            END [AM_L2_REV],
            d.L1A,
            d.L1B,
            d.L2,
            d.L3,
            D.QUOTA_TIER,
            PHYSICIAN,
            PHYSICIAN_ID
        FROM
            (
                /********
                 This is the Active AM to Sales Mesh so that payouts are calculated for all even 0 sales reps. 
                 ********/
                SELECT
                    ISNULL(T0.REP_EMAIL, T1.SALES_CREDIT_REP_EMAIL) SALES_CREDIT_REP_EMAIL,
                    T1.OPP_ID,
                    t1.ACT_NAME,
                    t1.ACT_ID,
                    t1.ISIMPL,
                    T1.CLOSEDATE,
                    ISNULL(T0.YYYYMM, T1.CLOSE_YYYYMM) CLOSE_YYYYMM,
                    T1.OPP_NAME,
                    T1.[isMDRTarget?],
                    T1.[REFERRAL COUNT],
                    ISNULL(T0.YYYYQQ, T1.CLOSE_YYYYQQ) CLOSE_YYYYQQ,
                    T1.QTY,
                    t1.PHYSICIAN,
                    t1.PHYSICIAN_ID,
                    T1.SALES,
                    T1.SPLIT,
                    t1.SPLIT_ACT,
                    t1.INDICATION_FOR_USE__C,
                    t1.REASON_FOR_IMPLANT__C,
                    T1.ASP,
                    T1.QTD_UNITS,
                    T1.QTD_SALES,
                    T1.QTD_IMPLANTS
                FROM
                    (
                        SELECT
                            A.REP_EMAIL,
                            A.NAME_REP,
                            A.DOT,
                            STATUS,
                            (
                                SELECT
                                    YYYYMM
                                FROM
                                    qryCalendar
                                WHERE
                                    [DT] = CAST(DATEADD(mm, - 1, GETDATE()) AS DATE)
                            ) AS [YYYYMM],
                            (
                                SELECT
                                    YYYYQQ
                                FROM
                                    qryCalendar
                                WHERE
                                    [DT] = CAST(DATEADD(mm, - 1, GETDATE()) AS DATE)
                            ) AS [YYYYQQ]
                        FROM
                            qryRoster A
                        WHERE
                            a.[isLATEST?] = 1
                            AND ROLE = 'REP'
                            AND (
                                CASE
                                    WHEN (
                                        SELECT
                                            YYYYMM
                                        FROM
                                            qryCalendar
                                        WHERE
                                            [DT] = CAST(DATEADD(mm, - 1, GETDATE()) AS DATE)
                                    ) BETWEEN DOH_YYYYMM
                                    AND ISNULL(DOT_YYYYMM, '2199_12') THEN 1
                                    ELSE 0
                                END
                            ) = 1
                    ) AS T0 FULL
                    JOIN (
                        /*t1 start*/
                        SELECT
                            ISNULL(
                                B.SALES_CREDIT_REP_EMAIL,
                                ISNULL(Z.REP_EMAIL, A.SALES_CREDIT_REP_EMAIL)
                            ) AS SALES_CREDIT_REP_EMAIL,
                            A.OPP_ID,
                            ACCOUNT_INDICATION__C AS [ACT_NAME],
                            A.ISIMPL,
                            A.ACT_ID,
                            A.PHYSICIAN,
                            a.PHYSICIAN_ID,
                            CLOSEDATE,
                            CLOSE_YYYYMM,
                            A.NAME OPP_NAME,
                            [isMDRTarget?],
                            [REFERRAL COUNT],
                            CLOSE_YYYYQQ,
                            INDICATION_FOR_USE__C,
                            REASON_FOR_IMPLANT__C,
                            ISNULL(B.SPLIT, ISNULL(Z.SPLIT, 1)) * TOTALOPPORTUNITYQUANTITY QTY,
                            CAST(
                                ISNULL(B.SPLIT, ISNULL(Z.SPLIT, 1)) * ISNULL(C.AMT, SALES) AS MONEY
                            ) SALES,
                            B.SPLIT,
                            Z.SPLIT SPLIT_ACT,
                            ISNULL(C.ASP, A.[ASP]) [ASP],
                            SUM(
                                ISNULL(B.SPLIT, ISNULL(Z.SPLIT, 1)) * TOTALOPPORTUNITYQUANTITY
                            ) OVER (
                                PARTITION BY ISNULL(
                                    B.SALES_CREDIT_REP_EMAIL,
                                    ISNULL(Z.REP_EMAIL, A.SALES_CREDIT_REP_EMAIL)
                                ),
                                CLOSE_YYYYQQ
                                ORDER BY
                                    CLOSEDATE,
                                    A.NAME
                            ) AS QTD_UNITS,
                            SUM(
                                ISNULL(B.SPLIT, ISNULL(Z.SPLIT, 1)) * ISNULL(C.AMT, SALES)
                            ) OVER (
                                PARTITION BY ISNULL(
                                    B.SALES_CREDIT_REP_EMAIL,
                                    ISNULL(Z.REP_EMAIL, A.SALES_CREDIT_REP_EMAIL)
                                ),
                                CLOSE_YYYYQQ
                                ORDER BY
                                    CLOSEDATE,
                                    A.NAME
                            ) AS QTD_SALES,
                            SUM(
                                IMPLANT_UNITS * ISNULL(B.SPLIT, ISNULL(Z.SPLIT, 1))
                            ) OVER (
                                PARTITION BY ISNULL(
                                    B.SALES_CREDIT_REP_EMAIL,
                                    ISNULL(Z.REP_EMAIL, A.SALES_CREDIT_REP_EMAIL)
                                ),
                                CLOSE_YYYYQQ
                                ORDER BY
                                    CLOSEDATE,
                                    A.NAME
                            ) AS QTD_IMPLANTS
                        FROM
                            qryRevRec A
                            LEFT JOIN tblSalesSplits B ON A.OPP_ID = B.OPP_ID
                            AND SPLIT IS NOT NULL
                            AND AMT IS NULL
                            LEFT JOIN tblActSplits Z ON A.ACT_ID = Z.ACT_ID
                            AND A.CLOSE_YYYYMM BETWEEN z.YYYYMM_ST
                            AND z.YYYYMM_END
                            LEFT JOIN tblSalesSplits C ON A.OPP_ID = C.OPP_ID
                            AND C.SALES_CREDIT_REP_EMAIL = 'OPP_ADJ'
                        WHERE
                            CLOSE_YYYYMM <= (
                                SELECT
                                    YYYYMM
                                FROM
                                    qryCalendar
                                WHERE
                                    [DT] = CAST(DATEADD(mm, - 1, GETDATE()) AS DATE)
                            )
                            AND CLOSE_YYYY >= '2022'
                            AND OPP_COUNTRY = 'US'
                            AND INDICATION_FOR_USE__C = 'Heart Failure - Reduced Ejection Fraction'
                            AND REASON_FOR_IMPLANT__C IN ('De novo', 'Replacement')
                            /* opp 006UY00000DP1uHYAT delayed due to Hurricane Helena, approval from RJ to pay as part of September comp */
                            AND A.OPP_ID <> '006UY00000DP1uHYAT'
                    ) AS T1 ON t0.REP_EMAIL = t1.SALES_CREDIT_REP_EMAIL
                    AND t0.YYYYMM = t1.CLOSE_YYYYMM
            ) AS B
            LEFT JOIN qryRoster C ON B.SALES_CREDIT_REP_EMAIL = C.REP_EMAIL
            AND C.ROLE = 'REP'
            LEFT JOIN qryRates_AM D ON B.SALES_CREDIT_REP_EMAIL = D.EID
            LEFT JOIN (
                SELECT
                    YYYYQQ,
                    EID,
                    sum(BASELINE) AS BL,
                    SUM(Q4BL) AS Q4BL,
                    SUM(QUOTA) AS QUOTA,
                    SUM(BASELINE) * 0.75 AS [75xBL]
                FROM
                    qryQuota_Monthly
                GROUP BY
                    YYYYQQ,
                    EID
            ) U ON B.SALES_CREDIT_REP_EMAIL = U.EID
            AND B.CLOSE_YYYYQQ = U.YYYYQQ
            LEFT JOIN (
                SELECT
                    B.OPP_ID,
                    B.CASENUMBER,
                    B.EMAIL,
                    B.ROLE,
                    B.PO,
                    B.PO_RECOUP_NQ,
                    B.SPIF_PO_YYYYMM,
                    B.NOTES,
                    C.OPPORTUNITY__C
                FROM
                    tblCPAS_PO B
                    LEFT JOIN sfdcCase C ON B.CASENUMBER = c.CASENUMBER
            ) CPAS ON B.OPP_ID = CPAS.OPPORTUNITY__C
            AND b.SALES_CREDIT_REP_EMAIL = cpas.EMAIL
    ) AS M
WHERE
    left(CLOSE_YYYYMM, 4) = '2024'