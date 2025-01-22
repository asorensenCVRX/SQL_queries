SELECT
    REGION_NM,
    OPP_OWNER_NAME,
    ACT_OWNER_NAME,
    STATUS,
    SUB_STATUS__C,
    CASENUMBER,
    CPAS_PA_SUB_DT,
    CPAS_SUBMIT_YYYYMM,
    OPP_PA_SUB_DT,
    OPP_COMP_YYYYMM,
    ISNULL(OPP_COMP_YYYYMM, '2099_12') [OPP_COMP_YYYYMM],
    SPIF_PO_YYYYMM,
    [AM_ACTIVE_YYYYMM],
    [IsOppPaid?],
    [IsCasePaid?],
    ROLE,
    CASE
        WHEN ISNULL(t.OPP_COMP_YYYYMM, '2099_12') > CPAS_SUBMIT_YYYYMM
        AND CAST(CPAS_PA_SUB_DT AS DATE) > '6/19/23'
        AND AM_ACTIVE_YYYYMM <= CPAS_SUBMIT_YYYYMM
        AND STATUS <> 'No Authorization Required'
        AND ROLE = 'REP' THEN 1
        ELSE 0
    END AS [isAMQualified?],
    CASE
        WHEN ISNULL(t.OPP_COMP_YYYYMM, '2099_12') > CPAS_SUBMIT_YYYYMM
        AND CAST(CPAS_PA_SUB_DT AS DATE) > '6/19/23'
        AND STATUS <> 'No Authorization Required' THEN 1
        ELSE 0
    END AS [isCSRQualified?],
    CASE
        WHEN ISNULL(t.OPP_COMP_YYYYMM, '2099_12') > CPAS_SUBMIT_YYYYMM
        AND ROLE = 'REP'
        AND [IsOppPaid?] = 0 THEN 1
        ELSE 0
    END AS [isEligibleForPaymentThisPeriod?],
    RANK() OVER (
        PARTITION BY OPP_ID
        ORDER BY
            CPAS_PA_SUB_DT
    ) [isDupeOpp?],
    COUNT(OPP_ID) OVER (PARTITION BY OPP_ID) [TotalCases],
    OPP_ID,
    OPP_NAME,
    SALES,
    TOTALOPPORTUNITYQUANTITY,
    CLOSEDATE,
    CREATED_DATE,
    CREATED_YYYYMM,
    FACILITY_NAME,
    PHYSICIAN,
    NOTES,
    AM_EMAIL,
    [AM_PO],
    CSR_NAME,
    CSR_EMAIL,
    [CSR_PO],
    REP_PO_YYYYMM,
    CSR_PO_YYYYMM,
    CASE_OWNER,
    OPP_STATUS,
    STAGENAME,
    IMPLANTED_DT,
    IMPLANTED_YYYYMM,
    [isSamePeriod?],
    [isActive?],
    ACT_ID
