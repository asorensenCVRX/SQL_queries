-- DO NOT OVERWRITE THIS FILE
/** THIS IS THE DETAIL SUBQUERY START **/
SELECT
    B.SALES_CREDIT_FCE_EMAIL,
    C.NAME_REP,
    B.SALES_CREDIT_REP_EMAIL,
    C.ROLE,
    C.DOH,
    B.CLOSEDATE,
    B.REGION,
    B.REGION_ID,
    ACCOUNT,
    PHYSICIAN,
    [isTarget?],
    b.[PO_%],
    ISNULL(B.PO_PER, 0) [PO_PER],
    ISNULL(CPAS.PO, 0) [CPAS_SPIFF_DEDUCTION],
    CASE
        WHEN [PO_%] > 0
        AND b.SALES_TGT > 0 THEN ([PO_%] * b.SALES_tgt) - ISNULL(cpas.PO, 0)
        ELSE ISNULL(B.PO_PER, 0) * ISNULL(B.IMPLANT_UNITS, 0) - ISNULL(cpas.PO, 0)
    END AS [TGT_PO],
    B.OPP_NAME,
    b.OPP_ID,
    IPG,
    B.CLOSE_YYYYMM,
    B.CLOSE_YYYYQQ,
    B.IMPLANTED_YYYYMM,
    B.IMPLANTED_YYYYQQ,
    ISNULL(B.QTY, 0) [QTY],
    ISNULL(B.SALES_base, 0) AS [SALES_BASE],
    ISNULL(B.SALES_TGT, 0) AS [SALES_TGT],
    -- add in sales for comp statements
    isnull(B.SALES_BASE, 0) + isnull(SALES_TGT, 0) AS [SALES],
    ----------------------------
    CASE
        WHEN C.[DOH] <= CLOSEDATE THEN 1
        ELSE 0
    END AS [isComp?],
    [TYPE]
