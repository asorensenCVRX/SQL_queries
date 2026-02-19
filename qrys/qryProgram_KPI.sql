-- CREATE VIEW qryProgram_KPI as 
/* ALL METRICS TRACK ONLY HEART FAILURE -- DE NOVO EXCEPT CONSISTENCY (tracks all HF implants including replacements) */
/* CTE A and B were written by Jake in the DataSet Excel file. */
/* CTE CM brings in the data for the consistency metric */
WITH A AS (
    SELECT
        M.STAGE,
        RANK() OVER(
            PARTITION BY REGION,
            REP
            ORDER BY
                [RankScore]
        ) [Analytics_Rank],
        N.[LEK Priority],
        REP_RANK,
        M.NAME,
        M.CITY_STATE,
        M.BEDS,
        M.GPO,
        M.IDN,
        M.IDN_CONTRACT,
        M.TU,
        M.PATIENTS_IN_FUNNEL,
        M.IMPLANTS_COMPLETED,
        /* removed the below lines because this data will be provided by Liam */
        -- M.HF_CLAIMS,
        -- M.CardioMEMS,
        -- M.LVAD,
        -- M.CRT_PROCEDURES,
        /******************/
        M.REIMBURSEMENT_QTILE,
        M.[MEDICARE_%],
        M.REP,
        M.REP_EMAIL,
        M.REGION,
        TERR_ID,
        M.[Definitive ID],
        M.PROVIDER_ID,
        M.ZIP_5,
        M.CBSA,
        M.RANKSCORE,
        M.SRC,
        m.ID,
        ACCOUNT_TIER
    FROM
        (
            /* this first part of the union query is bringing in accounts from SFDC */
            SELECT
                --'SFDC' AS [ACCOUNT_SRC], 
                CAST(C.DHC_ACCOUNT_ID__C AS VARCHAR) [Definitive ID],
                CAST(C.CMS_ID__C AS VARCHAR) AS [PROVIDER_ID],
                --       C.ID [SFDC_ID], 
                ISNULL(B.NAME_REP, e.NAME_REP) AS [REP],
                ISNULL(B.REP_EMAIL, E.REP_EMAIL) AS [REP_EMAIL],
                ISNULL(B.REGION, e.REGION) AS [REGION],
                E.TERR_ID,
                (c.cbsa + ' - ' + c.cbsa_name) [CBSA],
                C.NAME,
                c.id,
                CASE
                    WHEN STAGE_NEW__C = 'No Longer Pursuing' THEN 'Target'
                    WHEN isAIC = 1 THEN '4'
                    WHEN isAIC = 0
                    AND CONTRACTING__C = 'Contract Fully Executed' THEN '3'
                    WHEN isAIC = 0
                    AND VALUE_ANALYSIS_INITIATED__C = 'Complete' THEN '2'
                    WHEN isAIC = 0
                    AND (
                        (
                            ISNULL(VALUE_ANALYSIS_INITIATED__C, 'NA') <> 'Complete'
                            AND LEN(VALUE_ANALYSIS_INITIATED__C) <> 0
                        )
                        OR (
                            ISNULL(CONTRACTING__C, 'NA') <> 'Contract Fully Executed'
                            AND LEN(CONTRACTING__C) <> 0
                        )
                    ) THEN '1'
                    ELSE 'Target'
                END AS [STAGE],
                dbo.ConvertToTitleCase(C.SHIPPINGCITY) + ', ' + c.SHIPPINGSTATECODE [CITY_STATE],
                CAST(C.SHIPPINGPOSTALCODE AS VARCHAR) [ZIP_5],
                ISNULL(
                    CAST(D.[# of Staffed Beds] AS VARCHAR),
                    'Unknown'
                ) [BEDS],
                CASE
                    WHEN isAIC = 1 THEN 'AIC'
                    WHEN ISACU = 1 THEN 'ACU'
                    WHEN STAGE_NEW__C = 'In-Development (N-ACU)' THEN 'N-ACU'
                    ELSE NULL
                END [REP_RANK],
                D.GPO,
                D.IDN,
                D.IDN_CONTRACT,
                ISNULL(H.PATIENTS_IN_FUNNEL, 0) PATIENTS_IN_FUNNEL,
                C.TOTAL_RECOGNIZED_IMPLANT__C [IMPLANTS_COMPLETED],
                D.HF_CLAIMS,
                D.CRT_PROCEDURES,
                d.CardioMEMS,
                d.LVAD,
                --D.CRT_PROCEDURES_QTILE, 
                d.COST_TO_CHARGE_RATIO_QTILE [REIMBURSEMENT_QTILE],
                d.[MEDICARE_%],
                ISNULL(d.RankScore, 4000) [RANKSCORE],
                'SFDC' AS [SRC],
                TU,
                TRY_CAST(LEFT(C.Account_Tier__c, 1) AS INT) AS ACCOUNT_TIER
            FROM
                qryCust C
                LEFT JOIN qryCust_DHC d ON C.DHC_ACCOUNT_ID__C = CAST(d.[Definitive ID] AS VARCHAR)
                LEFT JOIN (
                    SELECT
                        DISTINCT *
                    FROM
                        qryZipAlign
                ) E ON c.SHIPPINGPOSTALCODE = E.ZIP_CODE
                LEFT JOIN (
                    SELECT
                        REP_EMAIL,
                        NAME_REP,
                        REGION
                    FROM
                        qryRoster
                    WHERE
                        [STATUS] = 'ACTIVE'
                        AND ROLE IN ('REP', 'FCE')
                    UNION
                    ALL
                    SELECT
                        EMP_EMAIL,
                        NAME,
                        REGION
                    FROM
                        qryRoster_RM
                ) B ON C.OWNER_EMAIL = B.REP_EMAIL
                /* PATIENTS IN FUNNEL METRIC */
                LEFT JOIN (
                    SELECT
                        ACT_ID,
                        COUNT(*) [PATIENTS_IN_FUNNEL]
                    FROM
                        [dbo].[qryOpps]
                    WHERE
                        INDICATION_FOR_USE__C = 'Heart Failure - Reduced Ejection Fraction'
                        AND REASON_FOR_IMPLANT__C = 'De novo'
                        AND RECORD_TYPE = 'Procedure - North America'
                        AND OPP_STATUS = 'OPEN'
                    GROUP BY
                        ACT_ID
                ) H ON c.ID = H.ACT_ID
                /**********************/
            WHERE
                C.SHIPPINGCOUNTRY = 'USA' --AND (ISACU = 1 OR d.HF_CLAIMS_QTILE > 2 OR d.IDN_CONTRACT = 'Y')
                AND (
                    ISACU = 1
                    OR ISNULL(d.HF_CLAIMS, 0) IS NOT NULL
                    OR d.IDN_CONTRACT = 'Y'
                )
            UNION
            ALL
            /* this second part of the union query is bringing in accounts from DHC */
            SELECT
                --'DHC' AS [ACCOUNT_SRC], 
                CAST(STR([Definitive ID]) AS VARCHAR) [Definitive ID],
                CAST(t.[Provider Number] AS VARCHAR) [Provider Number],
                --       '' AS [SFDC_ID], 
                ISNULL(E.NAME_REP, 'Unassigned') AS [REP],
                ISNULL(E.REP_EMAIL, 'Unassigned') AS [REP_EMAIL],
                ISNULL(E.REGION, 'Unassigned') AS [REGION],
                E.TERR_ID,
                --     ISNULL(B.TERRITORY, 'Unassigned') AS [TERRITORY], 
                -- ISNULL(ISNULL(ISNULL(ISNULL(E.OWNER_EMAIL, f.OWNER_EMAIL), g.OWNER_EMAIL), f2.OWNER_EMAIL), f3.OWNER_EMAIL) AS [REP_OWNER_EMAIL], 
                --   [CSA ID], 
                (t.cbsa + ' - ' + t.cbsa_name) [CBSA],
                T.HOSPITAL_NAME,
                NULL,
                'Target' AS [STAGE],
                --  '' AS [CONTRACTING__C], 
                --'' AS [VALUE_ANALYSIS_INITIATED__C], 
                --'' AS [STAGE_NEW__C], 
                --0 AS [ISACU], 
                --'FALSE' AS [isAIC], 
                dbo.ConvertToTitleCase(T.City) + ', ' + t.State [CITY_STATE],
                CAST(RIGHT('00000' + T.ZIPCode, 5) AS VARCHAR) ZIPCode,
                ISNULL(CAST([# of Staffed Beds] AS VARCHAR), 'Unknown') [BEDS],
                NULL AS [REP_RANK],
                GPO,
                IDN,
                IDN_CONTRACT,
                0 AS [PATIENTS_IN_FUNNEL],
                0 AS [IMPLANTS_COMPLETED],
                HF_CLAIMS,
                CRT_PROCEDURES,
                T.CardioMEMS,
                T.LVAD,
                --CRT_PROCEDURES_QTILE, 
                T.COST_TO_CHARGE_RATIO_QTILE AS [REIMBURSEMENT_QTILE],
                T.[MEDICARE_%],
                ISNULL(T.RankScore, 4000) [RANKSCORE],
                'DHC' AS [SRC],
                TU,
                0 AS TIER
            FROM
                qryCust_DHC T
                LEFT JOIN (
                    SELECT
                        DISTINCT *
                    FROM
                        qryZipAlign
                ) E ON RIGHT('00000' + T.ZIPCode, 5) = E.ZIP_CODE
            WHERE
                CAST(T.[Definitive ID] AS VARCHAR) NOT IN (
                    SELECT
                        DISTINCT A.DHC_ACCOUNT_ID__C
                    FROM
                        qryCust A
                    WHERE
                        A.DHC_ACCOUNT_ID__C IS NOT NULL
                ) --AND (t.HF_CLAIMS_QTILE > 2 OR IDN_CONTRACT = 'Y')
                AND (
                    ISNULL(t.HF_CLAIMS, 0) <> 0
                    OR IDN_CONTRACT = 'Y'
                )
        ) AS M
        LEFT JOIN dhc_LEK N ON M.PROVIDER_ID = n.[Cleaned PROV_ID]
),
/* CTE B brings in implant, revenue, ARC, and surgeon data */
B AS (
    SELECT
        --    , s.*
        M.*,
        C.CMS_ID__C,
        c.DHC_ACCOUNT_ID__C,
        isnull(d.[# of Staffed Beds], e.[# of Staffed Beds]) [# of Staffed Beds] -- isnull(d.HF_CLAIMS, e.HF_CLAIMS) HF_CLAIMS,
        -- isnull(d.HF_CLAIMS_QTILE, e.HF_CLAIMS_QTILE) HF_CLAIMS_QTILE,
        -- isnull(d.CRT_PROCEDURES, e.CRT_PROCEDURES) CRT_PROCEDURES,
        -- isnull(d.CRT_PROCEDURES_QTILE, e.CRT_PROCEDURES_QTILE) CRT_PROCEDURES_QTILE,
        -- isnull(d.LVAD, e.LVAD) LVAD,
        -- isnull(d.CardioMEMS, e.CardioMEMS) CardioMEMS
    FROM
        (
            SELECT
                [IR].[Account],
                I.FIRST_IMP,
                I.LAST_IMP,
                CASE
                    --   'active, at risk, churned, dormant and pending '
                    WHEN datediff(mm, I.LAST_IMP, GETDATE()) > 12 THEN 'Churned'
                    WHEN datediff(mm, I.LAST_IMP, GETDATE()) > 6 THEN 'At-Risk'
                    WHEN datediff(mm, I.LAST_IMP, GETDATE()) > 3 THEN 'Dormant'
                    WHEN [IR].[IMPLANTS (ALL)] = 0 THEN 'ACU'
                    ELSE 'Active'
                END AS [STATUS],
                [IR].[ACT_ID],
                [IR].[IDN],
                [IR].[ACT_OWNER_REGION],
                [IR].[ACT_OWNER_NAME],
                [IR].[IMPLANTS (ALL)],
                [IR].[IMPLANTS (R12)],
                [IR].[IMPLANTS (R6)],
                [IR].[REV_UNITS (ALL)],
                [IR].[REV_UNITS (R12)],
                [IR].[REV_UNITS (R6)],
                [IR].[REV_$ (ALL)],
                [IR].[REV_$ (R12)],
                [IR].[REV_$ (R6)],
                /* SURG come from SURGEON_ID in tmpOpps */
                isnull([ALL_TIME], 0) [SURG (ALL)],
                isnull([SURG_R12], 0) [SURG (R12)],
                isnull([SURG_R6], 0) [SURG (R6)],
                /* ARC comes from PHYSICIAN_ID in tmpOpps */
                isnull([ARC (All)], 0) [ARC (All)],
                isnull([ARC (R12)], 0) [ARC (R12)],
                isnull([ARC (R6)], 0) [ARC (R6)],
                /* PRESCRIBER comes from PRESCRIBER_ID in tmpOpps */
                isnull(P.PRESCRIBER_ALL_TIME, 0) [PRESCRIBER (All)],
                isnull(P.PRESCRIBER_R12, 0) [PRESCRIBER (R12)],
                isnull(P.PRESCRIBER_R6, 0) [PRESCRIBER (R6)]
            FROM
                (
                    SELECT
                        [T].[Account],
                        ACT_ID,
                        [T].[IDN],
                        [T].[ACT_OWNER_REGION],
                        [T].[ACT_OWNER_NAME],
                        SUM([T].[IMPLANTS]) [IMPLANTS (ALL)],
                        SUM([T].[IMPLANTS_R12]) [IMPLANTS (R12)],
                        SUM([T].[IMPLANTS_R6]) [IMPLANTS (R6)],
                        SUM([T].[REV_UNITS]) [REV_UNITS (ALL)],
                        SUM([T].[REV_UNITS_R12]) [REV_UNITS (R12)],
                        SUM([T].[REV_UNITS_R6]) [REV_UNITS (R6)],
                        SUM([T].[REV_$]) [REV_$ (ALL)],
                        SUM([T].[REV_$_R12]) [REV_$ (R12)],
                        SUM([T].[REV_$_R6]) [REV_$ (R6)]
                    FROM
                        (
                            SELECT
                                [Account],
                                ACT_ID,
                                [IDN],
                                dbo.ConvertToTitleCase(ACT_OWNER_REGION) ACT_OWNER_REGION,
                                ACT_OWNER_NAME,
                                INDICATION_FOR_USE__C,
                                REASON_FOR_IMPLANT__C,
                                isnull(sum(IMPLANTS), 0) AS IMPLANTS,
                                isnull(sum(REVENUE_UNITS), 0) AS REV_UNITS,
                                isnull(sum(SALES), 0) AS [REV_$],
                                CASE
                                    WHEN C.r12 = 'C12' THEN isnull(sum(IMPLANTS), 0)
                                    ELSE 0
                                END AS IMPLANTS_R12,
                                CASE
                                    WHEN C.r12 = 'C12' THEN isnull(sum(REVENUE_UNITS), 0)
                                    ELSE 0
                                END AS REV_UNITS_R12,
                                CASE
                                    WHEN C.r12 = 'C12' THEN isnull(sum(SALES), 0)
                                    ELSE 0
                                END AS [REV_$_R12],
                                CASE
                                    WHEN C.r6 = 'C6' THEN isnull(sum(IMPLANTS), 0)
                                    ELSE 0
                                END AS IMPLANTS_R6,
                                CASE
                                    WHEN C.r6 = 'C6' THEN isnull(sum(REVENUE_UNITS), 0)
                                    ELSE 0
                                END AS REV_UNITS_R6,
                                CASE
                                    WHEN C.r6 = 'C6' THEN isnull(sum(SALES), 0)
                                    ELSE 0
                                END AS [REV_$_R6],
                                C.R12,
                                C.R6
                            FROM
                                (
                                    SELECT
                                        A.NAME [Account],
                                        ACT_ID,
                                        O.NAME [OPP],
                                        STAGENAME,
                                        O.DHC_IDN_NAME__C [IDN],
                                        RECORD_TYPE,
                                        dbo.ConvertToTitleCase(ACT_OWNER_REGION) ACT_OWNER_REGION,
                                        ACT_OWNER_NAME,
                                        INDICATION_FOR_USE__C,
                                        REASON_FOR_IMPLANT__C,
                                        0 AS IMPLANTS,
                                        REVENUE_UNITS,
                                        SALES,
                                        cast(CLOSEDATE AS DATE) [DT],
                                        CLOSE_YYYYMM [YYYYMM],
                                        CLOSE_YYYY [YYYY],
                                        CLOSE_YYYYQQ [YYYYQQ],
                                        'REV' [DATA_SET]
                                    FROM
                                        tmpOpps O
                                        LEFT JOIN sfdcAccount A ON O.ACT_ID = A.ID
                                    WHERE
                                        OPP_COUNTRY = 'US'
                                        AND STAGENAME = 'REVENUE RECOGNIZED'
                                        AND REASON_FOR_IMPLANT__C = 'De novo'
                                    UNION
                                    ALL
                                    /* find all-time implants */
                                    SELECT
                                        A.NAME [Account],
                                        ACT_ID,
                                        O.NAME [OPP],
                                        STAGENAME,
                                        O.DHC_IDN_NAME__C [IDN],
                                        RECORD_TYPE,
                                        dbo.ConvertToTitleCase(ACT_OWNER_REGION) ACT_OWNER_REGION,
                                        ACT_OWNER_NAME,
                                        INDICATION_FOR_USE__C,
                                        REASON_FOR_IMPLANT__C,
                                        IMPLANT_UNITS,
                                        0 AS REVENUE_UNITS,
                                        0 AS SALES,
                                        cast(IMPLANTED_DT AS DATE),
                                        IMPLANTED_YYYYMM,
                                        IMPLANTED_YYYY,
                                        IMPLANTED_YYYYQQ,
                                        'IMP' [DATA_SET]
                                    FROM
                                        tmpOpps O
                                        LEFT JOIN sfdcAccount A ON O.ACT_ID = A.ID
                                    WHERE
                                        OPP_COUNTRY = 'US'
                                        AND OPP_STATUS = 'CLOSED'
                                        AND REASON_FOR_IMPLANT__C = 'De novo'
                                        AND INDICATION_FOR_USE__C = 'Heart Failure - Reduced Ejection Fraction'
                                        AND ISIMPL = 1
                                        /**************/
                                ) AS M
                                LEFT JOIN qryCalendar C ON M.DT = c.DT
                            GROUP BY
                                [Account],
                                [IDN],
                                ACT_OWNER_REGION,
                                ACT_OWNER_NAME,
                                INDICATION_FOR_USE__C,
                                REASON_FOR_IMPLANT__C,
                                c.R6,
                                ACT_ID,
                                c.r12
                        ) AS T
                    GROUP BY
                        [T].[Account],
                        [T].[IDN],
                        [T].[ACT_OWNER_REGION],
                        [T].[ACT_OWNER_NAME],
                        ACT_ID
                ) AS IR
                LEFT JOIN (
                    SELECT
                        ACT_ID,
                        MAX(cast(IMPLANTED_DT AS DATE)) [LAST_IMP],
                        MIN(cast(IMPLANTED_DT AS DATE)) [FIRST_IMP]
                    FROM
                        tmpOpps
                    WHERE
                        OPP_COUNTRY = 'US'
                        AND OPP_STATUS = 'CLOSED'
                        AND ISIMPL = 1
                        AND REASON_FOR_IMPLANT__C = 'De novo'
                        AND INDICATION_FOR_USE__C = 'Heart Failure - Reduced Ejection Fraction'
                    GROUP BY
                        ACT_ID
                ) AS I ON ir.ACT_ID = i.ACT_ID
                /* get all implanters (de novo only) */
                LEFT JOIN (
                    SELECT
                        S.[Account],
                        S.ACT_ID,
                        SUM([COUNTER]) [ALL_TIME],
                        SUM(SURG_R12) [SURG_R12],
                        SUM(SURG_R6) [SURG_R6]
                    FROM
                        (
                            SELECT
                                T.*,
                                c.r12,
                                c.R6,
                                CASE
                                    WHEN C.r12 = 'C12' THEN [COUNTER]
                                    ELSE 0
                                END AS [SURG_R12],
                                CASE
                                    WHEN C.r6 = 'C6' THEN [COUNTER]
                                    ELSE 0
                                END AS [SURG_R6]
                            FROM
                                (
                                    SELECT
                                        A.NAME [Account],
                                        ACT_ID,
                                        SURGEON,
                                        o.SURGEON_ID,
                                        1 AS COUNTER,
                                        MAX(IMPLANTED_DT) [LAST_IMPLANT]
                                    FROM
                                        tmpOpps O
                                        LEFT JOIN sfdcAccount A ON O.ACT_ID = A.ID
                                    WHERE
                                        OPP_COUNTRY = 'US'
                                        AND OPP_STATUS = 'CLOSED'
                                        AND ISIMPL = 1
                                        AND REASON_FOR_IMPLANT__C = 'De novo'
                                        AND INDICATION_FOR_USE__C = 'Heart Failure - Reduced Ejection Fraction'
                                        AND SURGEON_ID IS NOT NULL
                                        AND CLOSEDATE < (
                                            SELECT
                                                cast(MONTH_START_DATE AS date) AS DT
                                            FROM
                                                qryCalendar
                                            WHERE
                                                dt = cast(getdate() AS date)
                                        )
                                    GROUP BY
                                        A.NAME,
                                        ACT_ID,
                                        SURGEON,
                                        o.SURGEON_ID
                                ) AS T
                                LEFT JOIN qryCalendar C ON T.LAST_IMPLANT = c.dt
                        ) AS S
                    GROUP BY
                        S.[Account],
                        S.ACT_ID
                ) AS S ON IR.ACT_ID = S.ACT_ID
                /* get all referrers (de novo only) */
                LEFT OUTER JOIN (
                    SELECT
                        S.[Account],
                        S.ACT_ID,
                        SUM([COUNTER]) [ARC (ALL)],
                        SUM(ARC_R12) [ARC (R12)],
                        SUM(ARC_R6) [ARC (R6)]
                    FROM
                        (
                            SELECT
                                T.*,
                                c.r12,
                                c.R6,
                                CASE
                                    WHEN C.r12 = 'C12' THEN [COUNTER]
                                    ELSE 0
                                END AS [ARC_R12],
                                CASE
                                    WHEN C.r6 = 'C6' THEN [COUNTER]
                                    ELSE 0
                                END AS [ARC_R6]
                            FROM
                                (
                                    SELECT
                                        A.NAME [Account],
                                        ACT_ID,
                                        PHYSICIAN,
                                        PHYSICIAN_ID,
                                        1 AS COUNTER,
                                        MAX(IMPLANTED_DT) [LAST_IMPLANT]
                                    FROM
                                        tmpOpps O
                                        LEFT JOIN sfdcAccount A ON O.ACT_ID = A.ID
                                    WHERE
                                        OPP_COUNTRY = 'US'
                                        AND OPP_STATUS = 'CLOSED'
                                        AND ISIMPL = 1
                                        AND REASON_FOR_IMPLANT__C = 'De novo'
                                        AND INDICATION_FOR_USE__C = 'Heart Failure - Reduced Ejection Fraction'
                                        AND PHYSICIAN_ID IS NOT NULL
                                        AND CLOSEDATE < (
                                            SELECT
                                                cast(MONTH_START_DATE AS date) AS DT
                                            FROM
                                                qryCalendar
                                            WHERE
                                                dt = cast(getdate() AS date)
                                        )
                                    GROUP BY
                                        A.NAME,
                                        ACT_ID,
                                        PHYSICIAN,
                                        PHYSICIAN_ID
                                ) AS T
                                LEFT JOIN qryCalendar C ON T.LAST_IMPLANT = c.dt
                        ) AS S
                    GROUP BY
                        S.[Account],
                        S.ACT_ID
                ) A ON IR.act_ID = a.act_ID
                /* get all prescribers (de novo only) */
                LEFT OUTER JOIN (
                    SELECT
                        S.[Account],
                        S.ACT_ID,
                        SUM([COUNTER]) [PRESCRIBER_ALL_TIME],
                        SUM(PRESCRIBER_R12) [PRESCRIBER_R12],
                        SUM(PRESCRIBER_R6) [PRESCRIBER_R6]
                    FROM
                        (
                            SELECT
                                T.*,
                                c.r12,
                                c.R6,
                                CASE
                                    WHEN C.r12 = 'C12' THEN [COUNTER]
                                    ELSE 0
                                END AS [PRESCRIBER_R12],
                                CASE
                                    WHEN C.r6 = 'C6' THEN [COUNTER]
                                    ELSE 0
                                END AS [PRESCRIBER_R6]
                            FROM
                                (
                                    SELECT
                                        A.NAME [Account],
                                        ACT_ID,
                                        PRESCRIBER,
                                        PRESCRIBER_ID,
                                        1 AS COUNTER,
                                        MAX(IMPLANTED_DT) [LAST_IMPLANT]
                                    FROM
                                        tmpOpps O
                                        LEFT JOIN sfdcAccount A ON O.ACT_ID = A.ID
                                    WHERE
                                        OPP_COUNTRY = 'US'
                                        AND OPP_STATUS = 'CLOSED'
                                        AND ISIMPL = 1
                                        AND REASON_FOR_IMPLANT__C = 'De novo'
                                        AND INDICATION_FOR_USE__C = 'Heart Failure - Reduced Ejection Fraction'
                                        AND PRESCRIBER_ID IS NOT NULL
                                        AND CLOSEDATE < (
                                            SELECT
                                                cast(MONTH_START_DATE AS date) AS DT
                                            FROM
                                                qryCalendar
                                            WHERE
                                                dt = cast(getdate() AS date)
                                        )
                                    GROUP BY
                                        A.NAME,
                                        ACT_ID,
                                        PRESCRIBER,
                                        PRESCRIBER_ID
                                ) AS T
                                LEFT JOIN qryCalendar C ON T.LAST_IMPLANT = c.dt
                        ) AS S
                    GROUP BY
                        S.[Account],
                        S.ACT_ID
                ) AS P ON P.ACT_ID = IR.ACT_ID
        ) AS M
        LEFT JOIN qryCust C ON c.ID = M.act_id
        LEFT JOIN qryCust_DHC D ON C.CMS_ID__C = D.[Provider Number]
        LEFT JOIN qryCust_DHC E ON c.DHC_ACCOUNT_ID__C = cast(e.[Definitive ID] AS varchar)
),
DISTINCT_PHYS AS (
    SELECT
        Account,
        ACT_ID,
        COUNT(DOC_ID) AS DISTINCT_ARC_AND_PRESC
    FROM
        (
            SELECT
                Account,
                ACT_ID,
                DOC_ID,
                MAX(IMPLANTED_DT) AS [LAST_IMPLANT]
            FROM
                (
                    SELECT
                        A.NAME [Account],
                        O.ACT_ID,
                        O.PRESCRIBER_ID AS DOC_ID,
                        IMPLANTED_DT
                    FROM
                        tmpOpps O
                        LEFT JOIN sfdcAccount A ON A.ID = O.ACT_ID
                    WHERE
                        OPP_COUNTRY = 'US'
                        AND OPP_STATUS = 'CLOSED'
                        AND ISIMPL = 1
                        AND REASON_FOR_IMPLANT__C = 'De novo'
                        AND INDICATION_FOR_USE__C = 'Heart Failure - Reduced Ejection Fraction'
                        AND PRESCRIBER_ID IS NOT NULL
                        AND CLOSEDATE < (
                            SELECT
                                cast(MONTH_START_DATE AS date) AS DT
                            FROM
                                qryCalendar
                            WHERE
                                dt = cast(getdate() AS date)
                        )
                    UNION
                    ALL
                    SELECT
                        A.NAME [Account],
                        O.ACT_ID,
                        O.PHYSICIAN_ID AS DOC_ID,
                        IMPLANTED_DT
                    FROM
                        tmpOpps O
                        LEFT JOIN sfdcAccount A ON A.ID = O.ACT_ID
                    WHERE
                        OPP_COUNTRY = 'US'
                        AND OPP_STATUS = 'CLOSED'
                        AND ISIMPL = 1
                        AND REASON_FOR_IMPLANT__C = 'De novo'
                        AND INDICATION_FOR_USE__C = 'Heart Failure - Reduced Ejection Fraction'
                        AND PHYSICIAN_ID IS NOT NULL
                        AND CLOSEDATE < (
                            SELECT
                                cast(MONTH_START_DATE AS date) AS DT
                            FROM
                                qryCalendar
                            WHERE
                                dt = cast(getdate() AS date)
                        )
                ) AS A
            WHERE
                FORMAT(IMPLANTED_DT, 'yyyy_MM') < FORMAT(GETDATE(), 'yyyy_MM')
            GROUP BY
                Account,
                ACT_ID,
                DOC_ID
            HAVING
                FORMAT(MAX(IMPLANTED_DT), 'yyyy_MM') IN (
                    SELECT
                        DISTINCT YYYYMM
                    FROM
                        qryCalendar
                    WHERE
                        R12 = 'C12'
                )
        ) AS B
    GROUP BY
        Account,
        ACT_ID
),
-- consistency metric
CM AS (
    SELECT
        *,
        CASE
            WHEN [R6_MONTHS_W_IMPLANT] >= 4
            AND [R6_AVG_IMPL] >= 1 THEN 1
            ELSE 0
        END AS [CONSISTENCY_METRIC_MET?]
    FROM
        qryImplant_Consistency
    WHERE
        IMPLANT_YYYYMM = FORMAT(DATEADD(MONTH, -1, GETDATE()), 'yyyy_MM')
),
-- blueprint data
BP AS (
    SELECT
        Account__c,
        ID AS BP_ID,
        Blueprint_Type__c,
        Status__c,
        ASD_Sign_Date__c,
        Champions__c,
        Prescribers__c,
        Referrers__c
    FROM
        ods.sfdcBlueprint
    WHERE
        Status__c = 'Active'
),
Q AS
/* QUERY STARTS HERE */
(
    SELECT
        Y.*,
        CM.[R6_MONTHS_W_IMPLANT],
        CM.[R6_AVG_IMPL],
        ISNULL(CM.CONSECUTIVE_MONTHS, 0) AS CONSISTENCY,
        ISNULL(CM.[CONSISTENCY_METRIC_MET?], 0) AS [CONSISTENCY_METRIC_MET?],
        CASE
            WHEN [VOLUME_METRIC_MET?] + [REFERRER_METRIC_MET?] + [SURGEON_METRIC_MET?] + [CHAMPION_METRIC_MET?] + ISNULL([CONSISTENCY_METRIC_MET?], 0) = 5 THEN 1
            ELSE 0
        END AS [isProgram?],
        CONCAT(
            [VOLUME_METRIC_MET?] + [REFERRER_METRIC_MET?] + [SURGEON_METRIC_MET?] + [CHAMPION_METRIC_MET?] + isnull([CONSISTENCY_METRIC_MET?], 0),
            '/5'
        ) AS METRICS_MET,
        count(*) over (PARTITION by [Definitive ID]) AS [DEFINITIVE ID DUPE?],
        /* some records have an SFDC associated with a different Definitive ID than what Jordan has in his file.
         This "case when" statement allows you to exclude those SFDC/Definitve ID pairs that do not match Jordan's
         mapping file. */
        CASE
            /*if only 1 record exists for the Definitive ID, do not exclude*/
            WHEN count(*) over (PARTITION by [Definitive ID]) = 1 THEN 'NO'
            /*if 2 records exist for the Definitive ID, only keep the one that matches the Definitive ID & SFDC ID in the mapping file*/
            WHEN count(*) over (PARTITION by [Definitive ID]) = 2
            AND EXISTS(
                SELECT
                    1
                FROM
                    tblAccount_Mapping AM
                WHERE
                    Y.[Definitive ID] = TRIM(AM.[Definitive ID])
                    AND Y.SFDC_ID = TRIM(AM.[Salesforce ID])
            ) THEN 'NO'
            /*if 2 records exist for the Definitive ID and the tier = 4, only keep the records where the source
             is SFDC and the Definitive ID is not in the mapping file (if the Definitive ID is in the mapping file, it should
             have already been captured in the previous "WHEN" statement)*/
            WHEN [Tier] = 4
            AND count(*) over (PARTITION by [Definitive ID]) = 2
            AND [SRC] = 'SFDC'
            AND Y.[Definitive ID] NOT IN (
                SELECT
                    TRIM([Definitive ID])
                FROM
                    tblAccount_Mapping
                WHERE
                    [Definitive ID] IS NOT NULL
            ) THEN 'NO'
            WHEN count(*) over (PARTITION by [Definitive ID]) > 100 THEN 'NO'
            ELSE 'YES'
        END AS [EXCLUDE?],
        CASE
            WHEN SFDC_ID IS NULL THEN NULL
            ELSE CONCAT(
                'https://cvrx.lightning.force.com/lightning/r/Account/',
                SFDC_ID,
                '/view'
            )
        END AS SFDC_LINK,
        CASE
            WHEN ACT_ID IN (
                SELECT
                    PARENT_ID
                FROM
                    tblAct_Satellites
            ) THEN 'Yes'
            ELSE 'No'
        END AS [HAS_SATELLITES?],
        CASE
            WHEN ACT_ID IN (
                SELECT
                    CHILD_ID
                FROM
                    tblAct_Satellites
            ) THEN (
                SELECT
                    PARENT_ID
                FROM
                    tblAct_Satellites
                WHERE
                    CHILD_ID = ACT_ID
            )
            ELSE NULL
        END AS [PARENT_ID]
    FROM
        (
            SELECT
                X.NAME,
                X.CITY_STATE,
                X.STAGE,
                X.Analytics_Rank,
                X.[LEK Priority],
                X.REP_RANK,
                X.GPO,
                X.IDN,
                X.IDN_CONTRACT,
                X.TU,
                X.PATIENTS_IN_FUNNEL,
                X.[REIMBURSEMENT_QTILE],
                X.[MEDICARE_%],
                X.ACT_OWNER,
                X.REP_EMAIL,
                X.REP,
                ISNULL(T.REGION_NM, X.REGION) AS REGION,
                ISNULL(D.DE_FACTO_TERR, X.TERR_ID) AS DE_FACTO_TERR_ID,
                T.TERR_NM,
                CASE
                    WHEN TRIM(ISNULL(Z.[Definitive ID], X.[Definitive ID])) = '0' THEN NULL
                    ELSE TRIM(ISNULL(Z.[Definitive ID], X.[Definitive ID]))
                END AS [Definitive ID],
                CASE
                    WHEN TRIM(
                        ISNULL(
                            CAST(Z.[CMS ID] AS VARCHAR(MAX)),
                            CAST(X.CMS_ID AS VARCHAR(MAX))
                        )
                    ) = '0' THEN NULL
                    ELSE TRIM(
                        ISNULL(
                            CAST(Z.[CMS ID] AS VARCHAR(MAX)),
                            CAST(X.CMS_ID AS VARCHAR(MAX))
                        )
                    )
                END AS CMS_ID,
                X.SFDC_ID,
                X.ZIP_5,
                X.CBSA,
                X.SRC,
                X.FIRST_IMP,
                X.LAST_IMP,
                X.[STATUS],
                X.[IMPLANTS (ALL)],
                X.[IMPLANTS (R12)],
                X.[IMPLANTS (R6)],
                X.[REV_UNITS (ALL)],
                X.[REV_UNITS (R12)],
                X.[REV_UNITS (R6)],
                X.[REV_$ (ALL)],
                X.[REV_$ (R12)],
                X.[REV_$ (R6)],
                X.[SURG (ALL)],
                X.[SURG (R12)],
                X.[SURG (R6)],
                X.[ARC (All)],
                X.[ARC (R12)],
                X.[ARC (R6)],
                X.[PRESCRIBER (ALL)],
                X.[PRESCRIBER (R12)],
                X.[PRESCRIBER (R6)],
                X.DISTINCT_ARC_AND_PRESC,
                BP.Champions__c AS CHAMPIONS,
                ISNULL(Z.[HF Diagnosis], 0) AS [HF Diagnosis],
                ISNULL(Z.CardioMEMS, 0) AS CardioMEMS,
                ISNULL(Z.LVAD, 0) AS LVAD,
                ISNULL(Z.[CRT and ICD], 0) AS [CRT and ICD],
                ISNULL(Z.Mitraclip, 0) AS Mitraclip,
                ISNULL(Z.Watchman, 0) AS Watchman,
                -- ISNULL(Z.Tier, 4) AS Tier,
                ISNULL(
                    CASE
                        WHEN X.ACCOUNT_TIER IN (0, NULL) THEN Z.Tier
                        ELSE X.ACCOUNT_TIER
                    END,
                    4
                ) AS [Tier],
                CASE
                    WHEN X.[IMPLANTS (ALL)] >= 15 THEN 1
                    ELSE 0
                END AS [VOLUME_METRIC_MET?],
                CASE
                    WHEN [DISTINCT_ARC_AND_PRESC] >= 5 THEN 1
                    ELSE 0
                END AS [REFERRER_METRIC_MET?],
                CASE
                    WHEN [SURG (R12)] >= 2 THEN 1
                    ELSE 0
                END AS [SURGEON_METRIC_MET?],
                CASE
                    WHEN BP.Champions__c >= 2 THEN 1
                    ELSE 0
                END AS [CHAMPION_METRIC_MET?],
                CASE
                    WHEN BP.Status__c = 'Active' THEN 'Yes'
                    ELSE 'No'
                END AS [Blueprint Completed?],
                BP.Blueprint_Type__c AS [Blueprint Type],
                BP.ASD_Sign_Date__c AS [Blueprint Sign Date],
                BP.BP_ID AS BLUEPRINT_ID,
                CASE
                    WHEN BP_ID IS NULL THEN NULL
                    ELSE CONCAT(
                        'https://cvrx.lightning.force.com/lightning/r/Blueprint__c/',
                        BP_ID,
                        '/view'
                    )
                END AS BLUEPRINT_LINK
            FROM
                (
                    SELECT
                        A.NAME,
                        A.CITY_STATE,
                        A.STAGE,
                        A.ACCOUNT_TIER,
                        A.Analytics_Rank,
                        A.[LEK Priority],
                        A.REP_RANK,
                        A.GPO,
                        ISNULL(A.IDN, B.IDN) AS IDN,
                        A.IDN_CONTRACT,
                        A.TU,
                        A.PATIENTS_IN_FUNNEL,
                        A.REIMBURSEMENT_QTILE,
                        A.[MEDICARE_%],
                        ISNULL(A.REP, B.ACT_OWNER_NAME) AS ACT_OWNER,
                        A.REP_EMAIL,
                        A.REP,
                        A.REGION,
                        A.TERR_ID,
                        CAST(
                            ISNULL(A.[Definitive ID], B.DHC_ACCOUNT_ID__C) AS VARCHAR(MAX)
                        ) AS [Definitive ID],
                        CAST(
                            ISNULL(A.PROVIDER_ID, B.CMS_ID__C) AS VARCHAR(MAX)
                        ) AS CMS_ID,
                        CAST(ISNULL(A.ID, B.ACT_ID) AS VARCHAR(MAX)) AS SFDC_ID,
                        A.ZIP_5,
                        A.CBSA,
                        A.SRC,
                        B.FIRST_IMP,
                        B.LAST_IMP,
                        [STATUS],
                        ISNULL(B.[IMPLANTS (ALL)], 0) AS [IMPLANTS (ALL)],
                        ISNULL(B.[IMPLANTS (R12)], 0) AS [IMPLANTS (R12)],
                        ISNULL(B.[IMPLANTS (R6)], 0) AS [IMPLANTS (R6)],
                        ISNULL(B.[REV_UNITS (ALL)], 0) AS [REV_UNITS (ALL)],
                        ISNULL(B.[REV_UNITS (R12)], 0) AS [REV_UNITS (R12)],
                        ISNULL(B.[REV_UNITS (R6)], 0) AS [REV_UNITS (R6)],
                        ISNULL(B.[REV_$ (ALL)], 0) AS [REV_$ (ALL)],
                        ISNULL(B.[REV_$ (R12)], 0) AS [REV_$ (R12)],
                        ISNULL(B.[REV_$ (R6)], 0) AS [REV_$ (R6)],
                        ISNULL(B.[SURG (ALL)], 0) AS [SURG (ALL)],
                        ISNULL(B.[SURG (R12)], 0) AS [SURG (R12)],
                        ISNULL(B.[SURG (R6)], 0) AS [SURG (R6)],
                        ISNULL(B.[ARC (All)], 0) AS [ARC (All)],
                        ISNULL(B.[ARC (R12)], 0) AS [ARC (R12)],
                        ISNULL(B.[ARC (R6)], 0) AS [ARC (R6)],
                        ISNULL(B.[PRESCRIBER (All)], 0) AS [PRESCRIBER (ALL)],
                        ISNULL(B.[PRESCRIBER (R12)], 0) AS [PRESCRIBER (R12)],
                        ISNULL(B.[PRESCRIBER (R6)], 0) AS [PRESCRIBER (R6)],
                        ISNULL(DP.DISTINCT_ARC_AND_PRESC, 0) AS DISTINCT_ARC_AND_PRESC
                    FROM
                        A FULL
                        JOIN b ON a.ID = b.ACT_ID
                        LEFT JOIN DISTINCT_PHYS DP ON DP.ACT_ID = ISNULL(A.ID, B.ACT_ID)
                ) AS X
                OUTER APPLY(
                    SELECT
                        TOP 1 *
                    FROM
                        tblAccount_Mapping AS AM
                    WHERE
                        TRIM(AM.[Salesforce ID]) = TRIM(X.SFDC_ID)
                        OR TRIM(AM.[Definitive ID]) = TRIM(X.[Definitive ID])
                    ORDER BY
                        CASE
                            WHEN TRIM(AM.[Salesforce ID]) = TRIM(X.SFDC_ID) THEN 1
                            WHEN TRIM(AM.[Definitive ID]) = TRIM(X.[Definitive ID]) THEN 2
                        END
                ) AS Z
                /* bring in de-facto territory assignments */
                LEFT JOIN qryDE_FACTO_ASSIGNMENTS D ON X.SFDC_ID = D.ACT_ID
                /* bring in territory names */
                LEFT JOIN (
                    SELECT
                        T.TERRITORY_ID,
                        ISNULL(
                            R.TERR_NM,
                            CONCAT(T.TERRITORY, ' (OPEN)')
                        ) AS TERR_NM,
                        T.REGION_ID,
                        T.REGION AS REGION_NM,
                        ROW_NUMBER() OVER (
                            PARTITION BY T.TERRITORY_ID
                            ORDER BY
                                T.END_DT DESC
                        ) AS RN
                    FROM
                        tblTerritory T
                        LEFT JOIN qryRoster R ON T.TERRITORY_ID = R.TERRITORY_ID
                        AND R.ROLE = 'REP'
                        AND R.[isLATEST?] = 1
                        AND R.[STATUS] = 'ACTIVE'
                    WHERE
                        T.TERRITORY_ID NOT LIKE '%OFF'
                        AND T.TERRITORY_ID NOT LIKE 'MDR%'
                        AND T.END_DT > GETDATE()
                ) AS T ON ISNULL(D.DE_FACTO_TERR, X.TERR_ID) = T.TERRITORY_ID
                LEFT JOIN BP ON X.SFDC_ID = BP.Account__c
        ) AS Y
        LEFT JOIN CM ON Y.SFDC_ID = CM.ACT_ID
)
SELECT
    *
FROM
    Q
WHERE
    [EXCLUDE?] = 'NO';