FROM
    (
        SELECT
            C.STATUS,
            C.SUB_STATUS__C,
            C.CASENUMBER,
            C.PRIOR_AUTH_SUBMISSION_DATE__C AS CPAS_PA_SUB_DT,
            F.NAME AS FACILITY_NAME,
            O.PHYSICIAN,
            O.OPP_OWNER_NAME,
            R.ACTIVE_YYYYMM AS [AM_ACTIVE_YYYYMM],
            R.NAME_REP AS [ACT_OWNER_NAME],
            r.REGION_NM,
            R.REP_EMAIL AS AM_EMAIL,
            r.STATUS [isActive?],
            R.ROLE,
            ISNULL(
                Z2.REP_PO,
                CASE
                    WHEN REPLACE(CAL.YYYYMM, '2023_06', '2023_07') >= '2023_10'
                    AND R.REP_EMAIL IN (
                        'jrussell@cvrx.com',
                        'dduffy@cvrx.com',
                        'jhorky@cvrx.com',
                        'gsnow@cvrx.com',
                        'bdanielewicz@cvrx.com',
                        'lmiller@cvrx.com'
                    ) THEN (
                        CASE
                            WHEN x.EMAIL IS NULL THEN 500.00
                            ELSE 350.00
                        END
                    ) * 1
                    ELSE (
                        CASE
                            WHEN x.EMAIL IS NULL THEN 500.00
                            ELSE 350.00
                        END
                    )
                END
            ) AS [AM_PO],
            RC.REP_EMAIL AS CSR_EMAIL,
            rc.NAME_REP [CSR_NAME],
            ISNULL(
                Z2.CSR_PO,
                CASE
                    WHEN REPLACE(CAL.YYYYMM, '2023_06', '2023_07') >= '2023_10'
                    AND R.REP_EMAIL IN (
                        'jrussell@cvrx.com',
                        'dduffy@cvrx.com',
                        'jhorky@cvrx.com',
                        'gsnow@cvrx.com',
                        'bdanielewicz@cvrx.com',
                        'lmiller@cvrx.com'
                    ) THEN (
                        CASE
                            WHEN x.EMAIL IS NULL THEN 0.00
                            ELSE 150.00
                        END
                    ) * 1
                    ELSE (
                        CASE
                            WHEN x.EMAIL IS NULL THEN 0.00
                            ELSE 150.00
                        END
                    )
                END
            ) AS CSR_PO,
            CC.NAME AS CASE_OWNER,
            o.SALES,
            o.TOTALOPPORTUNITYQUANTITY,
            O.OPP_STATUS,
            O.OPP_ID,
            O.NAME AS OPP_NAME,
            O.STAGENAME,
            O.IMPLANTED_DT,
            O.IMPLANTED_YYYYMM,
            O.CLOSEDATE,
            CAST(C.CREATEDDATE AS DATE) AS CREATED_DATE,
            cal2.YYYYMM CREATED_YYYYMM,
            O.PRIOR_AUTH_SUBMISSION_DATE__C AS OPP_PA_SUB_DT,
            REPLACE(CAL.YYYYMM, '2023_06', '2023_07') CPAS_SUBMIT_YYYYMM,
            CASE
                WHEN o.STAGENAME = 'Revenue Recognized' THEN CLOSE_YYYYMM
                ELSE NULL
            END AS OPP_COMP_YYYYMM,
            REPLACE(CAL.YYYYMM, '2023_06', '2023_07') AS SPIF_PO_YYYYMM,
            CASE
                WHEN (
                    CASE
                        WHEN o.STAGENAME = 'Revenue Recognized' THEN CLOSE_YYYYMM
                        ELSE NULL
                    END
                ) = REPLACE(
                    CAL.YYYYMM,
                    '2023_06',
                    '2023_07'
                ) THEN 1
                ELSE 0
            END AS [isSamePeriod?],
            CASE
                WHEN Z.OPP_ID IS NOT NULL THEN 1
                ELSE 0
            END AS [IsOppPaid?],
            CASE
                WHEN Z2.CASENUMBER IS NOT NULL THEN 1
                ELSE 0
            END AS [IsCasePaid?],
            z2.CSR_PO_YYYYMM,
            z2.REP_PO_YYYYMM,
            [AS].[NOTES],
            F.ID [ACT_ID]
        FROM
            dbo.sfdcCase AS C
            LEFT OUTER JOIN dbo.sfdcAccount AS A ON C.ACCOUNTID = A.ID
            LEFT OUTER JOIN dbo.sfdcAccount AS F ON C.FACILITY__C = F.ID
            LEFT OUTER JOIN dbo.qryOpps AS O ON C.OPPORTUNITY__C = O.OPP_ID
            LEFT JOIN (
                SELECT
                    DISTINCT ACT_ID,
                    NOTES
                FROM
                    tblActSplits
            ) AS [AS] ON [as].ACT_ID = f.ID
            LEFT OUTER JOIN dbo.sfdcUser AS CC ON C.OWNERID = CC.ID
            LEFT OUTER JOIN dbo.qryCalendar AS CAL ON CAL.DT = CAST(C.PRIOR_AUTH_SUBMISSION_DATE__C AS DATE)
            LEFT OUTER JOIN dbo.qryCalendar AS CAL2 ON CAL2.DT = CAST(C.CREATEDDATE AS DATE)
            LEFT OUTER JOIN (
                SELECT
                    DISTINCT OPP_ID
                FROM
                    dbo.tblCPAS_PO
            ) AS Z ON c.OPPORTUNITY__C = z.opp_ID
            LEFT OUTER JOIN qryCPAS_PO AS Z2 ON z2.CASENUMBER = c.CASENUMBER
            LEFT OUTER JOIN dbo.qryRoster AS R ON ISNULL(z2.REP_EMAIL, o.ACT_OWNER_EMAIL) = R.REP_EMAIL
            AND R.[isLATEST?] = 1
            LEFT OUTER JOIN dbo.qryAlign_FCE AS X ON (
                CASE
                    WHEN X.TYPE = 'ACCT' THEN c.FACILITY__C
                    WHEN x.TYPE = 'DOC' THEN o.PHYSICIAN_ID
                END
            ) = X.[KEY]
            AND ISNULL(
                CAL.YYYYMM,
                '2099_12'
            ) >= x.ACTIVE_YYYYMM
            LEFT OUTER JOIN dbo.qryRoster AS Rc ON ISNULL(z2.CSR_EMAIL, X.EMAIL) = Rc.REP_EMAIL
            AND RC.[isLATEST?] = 1
        WHERE
            C.RECORDTYPEID = '0124u0000009vDVAAY'
            AND ISNULL(cal.YYYYMM, cal2.yyyymm) < (
                SELECT
                    YYYYMM
                FROM
                    qryCalendar
                WHERE
                    [DT] = CAST(DATEADD(mm, 0, GETDATE()) AS DATE)
            )
            AND O.OPP_ID IS NOT NULL
            AND (
                CAST(C.CREATEDDATE AS DATE) > '6/19/23'
                OR CAST(C.PRIOR_AUTH_SUBMISSION_DATE__C AS DATE) > '6/19/23'
            )
            OR z.OPP_ID IS NOT NULL
    ) AS T -- WHERE
    --     CASENUMBER in (4903)