FROM
    (
        /** B START **/
        SELECT
            ISNULL(T0.REP_EMAIL, T1.SALES_CREDIT_FCE_EMAIL) SALES_CREDIT_FCE_EMAIL,
            T0.STATUS,
            T1.SALES_CREDIT_REP_EMAIL,
            ISNULL(T0.REGION, T1.REGION) REGION,
            ISNULL(T0.REGION_ID, T1.REG_ID) REGION_ID,
            T1.OPP_ID,
            T1.OPP_NAME,
            t1.[Exclude?],
            IPG,
            ACT_ID,
            ACCOUNT,
            PHYSICIAN,
            T1.CLOSEDATE,
            ISNULL(T0.YYYYMM, T1.CLOSE_YYYYMM) CLOSE_YYYYMM,
            T1.CLOSE_YYYYQQ,
            t1.IMPLANTED_YYYYMM,
            t1.IMPLANTED_YYYYQQ,
            t1.IMPLANT_UNITS,
            T1.QTY,
            T1.SALES_BASE,
            T1.SALES_TGT,
            T1.ASP,
            [isTarget?],
            PO_PER,
            [PO_%],
            t1.[TYPE]
        FROM
            (
                /** T0 Start **/
                SELECT
                    A.REP_EMAIL,
                    A.NAME_REP,
                    A.DOT,
                    STATUS,
                    REGION_ID,
                    region,
                    (
                        SELECT
                            YYYYMM
                        FROM
                            qryCalendar
                        WHERE
                            [DT] = CAST(DATEADD(mm, -1, GETDATE()) AS DATE)
                    ) AS [YYYYMM]
                FROM
                    qryRoster A
                WHERE
                    ROLE = 'FCE'
                    AND (
                        CASE
                            WHEN (
                                SELECT
                                    YYYYMM
                                FROM
                                    qryCalendar
                                WHERE
                                    [DT] = CAST(DATEADD(mm, -1, GETDATE()) AS DATE)
                            ) BETWEEN ACTIVE_YYYYMM
                            AND ISNULL(DOT_YYYYMM, '2199_12') THEN 1
                            ELSE 0
                        END
                    ) = 1
                    /** T0 END **/
            ) AS T0 FULL
            JOIN (
                /** T1 START **/
                SELECT
                    T1.SALES_CREDIT_FCE_EMAIL,
                    T1.SALES_CREDIT_REP_EMAIL,
                    T1.REGION,
                    T1.REG_ID,
                    T1.OPP_ID,
                    T1.OPP_NAME,
                    T1.ACT_ID,
                    T1.[isTarget?],
                    T1.PO_PER,
                    T1.[PO_%],
                    T1.IPG,
                    T1.ACCOUNT,
                    t1.PHYSICIAN,
                    t1.PHYSICIAN_ID,
                    T1.SHIPPINGSTATECODE,
                    T1.CLOSEDATE,
                    T1.CLOSE_YYYYMM,
                    T1.CLOSE_YYYYQQ,
                    t1.IMPLANTED_YYYYMM,
                    t1.IMPLANTED_YYYYQQ,
                    t1.IMPLANT_UNITS,
                    T1.QTY,
                    T1.SALES_BASE,
                    t1.SALES_TGT,
                    T1.ASP,
                    T1.[Exclude?],
                    T1.TYPE,
                    COUNT(*) OVER (PARTITION BY t1.OPP_NAME) [COUNTER]
                FROM
                    (
                        /** ACCT ALIGNMENT START**/
                        SELECT
                            A.REGION,
                            A.REG_ID,
                            B.EMAIL [SALES_CREDIT_FCE_EMAIL],
                            A.SALES_CREDIT_REP_EMAIL,
                            A.OPP_ID,
                            A.OPP_NAME,
                            A.ACT_ID,
                            1 AS [isTarget?],
                            b.PO_PER,
                            b.[PO_%],
                            IPG,
                            ACCOUNT,
                            A.PHYSICIAN,
                            A.PHYSICIAN_ID,
                            A.SHIPPINGSTATECODE,
                            CLOSEDATE,
                            CLOSE_YYYYMM,
                            CLOSE_YYYYQQ,
                            IMPLANTED_YYYYMM,
                            IMPLANTED_YYYYQQ,
                            IMPLANT_UNITS,
                            QTY,
                            0 AS [SALES_BASE],
                            ISNULL(SALES, 0) [SALES_TGT],
                            ASP,
                            CASE
                                WHEN C.EMAIL IS NOT NULL THEN 1
                                ELSE 0
                            END AS [Exclude?],
                            'ACCT' AS [TYPE]
                        FROM
                            (
                                SELECT
                                    UPPER(A.REGION) [REGION],
                                    A.REG_ID,
                                    A.SALES_CREDIT_REP_EMAIL,
                                    A.OPP_ID,
                                    ACCOUNT_INDICATION__C [ACCOUNT],
                                    A.ACT_ID,
                                    A.PHYSICIAN,
                                    A.PHYSICIAN_ID,
                                    PATIENT_IPG_SERIAL_NUMBER__C [IPG],
                                    A.SHIPPINGSTATECODE,
                                    A.SHIPPINGCITY,
                                    INDICATION_FOR_USE__C,
                                    REASON_FOR_IMPLANT__C,
                                    CLOSEDATE,
                                    CLOSE_YYYYMM,
                                    NAME OPP_NAME,
                                    CLOSE_YYYYQQ,
                                    IMPLANTED_YYYYMM,
                                    IMPLANTED_YYYYQQ,
                                    IMPLANT_UNITS,
                                    TOTALOPPORTUNITYQUANTITY AS [QTY],
                                    SALES,
                                    [ASP]
                                FROM
                                    qryOpps A
                                WHERE
                                    IMPLANTED_YYYY = '2024'
                                    AND OPP_COUNTRY = 'US'
                                    AND RECORD_TYPE = 'Procedure - North America'
                                    AND INDICATION_FOR_USE__C = 'Heart Failure - Reduced Ejection Fraction'
                                    AND REASON_FOR_IMPLANT__C IN ('De novo')
                                    AND STAGENAME IN ('Implant Completed', 'Revenue Recognized')
                                    AND IMPLANTED_YYYYMM <= (
                                        SELECT
                                            YYYYMM
                                        FROM
                                            qryCalendar
                                        WHERE
                                            [DT] = CAST(DATEADD(mm, -1, GETDATE()) AS DATE)
                                    )
                            ) AS A
                            LEFT JOIN qryAlign_FCE B ON A.ACT_ID = B.[KEY]
                            AND B.TYPE = 'ACCT'
                            AND A.IMPLANTED_YYYYMM BETWEEN b.ACTIVE_YYYYMM
                            AND B.DOT_YYYYMM
                            LEFT JOIN tblOppEx C ON A.OPP_NAME = C.OPP_NAME
                            AND b.EMAIL = C.EMAIL
                        WHERE
                            B.EMAIL IS NOT NULL
                            AND ISNULL(A.PHYSICIAN_ID, 0) NOT IN (
                                SELECT
                                    B3.[KEY]
                                FROM
                                    qryAlign_FCE B3
                                WHERE
                                    B3.TYPE = 'DOC'
                                    AND B3.EMAIL = B.EMAIL
                                    AND a.IMPLANTED_YYYYMM >= B3.ACTIVE_YYYYMM
                            )
                            /** ACCT ALIGNMENT END**/
                        UNION
                        ALL
                        /** DOC ALIGNMENT START **/
                        SELECT
                            UPPER(A.REGION) [REGION],
                            A.REG_ID,
                            B.EMAIL [SALES_CREDIT_FCE_EMAIL],
                            A.SALES_CREDIT_REP_EMAIL,
                            A.OPP_ID,
                            A.OPP_NAME,
                            A.ACT_ID,
                            1 AS [isTarget?],
                            b.PO_PER,
                            b.[PO_%],
                            IPG,
                            ACCOUNT,
                            A.PHYSICIAN,
                            A.PHYSICIAN_ID,
                            A.SHIPPINGSTATECODE,
                            CLOSEDATE,
                            CLOSE_YYYYMM,
                            CLOSE_YYYYQQ,
                            IMPLANTED_YYYYMM,
                            IMPLANTED_YYYYQQ,
                            IMPLANT_UNITS,
                            QTY,
                            0 AS [SALES_BASE],
                            ISNULL(SALES, 0) [SALES_TGT],
                            ASP,
                            CASE
                                WHEN C.EMAIL IS NOT NULL THEN 1
                                ELSE 0
                            END AS [Exclude?],
                            'DOC' AS [TYPE]
                        FROM
                            (
                                SELECT
                                    A.REGION,
                                    A.REG_ID,
                                    A.SALES_CREDIT_REP_EMAIL,
                                    A.OPP_ID,
                                    ACCOUNT_INDICATION__C [ACCOUNT],
                                    A.ACT_ID,
                                    A.PHYSICIAN,
                                    A.PHYSICIAN_ID,
                                    PATIENT_IPG_SERIAL_NUMBER__C [IPG],
                                    A.SHIPPINGSTATECODE,
                                    A.SHIPPINGCITY,
                                    INDICATION_FOR_USE__C,
                                    REASON_FOR_IMPLANT__C,
                                    CLOSEDATE,
                                    CLOSE_YYYYMM,
                                    NAME OPP_NAME,
                                    CLOSE_YYYYQQ,
                                    IMPLANTED_YYYYMM,
                                    IMPLANTED_YYYYQQ,
                                    IMPLANT_UNITS,
                                    TOTALOPPORTUNITYQUANTITY AS [QTY],
                                    SALES,
                                    [ASP]
                                FROM
                                    qryOpps A
                                WHERE
                                    IMPLANTED_YYYY = '2024'
                                    AND OPP_COUNTRY = 'US'
                                    AND RECORD_TYPE = 'Procedure - North America'
                                    AND INDICATION_FOR_USE__C = 'Heart Failure - Reduced Ejection Fraction'
                                    AND REASON_FOR_IMPLANT__C IN ('De novo')
                                    AND STAGENAME IN ('Implant Completed', 'Revenue Recognized')
                                    AND IMPLANTED_YYYYMM <= (
                                        SELECT
                                            YYYYMM
                                        FROM
                                            qryCalendar
                                        WHERE
                                            [DT] = CAST(DATEADD(mm, -1, GETDATE()) AS DATE)
                                    )
                            ) AS A
                            LEFT JOIN qryAlign_FCE B ON A.PHYSICIAN_ID = B.[KEY]
                            AND B.TYPE = 'DOC'
                            AND A.IMPLANTED_YYYYMM BETWEEN b.ACTIVE_YYYYMM
                            AND B.DOT_YYYYMM
                            LEFT JOIN tblOppEx C ON A.OPP_NAME = C.OPP_NAME
                            AND b.EMAIL = C.EMAIL
                        WHERE
                            B.EMAIL IS NOT NULL
                            /** DOC ALIGNMENT END **/
                        UNION
                        ALL
                        /** REGION ALIGNMENT START **/
                        SELECT
                            REGION,
                            REG_ID,
                            B.EMAIL [SALES_CREDIT_FCE_EMAIL],
                            A.SALES_CREDIT_REP_EMAIL,
                            A.OPP_ID,
                            A.OPP_NAME,
                            A.ACT_ID,
                            NULL AS [isTarget],
                            NULL AS [PO_PER],
                            NULL AS [PO_%],
                            IPG,
                            ACCOUNT,
                            A.PHYSICIAN,
                            A.PHYSICIAN_ID,
                            A.SHIPPINGSTATECODE,
                            A.CLOSEDATE,
                            A.CLOSE_YYYYMM,
                            A.CLOSE_YYYYQQ,
                            IMPLANTED_YYYYMM,
                            IMPLANTED_YYYYQQ,
                            IMPLANT_UNITS,
                            A.QTY,
                            ISNULL(SALES, 0) AS [SALES_BASE],
                            0 AS [SALES_TGT],
                            A.ASP,
                            CASE
                                WHEN C.EMAIL IS NOT NULL THEN 1
                                ELSE 0
                            END AS [Exclude?],
                            'REGION_HF' AS [TYPE]
                        FROM
                            (
                                SELECT
                                    A.REGION,
                                    A.REG_ID,
                                    A.SALES_CREDIT_REP_EMAIL,
                                    A.OPP_ID,
                                    ACCOUNT_INDICATION__C [ACCOUNT],
                                    A.ACT_ID,
                                    A.PHYSICIAN,
                                    A.PHYSICIAN_ID,
                                    PATIENT_IPG_SERIAL_NUMBER__C [IPG],
                                    A.SHIPPINGSTATECODE,
                                    A.SHIPPINGCITY,
                                    INDICATION_FOR_USE__C,
                                    REASON_FOR_IMPLANT__C,
                                    CLOSEDATE,
                                    CLOSE_YYYYMM,
                                    NAME OPP_NAME,
                                    CLOSE_YYYYQQ,
                                    IMPLANTED_YYYYMM,
                                    IMPLANTED_YYYYQQ,
                                    IMPLANT_UNITS,
                                    TOTALOPPORTUNITYQUANTITY AS [QTY],
                                    SALES,
                                    [ASP]
                                FROM
                                    qryRevRec A
                                WHERE
                                    CLOSE_YYYY = '2024'
                                    AND OPP_COUNTRY = 'US'
                                    AND SALES <> 0
                                    AND INDICATION_FOR_USE__C = 'Heart Failure - Reduced Ejection Fraction'
                                    AND REASON_FOR_IMPLANT__C IN ('De novo', 'Replacement')
                                    AND CLOSE_YYYYMM <= (
                                        SELECT
                                            YYYYMM
                                        FROM
                                            qryCalendar
                                        WHERE
                                            [DT] = CAST(DATEADD(mm, -1, GETDATE()) AS DATE)
                                    )
                            ) AS A
                            LEFT JOIN qryAlign_FCE B ON A.REG_ID = B.[KEY]
                            AND B.TYPE = 'REGION'
                            AND A.CLOSE_YYYYMM BETWEEN b.ACTIVE_YYYYMM
                            AND B.DOT_YYYYMM
                            LEFT JOIN tblOppEx C ON A.OPP_NAME = C.OPP_NAME
                            AND b.EMAIL = C.EMAIL
                        WHERE
                            B.EMAIL IS NOT NULL
                            /** REGIONAL HF END  **/
                        UNION
                        ALL
                        /** TERRITORY ALIGNMENT START **/
                        SELECT
                            REGION,
                            REG_ID,
                            B.EMAIL [SALES_CREDIT_FCE_EMAIL],
                            A.SALES_CREDIT_REP_EMAIL,
                            A.OPP_ID,
                            A.OPP_NAME,
                            A.ACT_ID,
                            NULL AS [isTarget],
                            NULL AS [PO_PER],
                            NULL AS [PO_%],
                            IPG,
                            ACCOUNT,
                            A.PHYSICIAN,
                            A.PHYSICIAN_ID,
                            A.SHIPPINGSTATECODE,
                            A.CLOSEDATE,
                            A.CLOSE_YYYYMM,
                            A.CLOSE_YYYYQQ,
                            IMPLANTED_YYYYMM,
                            IMPLANTED_YYYYQQ,
                            IMPLANT_UNITS,
                            A.QTY,
                            ISNULL(SALES, 0) AS [SALES_BASE],
                            0 AS [SALES_TGT],
                            A.ASP,
                            CASE
                                WHEN C.EMAIL IS NOT NULL THEN 1
                                ELSE 0
                            END AS [Exclude?],
                            'TERRITORY_HF' AS [TYPE]
                        FROM
                            (
                                SELECT
                                    A.REGION,
                                    A.REG_ID,
                                    A.SALES_CREDIT_REP_EMAIL,
                                    r.TERRITORY_ID,
                                    A.OPP_ID,
                                    ACCOUNT_INDICATION__C [ACCOUNT],
                                    A.ACT_ID,
                                    A.PHYSICIAN,
                                    A.PHYSICIAN_ID,
                                    PATIENT_IPG_SERIAL_NUMBER__C [IPG],
                                    A.SHIPPINGSTATECODE,
                                    A.SHIPPINGCITY,
                                    INDICATION_FOR_USE__C,
                                    REASON_FOR_IMPLANT__C,
                                    CLOSEDATE,
                                    CLOSE_YYYYMM,
                                    NAME OPP_NAME,
                                    CLOSE_YYYYQQ,
                                    IMPLANTED_YYYYMM,
                                    IMPLANTED_YYYYQQ,
                                    IMPLANT_UNITS,
                                    TOTALOPPORTUNITYQUANTITY AS [QTY],
                                    SALES,
                                    [ASP]
                                FROM
                                    qryRevRec A
                                    LEFT JOIN qryRoster R ON a.SALES_CREDIT_REP_EMAIL = r.REP_EMAIL
                                    AND R.[isLATEST?] = 1
                                WHERE
                                    CLOSE_YYYY = '2024'
                                    AND OPP_COUNTRY = 'US'
                                    AND SALES <> 0
                                    AND INDICATION_FOR_USE__C = 'Heart Failure - Reduced Ejection Fraction'
                                    AND REASON_FOR_IMPLANT__C IN ('De novo', 'Replacement')
                                    AND CLOSE_YYYYMM <= (
                                        SELECT
                                            YYYYMM
                                        FROM
                                            qryCalendar
                                        WHERE
                                            [DT] = CAST(DATEADD(mm, -1, GETDATE()) AS DATE)
                                    )
                            ) AS A
                            LEFT JOIN qryAlign_FCE B ON A.TERRITORY_ID = B.[KEY]
                            AND B.TYPE = 'TERR'
                            AND A.CLOSE_YYYYMM BETWEEN b.ACTIVE_YYYYMM
                            AND B.DOT_YYYYMM
                            LEFT JOIN tblOppEx C ON A.OPP_NAME = C.OPP_NAME
                            AND b.EMAIL = C.EMAIL
                        WHERE
                            B.EMAIL IS NOT NULL
                            /*territory align end*/
                    ) AS T1
            ) AS T1 ON t0.REP_EMAIL = t1.SALES_CREDIT_FCE_EMAIL
            AND t0.YYYYMM = t1.CLOSE_YYYYMM
            /** B END **/
    ) AS B
    LEFT JOIN qryRoster C ON B.SALES_CREDIT_FCE_EMAIL = C.REP_EMAIL
    /*ON B.SALES_CREDIT_FCE_EMAIL = D.FCE_EMAIL*/
    LEFT JOIN (
        SELECT
            B.OPP_ID,
            B.CASENUMBER,
            B.EMAIL,
            B.ROLE,
            0.00 AS PO,
            /*   B.PO, */
            B.PO_RECOUP_NQ,
            B.SPIF_PO_YYYYMM,
            B.NOTES,
            C.OPPORTUNITY__C
        FROM
            tblCPAS_PO B
            LEFT JOIN sfdcCase C ON B.CASENUMBER = c.CASENUMBER
    ) CPAS ON B.OPP_ID = CPAS.OPPORTUNITY__C
    AND b.SALES_CREDIT_FCE_EMAIL = cpas.EMAIL
WHERE
    C.ROLE = 'FCE'
    AND ISNULL(B.[Exclude?], 0) = 0;