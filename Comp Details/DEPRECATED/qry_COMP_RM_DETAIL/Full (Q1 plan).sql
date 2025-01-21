/****************************** 
 THIS IS THE DETAIL SUBQUERY START
 *******************************/
SELECT
    CASE
        WHEN [SALES_CREDIT_RM_EMAIL] = 'jgarner@Cvrx.Com' THEN 'jheimsoth@cvrx.com'
        WHEN [SALES_CREDIT_RM_EMAIL] = 'ccastillo@Cvrx.Com' THEN 'mbrown@cvrx.com'
        WHEN [SALES_CREDIT_RM_EMAIL] = 'kdenton@Cvrx.Com' THEN 'pknight@cvrx.com'
        ELSE [SALES_CREDIT_RM_EMAIL]
    END AS [AD_EID],
    *,
    CASE
        WHEN [SALES_CREDIT_RM_EMAIL] <> (
            CASE
                WHEN [SALES_CREDIT_RM_EMAIL] = 'jgarner@Cvrx.Com' THEN 'jheimsoth@cvrx.com'
                WHEN [SALES_CREDIT_RM_EMAIL] = 'ccastillo@Cvrx.Com' THEN 'mbrown@cvrx.com'
                WHEN [SALES_CREDIT_RM_EMAIL] = 'kdenton@Cvrx.Com' THEN 'pknight@cvrx.com'
                ELSE [SALES_CREDIT_RM_EMAIL]
            END
        ) THEN SALES_NEW
        ELSE 0
    END AS [AD_SALES],
    RM_L1_REV * L1 [RM_L1_PO],
    RM_L2_REV * L2 [RM_L2_PO],
    RM_L3_REV * L3 [RM_L3_PO]
