/****************************** 
 THIS IS THE DETAIL SUBQUERY START
 *******************************/
SELECT
    M.*,
    M.AM_L1A_REV * M.L1A [AM_L1A_PO],
    M.AM_L1B_REV * M.L1B [AM_L1B_PO],
    M.AM_L2_REV * M.L2 [AM_L2_PO],
    M.AM_L3_REV * M.L3 [AM_L3_PO]
FROM
    (
        SELECT
            B.SALES_CREDIT_REP_EMAIL,
            CASE
                WHEN ISNULL(sales, 0) + ISNULL(sales_replc, 0) <> 0 THEN 1
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
            B.ASP,
            ISNULL(B.UNITS_REPLC, 0) UNITS_REPLC,
            ISNULL(B.SALES_REPLC, 0) SALES_REPLC,
            ISNULL(B.QTY, 0) [QTY],
            ISNULL(B.QTD_UNITS, 0) [QTD_UNITS],
            ISNULL(B.SALES, 0) SALES,
            B.QTD_SALES,
            ISNULL(QTD_SALES, 0) - ISNULL(SALES, 0) [QTD_SALES - SALES],
            U.[75xBL],
            u.BL,
            u.QUOTA,
            CASE
                /*Solve: if this sales is negative and we're still below 75% of baseline  then sales  */
                WHEN ISNULL(sales, 0) < 0
                AND ISNULL(QTD_SALES, 0) <= u.[75xBL] THEN SALES
                /*Solve: if this sales is negative and we're no longer above 75% of baseline but we were before this line item then   */
                WHEN ISNULL(sales, 0) < 0
                AND ISNULL(QTD_SALES, 0) < u.[75xBL]
                AND ISNULL(QTD_SALES, 0) - ISNULL(sales, 0) > u.[75xBL] THEN (u.[75xbl] - ISNULL(QTD_SALES, 0)) + ISNULL(sales, 0)
                /*Solve: if were not currently above 75% to baseline then all Sales are in L1A still */
                WHEN ISNULL(QTD_SALES, 0) <= U.[75xBL] THEN ISNULL(sales, 0)
                /*Solve:   if we were NOT already above 75% AND we are above 75% to baseline now then return a portion/all of this sale up to 75%BL*/
                WHEN (ISNULL(QTD_SALES, 0) - ISNULL(sales, 0)) <= U.[75xBL] THEN U.[75xBL] - (ISNULL(QTD_SALES, 0) - ISNULL(sales, 0))
                ELSE 0
            END AS AM_L1A_REV,
            /*Excel: Level 1 B =IF([QTD_$]>=BL,(0.25*BL),IF(AND([QTD_$]>0.75*BL,[QTD_$]<=BL),[QTD_$]-(0.75*BL),0))   */
            CASE
                /*Solve: if this sales is negative and we're currently l1b and previously were in l1b then sales  */
                WHEN ISNULL(sales, 0) < 0
                AND ISNULL(QTD_SALES, 0) BETWEEN u.[75xBL]
                AND u.BL
                AND ISNULL(QTD_SALES, 0) - ISNULL(sales, 0) BETWEEN u.[75xBL]
                AND u.BL THEN sales
                /*Solve: if this sales is negative and we're still above 75% of baseline but below 100% of baseline and were previously greater than baseline then calc qtd_sales less baseline  */
                WHEN ISNULL(
                    sales,
                    0
                ) < 0
                AND ISNULL(QTD_SALES, 0) >= u.[75xBL]
                AND ISNULL(QTD_SALES, 0) < u.BL
                AND ISNULL(QTD_SALES, 0) - ISNULL(sales, 0) > u.BL THEN ISNULL(QTD_SALES, 0) - u.BL
                /*Solve: if this sales is negative and we're no longer above 75% of baseline but we were before this line item then   */
                WHEN ISNULL(sales, 0) < 0
                AND ISNULL(QTD_SALES, 0) < u.[75xBL]
                AND ISNULL(QTD_SALES, 0) - ISNULL(sales, 0) > u.[75xBL] THEN (u.[75xbl] - ISNULL(QTD_SALES, 0)) + ISNULL(sales, 0)
                /*Solve: if we're already passed 100% of Baseline before this record OR sales is still below 75%BL at this line then 0 sales get passed.   */
                WHEN ISNULL(QTD_SALES, 0) - ISNULL(sales, 0) > u.BL
                OR (ISNULL(QTD_SALES, 0)) <= u.[75xBL]
                OR ISNULL(SALES, 0) = 0 THEN 0
                /*Solve: if were NOT already above 75% of Baseline before this record AND sales is now over basleine then [baseline] - [75% of baseline] (or 25% of BL) the etire bucket*/
                WHEN (
                    ISNULL(QTD_SALES, 0) - ISNULL(sales, 0)
                ) < u.[75xBL]
                AND (ISNULL(QTD_SALES, 0)) >= u.BL THEN u.BL - u.[75xBL]
                /*Solve: if were already above 75% of Baseline before this record AND sales are now over basleine then baseline less previous QTD Sales*/
                WHEN (
                    ISNULL(QTD_SALES, 0) - ISNULL(sales, 0)
                ) > u.[75xBL]
                AND (ISNULL(QTD_SALES, 0)) >= u.BL THEN u.BL - (ISNULL(QTD_SALES, 0) - ISNULL(sales, 0))
                /*Solve: if we were already at/passed 75% of Baseline and currently less than baseline then sales */
                WHEN (ISNULL(QTD_SALES, 0) - ISNULL(sales, 0)) > u.[75xbl]
                AND ISNULL(QTD_SALES, 0) >= u.[75xBL]
                AND (ISNULL(QTD_SALES, 0)) < u.bl THEN sales
                /*Solve: if we are now at/passed 75% of Baseline and currently less than 100% BL then take the sales over the 75%BL threshold */
                WHEN ISNULL(QTD_SALES, 0) >= u.[75xBL]
                AND (ISNULL(QTD_SALES, 0)) < u.BL THEN ISNULL(QTD_SALES, 0) - u.[75xBL]
                /*WHEN(ISNULL(QTD_SALES, 0) - ISNULL(sales, 0)) > u.[75xBL] THEN -777  -- 0 */
                ELSE NULL
            END [AM_L1B_REV],
            /* 75%BL > x <=  BL */
            CASE
                /*Solve: if this sales is negative and we're currently l2 and previously were in l2 then sales  */
                WHEN ISNULL(sales, 0) < 0
                AND ISNULL(QTD_SALES, 0) BETWEEN u.[BL]
                AND u.quota
                AND ISNULL(QTD_SALES, 0) - ISNULL(sales, 0) BETWEEN u.[BL]
                AND u.quota THEN sales
                /*Solve: if this sales is negative and we're still above baseline but below quota and were previously greater than quota then calc qtd_sales less quota  */
                WHEN ISNULL(sales, 0) < 0
                AND ISNULL(QTD_SALES, 0) >= u.[BL]
                AND ISNULL(QTD_SALES, 0) < u.quota
                AND ISNULL(QTD_SALES, 0) - ISNULL(sales, 0) > u.quota THEN ISNULL(QTD_SALES, 0) - u.QUOTA
                /*Solve: if this sales is negative and we're no longer above baseline but we were before this line item then   */
                WHEN ISNULL(sales, 0) < 0
                AND ISNULL(QTD_SALES, 0) < u.[BL]
                AND ISNULL(
                    QTD_SALES,
                    0
                ) - ISNULL(sales, 0) > u.[BL] THEN (u.[bl] - ISNULL(QTD_SALES, 0)) + ISNULL(sales, 0)
                /*Solve: if we're already passed quota before this record OR sales is still below BL at this line then 0 sales get passed. */
                WHEN ISNULL(QTD_SALES, 0) - ISNULL(sales, 0) > u.QUOTA
                OR (ISNULL(QTD_SALES, 0)) <= u.[BL]
                OR ISNULL(SALES, 0) = 0 THEN 0
                /*Solve: if were NOT already above 100% of Baseline before this record AND sales is now over quota then	quota - [baseline] */
                WHEN (ISNULL(QTD_SALES, 0) - ISNULL(sales, 0)) < u.[BL]
                AND (ISNULL(QTD_SALES, 0)) >= u.QUOTA THEN u.QUOTA - u.[BL]
                /*Solve: if were already above Baseline before this record AND sales are now over quota then quota less previous QTD Sales*/
                WHEN (ISNULL(QTD_SALES, 0) - ISNULL(sales, 0)) > u.[BL]
                AND (ISNULL(QTD_SALES, 0)) >= u.QUOTA THEN u.QUOTA - (ISNULL(QTD_SALES, 0) - ISNULL(sales, 0))
                /*Solve: if we were already at/passed Baseline and currently still less than quota then sales */
                WHEN (ISNULL(QTD_SALES, 0) - ISNULL(sales, 0)) > u.[bl]
                AND ISNULL(QTD_SALES, 0) >= u.[BL]
                AND (ISNULL(QTD_SALES, 0)) < u.QUOTA THEN sales
                /*Solve: if we are now at/passed Baseline and currently less than quota then take the sales over the baseline */
                WHEN ISNULL(QTD_SALES, 0) >= u.[BL]
                AND (ISNULL(QTD_SALES, 0)) < u.QUOTA THEN ISNULL(QTD_SALES, 0) - u.[BL]
                /*WHEN(ISNULL(QTD_SALES, 0) - ISNULL(sales, 0)) > u.[75xBL] THEN -777  -- 0 */
                ELSE NULL
            END [AM_L2_REV],
            CASE
                /*Solve: if this sales is negative and we're still above quota then ssales  */
                WHEN ISNULL(sales, 0) < 0
                AND ISNULL(QTD_SALES, 0) >= u.QUOTA THEN SALES
                /*Solve: if this sales is negative and we're no longer above quota but we were before this line item then calc quota less QTD sales  */
                WHEN ISNULL(sales, 0) < 0
                AND ISNULL(
                    QTD_SALES,
                    0
                ) < u.QUOTA
                AND ISNULL(QTD_SALES, 0) - ISNULL(sales, 0) > u.quota THEN (u.quota - ISNULL(QTD_SALES, 0)) + ISNULL(sales, 0)
                /* If you were not already less than quota AND you are currently above quota then sales less quota */
                WHEN (ISNULL(QTD_SALES, 0) - ISNULL(sales, 0)) < u.QUOTA
                AND (ISNULL(QTD_SALES, 0)) > u.QUOTA THEN ISNULL(QTD_SALES, 0) - u.QUOTA
                /* If current sales over quota AND you've reached quota then 	*/
                WHEN (ISNULL(QTD_SALES, 0)) > u.QUOTA THEN ISNULL(sales, 0)
                ELSE 0
            END [AM_L3_REV],
            d.L1A,
            d.L1B,
            d.L2,
            d.L3,
            /*  ISNULL(CPAS.PO, 0) [SPIFF_DEDUCTION], */
            0.00 AS [SPIFF_DEDUCTION],
            SALES_REPLC *.03 AS [REPLC_PO],
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
                    T1.ASP,
                    T1.QTD_UNITS,
                    T1.QTD_SALES,
                    T1.SALES_REPLC,
                    t1.UNITS_REPLC
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
                            0 AS SALES_REPLC,
                            0 AS UNITS_REPLC
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
                            AND REASON_FOR_IMPLANT__C = 'De Novo'
                        UNION
                        ALL
                        SELECT
                            ISNULL(Z.REP_EMAIL, A.SALES_CREDIT_REP_EMAIL) AS SALES_CREDIT_REP_EMAIL,
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
                            0 QTY,
                            0 SALES,
                            NULL AS SPLIT,
                            Z.SPLIT SPLIT_ACT,
                            A.[ASP],
                            0 AS QTD_UNITS,
                            0 AS QTD_SALES,
                            ISNULL(
                                Z.SPLIT,
                                1
                            ) * SALES_REPLC SALES_REPLC,
                            ISNULL(Z.SPLIT, 1) * TOTALOPPORTUNITYQUANTITY_REPLC AS UNITS_REPLC
                        FROM
                            qryRevRec A
                            LEFT JOIN tblActSplits Z ON A.ACT_ID = Z.ACT_ID
                            AND A.CLOSE_YYYYMM BETWEEN z.YYYYMM_ST
                            AND z.YYYYMM_END
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
                            AND SALES <> 0
                            AND REASON_FOR_IMPLANT__C = 'Replacement'
                            /*t1 end */
                    ) AS T1 ON t0.REP_EMAIL = t1.SALES_CREDIT_REP_EMAIL
                    AND t0.YYYYMM = t1.CLOSE_YYYYMM
            ) AS B
            LEFT JOIN qryRoster C ON B.SALES_CREDIT_REP_EMAIL = C.REP_EMAIL
            AND C.ROLE = 'REP'
            LEFT JOIN qryRates_AM D ON B.SALES_CREDIT_REP_EMAIL = D.EID
            LEFT JOIN qryRates_AM_BY_QTR U ON B.SALES_CREDIT_REP_EMAIL = U.EID
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
    ) AS M;