FROM
    (
        SELECT
            C.EMP_EMAIL AS [SALES_CREDIT_RM_EMAIL],
            C.ROLE,
            B.CLOSEDATE,
            [ACT_NAME],
            B.OPP_NAME,
            B.CLOSE_YYYYMM,
            B.CLOSE_YYYYQQ,
            B.QTY_NEW,
            B.QTY_REPLC,
            [SALES] AS SALES_NEW,
            B.SALES_REPLC,
            B.ASP,
            B.QTD_UNITS,
            B.QTD_SALES,
            /* START OF REVENUE BUCKETS*/
            CASE
                /*Solve: if this sales is negative and we're still below  baseline  then sales  */
                WHEN ISNULL(sales, 0) < 0
                AND ISNULL(QTD_SALES, 0) <= u.[BL] THEN SALES
                /*Solve: if this sales is negative and we're no longer above  baseline but we were before this line item then   */
                WHEN ISNULL(sales, 0) < 0
                AND ISNULL(
                    QTD_SALES,
                    0
                ) < u.[BL]
                AND ISNULL(QTD_SALES, 0) - ISNULL(sales, 0) > u.[BL] THEN (u.[bl] - ISNULL(QTD_SALES, 0)) + ISNULL(sales, 0)
                /*Solve: if were not currently above baseline then all Sales are in L1A still */
                WHEN ISNULL(QTD_SALES, 0) <= U.[BL] THEN ISNULL(sales, 0)
                /*Solve:   if we were NOT already above bl AND we are abovbaseline now then return a portion/all of this sale up to BL*/
                WHEN (ISNULL(QTD_SALES, 0) - ISNULL(sales, 0)) <= U.[BL] THEN U.[BL] - (ISNULL(QTD_SALES, 0) - ISNULL(sales, 0))
                ELSE 0
            END AS RM_L1_REV,
            CASE
                /*Solve: if this sales is negative and we're currently l2 and previously were in l2 then sales  */
                WHEN ISNULL(sales, 0) < 0
                AND ISNULL(QTD_SALES, 0) BETWEEN u.[BL]
                AND u.quota
                AND ISNULL(
                    QTD_SALES,
                    0
                ) - ISNULL(sales, 0) BETWEEN u.[BL]
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
            END [RM_L2_REV],
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
            END [RM_L3_REV],
            0.006 * SALES_REPLC AS [PO_HF_REPLC],
            D.L1,
            D.L2,
            D.L3
        FROM
            (
                /*TBL START*/
                SELECT
                    T1.SALES_CREDIT_REP_EMAIL,
                    ISNULL(t1.REGION, t0.REGION) AS REGION,
                    ISNULL(t1.REG_ID, t0.REG_ID) AS REG_ID,
                    ISNULL(T0.EMP_EMAIL, t1.SALES_CREDIT_RM) SALES_CREDIT_RM,
                    [ACT_NAME],
                    T1.OPP_ID,
                    ISNULL(T1.CLOSEDATE, MONTH_START_DATE) AS CLOSEDATE,
                    ISNULL(T1.CLOSE_YYYYMM, T0.YYYYMM) CLOSE_YYYYMM,
                    T1.OPP_NAME,
                    ISNULL(
                        T1.CLOSE_YYYYQQ,
                        YYYYQQ
                    ) AS CLOSE_YYYYQQ,
                    ISNULL(T1.QTY_NEW, 0) AS [QTY_NEW],
                    ISNULL(T1.QTY_REPLC, 0) AS [QTY_REPLC],
                    ISNULL(T1.SALES_NEW, 0) AS SALES,
                    ISNULL(T1.SALES_REPLC, 0) AS SALES_REPLC,
                    T1.ASP,
                    T1.QTD_UNITS,
                    T1.QTD_SALES
                FROM
                    (
                        /*********************************************** 
                         THIS IS THE Current Active Month/Roster Substrate START
                         ************************************************/
                        SELECT
                            A.EMP_EMAIL,
                            A.REGION,
                            A.TERRITORY_ID [REG_ID],
                            A.START_DT,
                            A.END_DT,
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
                            ) AS [YYYYQQ],
                            (
                                SELECT
                                    MONTH_START_DATE
                                FROM
                                    qryCalendar
                                WHERE
                                    [DT] = CAST(DATEADD(mm, - 1, GETDATE()) AS DATE)
                            ) AS [MONTH_START_DATE]
                        FROM
                            qryRoster_RM A
                        WHERE
                            (
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
                            /*********************************************** 
                             THIS IS THE Current Active Month/Roster Substrate END
                             ************************************************/
                    ) AS T0 FULL
                    JOIN (
                        SELECT
                            A.SALES_CREDIT_REP_EMAIL,
                            A.REGION,
                            A.REG_ID AS [REG_ID],
                            A.SALES_CREDIT_RM AS SALES_CREDIT_RM,
                            A.OPP_ID,
                            CLOSEDATE,
                            CLOSE_YYYYMM,
                            ACCOUNT_INDICATION__C AS [ACT_NAME],
                            NAME AS OPP_NAME,
                            CLOSE_YYYYQQ,
                            TOTALOPPORTUNITYQUANTITY_NEW AS QTY_NEW,
                            TOTALOPPORTUNITYQUANTITY_REPLC AS QTY_REPLC,
                            SALES_NEW,
                            SALES_REPLC,
                            A.[ASP],
                            SUM(TOTALOPPORTUNITYQUANTITY_NEW) OVER (
                                PARTITION BY A.SALES_CREDIT_RM,
                                CLOSE_YYYYQQ
                                ORDER BY
                                    CLOSEDATE,
                                    NAME
                            ) AS QTD_UNITS,
                            SUM(SALES_NEW) OVER (
                                PARTITION BY A.SALES_CREDIT_RM,
                                CLOSE_YYYYQQ
                                ORDER BY
                                    CLOSEDATE,
                                    NAME
                            ) AS QTD_SALES
                            /*   END) OVER (PARTitiON BY clOSE_YYYYQQ)  AS QTD_TEST*/
                        FROM
                            qryRevRec AS A
                        WHERE
                            CLOSE_YYYY = '2024'
                            AND OPP_COUNTRY = 'US'
                            AND INDICATION_FOR_USE__C = 'Heart Failure - Reduced Ejection Fraction'
                            AND SALES <> 0
                            AND CLOSE_YYYYMM <= (
                                SELECT
                                    YYYYMM
                                FROM
                                    qryCalendar
                                WHERE
                                    [DT] = CAST(DATEADD(mm, - 1, GETDATE()) AS DATE)
                            )
                            AND NAME NOT IN (
                                SELECT
                                    OPP_NAME
                                FROM
                                    tblOppEx
                                WHERE
                                    TYPE = 'RM_REMOVAL'
                            )
                            OR NAME IS NULL
                    ) AS T1 ON t0.EMP_EMAIL = t1.SALES_CREDIT_RM
                    AND t0.YYYYMM = t1.CLOSE_YYYYMM
            ) AS B
            LEFT JOIN qryRoster_RM C ON b.SALES_CREDIT_RM = c.EMP_EMAIL
            LEFT JOIN qryRates_RM D ON b.SALES_CREDIT_RM = d.EID
            LEFT JOIN qryRates_RM_BY_QTR U ON b.SALES_CREDIT_RM = U.EID
            AND U.YYYYQQ = b.CLOSE_YYYYQQ
    ) AS MM