-- CREATE VIEW qryOpps AS
WITH qOpps AS (
    SELECT
        T.*,
        CASE
            WHEN PHYSICIAN_ID IS NULL
            OR STAGENAME NOT IN (
                'Revenue Recognized',
                'Procedure recognized',
                'Implant Completed'
            ) THEN 0
            ELSE SUM([REFERRABLE_UNITS]) OVER (
                PARTITION BY PHYSICIAN_ID
                ORDER BY
                    ISNULL(IMPLANTED_DT, '12/31/2099'),
                    NAME
            )
        END AS [REFERRAL_COUNT_CLOSED],
        CASE
            WHEN PHYSICIAN_ID IS NULL THEN 0
            ELSE SUM([REFERRABLE_UNITS]) OVER (
                PARTITION BY PHYSICIAN_ID
                ORDER BY
                    ISNULL(IMPLANTED_DT, CLOSEDATE),
                    NAME
            )
        END AS [REFERRAL_COUNT_TTL]
    FROM
        (
            SELECT
                REPLACE(
                    dbo.ConvertToTitleCase(REPLACE(U.NAME, ' HF', '')),
                    '?',
                    ''
                ) AS ACCOUNT_INDICATION__C,
                A.ACCOUNT_OWNER_ALIAS__C,
                CASE
                    WHEN D.STAGE_NEW__C = 'Activated for commercial use (ACU)' THEN 1
                    ELSE 0
                END AS ISACU,
                A.ID AS OPP_ID,
                A.NEXTSTEP,
                A.NEXT_FOLLOW_UP_DATE__C,
                A.SURGERY_DATE__C,
                h2.PROCEDURE_DATE__C,
                CASE
                    WHEN h2.id IS NULL THEN 0
                    ELSE 1
                END AS [hasRelatedProcedure?],
                A.ACCOUNTID AS ACT_ID,
                A.[OPPORTUNITY_REGION__C],
                ISNULL(A.OPPORTUNITY_SOURCE__C, 'N/A') AS OPPORTUNITY_SOURCE__C,
                CASE
                    WHEN LEFT(A.OPPORTUNITY_REGION__C, 3) = 'EU ' THEN 'EU'
                    WHEN LEFT(A.OPPORTUNITY_REGION__C, 3) = 'Nor' THEN 'US'
                    WHEN LEFT(A.OPPORTUNITY_REGION__C, 2) = 'NA' THEN 'US' --WHEN ACCOUNT_OWNER_ALIAS__C = 'theng' then 'EU'
                    WHEN D.SHIPPINGCOUNTRYCODE = 'US' THEN 'US'
                    WHEN a.ACCOUNTID NOT IN (
                        SELECT
                            ID
                        FROM
                            sfdcAccount
                        WHERE
                            currencyISOCODE = 'USD'
                            AND isnull(SHIPPINGCOUNTRYCODE, 'US') = 'US'
                    ) THEN 'EU'
                    ELSE NULL
                END AS OPP_COUNTRY,
                REPLACE(
                    REPLACE(
                        A.OPPORTUNITY_OWNER_REGION__C,
                        'The Syndicate',
                        'South Central'
                    ),
                    'Northbeast',
                    'Northeast'
                ) AS [OPPORTUNITY_OWNER_REGION__C],
                A.OPPORTUNITY_OWNER_AREA__C,
                D.SHIPPINGSTATECODE,
                D.SHIPPINGCITY,
                D.SHIPPINGCOUNTRYCODE,
                d.SHIPPINGSTREET,
                D.DHC_IDN_NAME__C,
                D.PRIMARY_GPO__C,
                G.Rep AS SALES_CREDIT_REP,
                G.EMAIL AS SALES_CREDIT_REP_EMAIL,
                dbo.ConvertToTitleCase(ISNULL(d.REGION, B.US_REGION__C)) AS REGION,
                ISNULL(d.REGION_ID, 'NOT_ALGND') AS REG_ID,
                dbo.ConvertToTitleCase (
                    (
                        SELECT
                            DISTINCT RM_EMAIL
                        FROM
                            dbo.qryRoster AS qryRoster_1
                        WHERE
                            (REP_EMAIL = G.EMAIL)
                            AND [isLATEST?] = 1
                    )
                ) AS SALES_CREDIT_RM,
                dbo.ConvertToTitleCase (
                    (
                        SELECT
                            DISTINCT TERR_NM
                        FROM
                            dbo.qryRoster AS qryRoster_1
                        WHERE
                            (REP_EMAIL = f.EMAIL)
                            AND [isLATEST?] = 1
                    )
                ) AS SALES_CREDIT_TERR_NM,
                FF.NAME [AM_FOR_CREDIT],
                FF.EMAIL [AM_FOR_CREDIT_EMAIL],
                FFF.NAME AS CREATED_BY_NAME,
                FFF.EMAIL AS CREATED_BY_EMAIL,
                B.NAME AS OPP_OWNER_NAME,
                B.ID AS OPP_OWNER_ID,
                B.LASTNAME AS OPP_OWNER_LNAME,
                B.ALIAS AS OPP_OWNER_ALIAS,
                B.EMAIL AS OPP_OWNER_EMAIL,
                B.TITLE_REV AS OPP_OWNER_TITLE,
                B.ISACTIVE AS OPP_OWNER_ISACTIVE,
                B.US_REGION__C AS OPP_OWNER_REGION,
                F.NAME AS ACT_OWNER_NAME,
                F.LASTNAME AS ACT_OWNER_LNAME,
                F.ALIAS AS ACT_OWNER_ALIAS,
                F.TITLE_REV AS ACT_OWNER_TITLE,
                F.EMAIL AS ACT_OWNER_EMAIL,
                F.ISACTIVE AS ACT_OWNER_ISACTIVE,
                dbo.ConvertToTitleCase(F.US_REGION__C) AS ACT_OWNER_REGION,
                E.NAME AS RECORD_TYPE,
                E.ID AS RECORD_TYPE_ID,
                C.NAME AS IMPLANT_COMPLETE_NAME,
                C.US_REGION__C AS IMPLANT_COMPLETE_REGION,
                A.EXPECTEDREVENUE,
                A.IMPLANT_REVENUE__C AS SALES,
                A.IMPLANT_REVENUE__C / NULLIF (
                    CASE
                        WHEN A.TOTALOPPORTUNITYQUANTITY = 0 THEN 1
                        ELSE A.TOTALOPPORTUNITYQUANTITY
                    END,
                    0
                ) AS ASP,
                A.INDICATION_FOR_USE__C,
                CASE
                    WHEN A.TOTALOPPORTUNITYQUANTITY < 1
                    AND TOTALOPPORTUNITYQUANTITY > 0 THEN 0
                    ELSE A.TOTALOPPORTUNITYQUANTITY
                END AS TOTALOPPORTUNITYQUANTITY,
                CASE
                    WHEN LEFT(A.OPPORTUNITY_REGION__C, 3) = 'EU ' THEN 0
                    WHEN E.NAME = 'Financial Opportunity' THEN 0
                    WHEN A.REPLACEMENT_TYPE__C = 'CSL' THEN 0
                    ELSE 1
                END AS IMPLANT_UNITS,
                CASE
                    WHEN LEFT(A.OPPORTUNITY_REGION__C, 3) = 'EU ' THEN 0
                    WHEN A.IMPLANT_REVENUE__C = 0 THEN 0
                    WHEN A.REPLACEMENT_TYPE__C = 'CSL' THEN 0
                    WHEN ISNULL(a.EXPECTEDREVENUE, 0) < 0
                    AND ISNULL(a.EXPECTEDREVENUE, 0) > - 10000 THEN 0
                    ELSE TOTALOPPORTUNITYQUANTITY
                END AS REVENUE_UNITS,
                CASE
                    WHEN (
                        CASE
                            WHEN A.STAGENAME = 'CANCELLED' THEN 'CANCELLED'
                            WHEN A.STAGENAME IN (
                                'Revenue Recognized',
                                'Procedure recognized',
                                'Implant Completed'
                            )
                            OR ISCLOSED = 1 THEN 'CLOSED'
                            ELSE 'OPEN'
                        END
                    ) = 'OPEN'
                    AND E.NAME = 'Procedure - North America'
                    AND A.CREATEDDATE IS NOT NULL
                    AND DATEDIFF(dd, A.CREATEDDATE, GETDATE()) >= 0 THEN DATEDIFF(
                        dd,
                        A.CREATEDDATE,
                        GETDATE()
                    )
                    WHEN (
                        CASE
                            WHEN A.STAGENAME = 'CANCELLED' THEN 'CANCELLED'
                            WHEN A.STAGENAME IN (
                                'Revenue Recognized',
                                'Procedure recognized',
                                'Implant Completed'
                            )
                            OR ISCLOSED = 1 THEN 'CLOSED'
                            ELSE 'OPEN'
                        END
                    ) = 'CANCELLED'
                    AND E.NAME = 'Procedure - North America'
                    AND A.CREATEDDATE IS NOT NULL
                    AND DATEDIFF(dd, A.CREATEDDATE, GETDATE()) >= 0 THEN DATEDIFF(dd, A.CREATEDDATE, a.LASTSTAGECHANGEDATE)
                    WHEN E.NAME = 'Procedure - North America'
                    AND H.PROCEDURE_DATE__C IS NOT NULL
                    AND A.CREATEDDATE IS NOT NULL
                    AND DATEDIFF(dd, A.CREATEDDATE, H.PROCEDURE_DATE__C) >= 0 THEN DATEDIFF(dd, A.CREATEDDATE, H.PROCEDURE_DATE__C)
                    WHEN E.NAME = 'Procedure - North America' THEN 0
                    ELSE NULL
                END AS DURATION,
                CAST(A.CREATEDDATE AS DATE) AS CREATEDDATE,
                DATEDIFF(dd, A.CREATEDDATE, GETDATE()) AS AGE,
                TRIM(
                    CAST(YEAR(A.CREATEDDATE) AS VARCHAR) + '_' + RIGHT(
                        '0' + CAST(
                            MONTH(A.CREATEDDATE) AS VARCHAR
                        ),
                        2
                    )
                ) AS CREATED_YYYYMM,
                TT.YYYYQQ [CREATED_YYYYQQ],
                YEAR(A.CREATEDDATE) AS CREATED_YYYY,
                TT.R12 AS CREATED_R12,
                TT.R6 AS CREATED_R6,
                TT.R4 AS CREATED_R4,
                TT.R3 AS CREATED_R3,
                A.CLOSEDATE,
                TRIM(
                    CAST(YEAR(A.CLOSEDATE) AS VARCHAR) + '_' + RIGHT('0' + CAST(MONTH(A.CLOSEDATE) AS VARCHAR), 2)
                ) AS CLOSE_YYYYMM,
                TRIM(
                    CAST(
                        YEAR(A.CLOSEDATE) AS VARCHAR
                    ) + '_Q' + CAST(DATEPART(q, A.CLOSEDATE) AS VARCHAR)
                ) AS CLOSE_YYYYQQ,
                YEAR(A.CLOSEDATE) AS CLOSE_YYYY,
                STAGE_CHANGE_DATE__C,
                TRIM(
                    CAST(
                        YEAR(A.STAGE_CHANGE_DATE__C) AS VARCHAR
                    ) + '_' + RIGHT(
                        '0' + CAST(MONTH(A.STAGE_CHANGE_DATE__C) AS VARCHAR),
                        2
                    )
                ) AS STAGE_CHNG_YYYYMM,
                TRIM(
                    CAST(YEAR(A.STAGE_CHANGE_DATE__C) AS VARCHAR) + '_Q' + CAST(
                        DATEPART(
                            q,
                            A.STAGE_CHANGE_DATE__C
                        ) AS VARCHAR
                    )
                ) AS STAGE_CHNG_YYYYQQ,
                YEAR(A.STAGE_CHANGE_DATE__C) AS STAGE_CHNG_YYYY,
                A.AMOUNT,
                a.Probability__c [Probability],
                ii.name [Primary_Insurance__c],
                isnull(
                    CASE
                        WHEN ISNULL(A.INSURANCETYPE__C, a.INSURANCE_TYPE__C) = 'Other' THEN 'Other'
                        ELSE ISNULL(
                            ISNULL(A.INSURANCETYPE__C, a.INSURANCE_TYPE__C),
                            a.OPPORTUNITY_INSURANCE_TYPE__C
                        )
                    END,
                    CASE
                        WHEN INSURANCE_COMPANY_OTHER__C LIKE '%Medicare Advantage%' THEN 'Medicare Advantage'
                        WHEN INSURANCE_COMPANY_OTHER__C LIKE '%Med Adv%' THEN 'Medicare Advantage'
                        WHEN INSURANCE_COMPANY_OTHER__C LIKE '%Medicare%' THEN 'Medicare Traditional'
                        WHEN INSURANCE_COMPANY_OTHER__C LIKE '%Medicaid%' THEN 'Medicaid'
                        WHEN INSURANCE_COMPANY_OTHER__C LIKE '%Tricare%' THEN 'Tricare / VA'
                        WHEN INSURANCE_COMPANY_OTHER__C LIKE '%VA%' THEN 'Tricare / VA'
                        WHEN INSURANCE_COMPANY_OTHER__C LIKE '%HMO%' THEN 'Commercial'
                        WHEN INSURANCE_COMPANY_OTHER__C LIKE '%HMO' THEN 'Commercial'
                        WHEN INSURANCE_COMPANY_OTHER__C LIKE '%PPO%' THEN 'Commercial'
                        WHEN INSURANCE_COMPANY_OTHER__C LIKE '%commercial%' THEN 'Commercial'
                        WHEN INSURANCE_COMPANY_OTHER__C LIKE '%UHC%' THEN 'Commercial'
                        WHEN INSURANCE_COMPANY_OTHER__C LIKE '%United Health%' THEN 'Commercial'
                        WHEN INSURANCE_COMPANY_OTHER__C LIKE '%Humana%' THEN 'Commercial'
                        WHEN INSURANCE_COMPANY_OTHER__C LIKE '%BCBS%' THEN 'Commercial'
                        WHEN INSURANCE_COMPANY_OTHER__C LIKE '%AETNA%' THEN 'Commercial'
                        WHEN INSURANCE_COMPANY_OTHER__C LIKE 'Cigna%' THEN 'Commercial'
                        WHEN INSURANCE_COMPANY_OTHER__C LIKE 'Blue%' THEN 'Commercial'
                        ELSE 'Other'
                    END
                ) AS INSURANCE_MAIN,
                A.INSURANCETYPE__C,
                a.INSURANCE_TYPE__C,
                a.INSURANCE_COMPANY_OTHER__C,
                a.OPPORTUNITY_INSURANCE_TYPE__C,
                A.ISCLOSED,
                A.NAME,
                -- J2 is bringing in on A.SURGEON__C
                J2.NAME AS SURGEON,
                J2.SPECIALTY__C AS SURGEON_SPECIALTY,
                J2.ID AS SURGEON_ID,
                --J is bringing in on A.PATIENTSREFERRINGDOC__C
                J.NAME AS PHYSICIAN,
                J.SPECIALTY__C AS PHYSICIAN_SPECIALTY,
                J.ID AS PHYSICIAN_ID,
                J.MDR_Target__C [isMDRTarget?],
                -- J3 is bringing in on A.PRESCRIBER__C
                J3.NAME AS PRESCRIBER,
                J3.SPECIALTY__C AS PRESCRIBER_SPECIALTY,
                J3.ID AS PRESCRIBER_ID,
                CASE
                    WHEN LEFT(A.OPPORTUNITY_REGION__C, 3) = 'EU ' THEN 0
                    WHEN E.NAME = 'Financial Opportunity' THEN 0
                    WHEN A.REPLACEMENT_TYPE__C = 'CSL' THEN 0
                    /*     WHEN A.REASON_FOR_IMPLANT__C = 'De novo' AND a.INDICATION_FOR_USE__C = 'Heart Failure - Reduced Ejection Fraction' AND A.STAGENAME IN('Revenue Recognized', 'Procedure recognized', 'Implant Completed') THEN 1*/
                    WHEN A.REASON_FOR_IMPLANT__C = 'De novo'
                    AND a.INDICATION_FOR_USE__C = 'Heart Failure - Reduced Ejection Fraction' THEN 1
                    ELSE 0
                END AS REFERRABLE_UNITS,
                CASE
                    WHEN J.SPECIALTY__C LIKE '%elect%' THEN 'Electrophysiologist'
                    WHEN J.SPECIALTY__C LIKE '%card%' THEN 'Cardiologist'
                    WHEN J.SPECIALTY__C LIKE '%HF S%' THEN 'HF Specialist'
                    WHEN J.SPECIALTY__C IN (
                        'Nurse - Nurse Practitioner',
                        'Nurse Practitioner',
                        'Physician Assistant'
                    ) THEN 'NP/PA'
                    ELSE 'Other'
                END AS REFERRAL_TYPE,
                A.PATIENT_IPG_SERIAL_NUMBER__C,
                A.PO_RECEIVED__C,
                A.PO_REIMBURSEMENT_STATUS__C,
                A.PRIOR_AUTH_SUBMISSION_DATE__C,
                A.PRICEBOOK2ID,
                CASE
                    WHEN x.OPP_NAME IS NOT NULL THEN 'De Novo'
                    ELSE A.REASON_FOR_IMPLANT__C
                END AS REASON_FOR_IMPLANT__C,
                A.REPLACEMENT_TYPE__C,
                A.PROCEDURE_CODING__C,
                A.STAGENAME,
                A.SURGICAL_CONSULT_DATE__C,
                Ac.SURGICAL_CONSULT_DT,
                A.DATE_OF_INITIAL_CONSULT__C,
                H.PROCEDURE_DATE__C AS IMPLANTED_DT,
                TRIM(
                    CAST(tt3.YEAR AS VARCHAR) + '_' + RIGHT(
                        '0' + CAST(
                            MONTH(ISNULL(H.PROCEDURE_DATE__C, A.CLOSEDATE)) AS VARCHAR
                        ),
                        2
                    )
                ) AS IMPLANTED_YYYYMM,
                TRIM(
                    CAST(tt3.YEAR AS VARCHAR) + '_Q' + CAST(
                        DATEPART(
                            q,
                            ISNULL(H.PROCEDURE_DATE__C, A.CLOSEDATE)
                        ) AS VARCHAR
                    )
                ) AS IMPLANTED_YYYYQQ,
                tt3.YEAR AS IMPLANTED_YYYY,
                tt3.r12 AS IMPLANTED_R12,
                CASE
                    WHEN tt3.r12 = 'C12' THEN CASE
                        WHEN LEFT(A.OPPORTUNITY_REGION__C, 3) = 'EU ' THEN 0
                        WHEN E.NAME = 'Financial Opportunity' THEN 0
                        WHEN A.REPLACEMENT_TYPE__C = 'CSL' THEN 0
                        ELSE 1
                    END
                    ELSE NULL
                END AS IMPLANTED_UNITS_C12,
                CASE
                    WHEN A.STAGENAME = 'CANCELLED' THEN 'CANCELLED'
                    WHEN A.STAGENAME IN (
                        'Revenue Recognized',
                        'Procedure recognized',
                        'Implant Completed'
                    )
                    OR ISCLOSED = 1 THEN 'CLOSED'
                    ELSE 'OPEN'
                END AS OPP_STATUS,
                d.isAIC,
                CASE
                    WHEN PATIENT_IPG_SERIAL_NUMBER__C IS NULL
                    AND H.PROCEDURE_DATE__C IS NULL THEN 0
                    WHEN A.STAGENAME = 'Cancelled' THEN 0
                    ELSE 1
                END AS ISIMPL,
                A.LASTMODIFIEDDATE
            FROM
                dbo.sfdcOpps AS A
                LEFT JOIN (
                    SELECT
                        OPPORTUNITYID,
                        MAX(CREATEDDATE) SURGICAL_CONSULT_DT
                    FROM
                        qryOppStageHIST WITH (NOLOCK)
                    WHERE
                        STAGENAME IN ('Surgical Consult')
                    GROUP BY
                        OPPORTUNITYID
                ) AC ON A.ID = AC.OPPORTUNITYID
                LEFT OUTER JOIN dbo.qryUsers AS B ON A.OWNERID = B.ID
                LEFT OUTER JOIN dbo.qryUsers AS C ON A.ACCOUNT_OWNER_AT_IMPLANT_COMPLETE__C = C.ID
                LEFT OUTER JOIN dbo.qryCust AS D ON A.ACCOUNTID = D.ID
                LEFT OUTER JOIN dbo.sfdcAccount AS U ON A.ACCOUNTID = U.ID
                LEFT OUTER JOIN dbo.sfdcAccount AS II ON A.Primary_Insurance__c = II.ID
                LEFT OUTER JOIN dbo.qryUsers AS F ON D.OWNERID = F.ID
                LEFT OUTER JOIN dbo.sfdcRecordType AS E ON A.RECORDTYPEID = E.ID
                LEFT OUTER JOIN dbo.tblAlign_Opp AS G ON A.ID = G.OPP_ID
                LEFT OUTER JOIN dbo.sfdcProc AS H ON A.RELATED_PROCEDURE__C = H.ID
                AND (
                    H.STAGE__C = 'Implanted'
                    OR h.REASON__C = 'De novo - BATwire'
                )
                LEFT OUTER JOIN dbo.sfdcProc AS H2 ON A.RELATED_PROCEDURE__C = H2.ID
                LEFT OUTER JOIN dbo.sfdcContact AS J ON A.PATIENTSREFERRINGDOC__C = J.ID
                LEFT OUTER JOIN dbo.sfdcContact AS J2 ON h2.SURGEON__C = J2.ID
                LEFT OUTER JOIN sfdcContact AS J3 ON A.PRESCRIBER__C = J3.ID
                LEFT OUTER JOIN dbo.qryCalendar AS TT ON CAST(A.CREATEDDATE AS DATE) = TT.DT
                LEFT OUTER JOIN dbo.qryCalendar AS TT3 ON ISNULL(H.PROCEDURE_DATE__C, A.CLOSEDATE) = TT3.DT
                LEFT OUTER JOIN dbo.qryUsers AS FF ON A.ACCOUNT_OWNER_AT_IMPLANT_COMPLETE__C = FF.ID
                LEFT OUTER JOIN dbo.qryUsers AS FFF ON A.CREATEDBYID = fff.ID
                LEFT JOIN tblOppEx X ON x.TYPE = 'De Novo'
                AND a.NAME = x.OPP_NAME
            WHERE
                (
                    A.ACCOUNTID NOT IN (
                        '0010g00001kjr7dAAA',
                        '0010g00001XbJ4QAAV',
                        '0010g00001lEIEdAAO'
                    )
                )
                AND ACCOUNT_INDICATION__C NOT LIKE '%TEST%'
        ) AS T
),
VA_HCA AS (
    /** use this to get ASP for VA and HCA accounts **/
    SELECT
        DHC_IDN_NAME__C,
        SUM(SALES) [SALES_r12],
        SUM(REVENUE_UNITS) [REV_UNITS_R12],
        SUM(SALES) / SUM(REVENUE_UNITS) [ASP_r12]
    FROM
        [qOpps]
    WHERE
        DHC_IDN_NAME__C IN (
            'Department of Veterans Affairs',
            'HCA Healthcare'
        )
        AND CLOSE_YYYYMM IN (
            SELECT
                DISTINCT YYYYMM
            FROM
                qryCalendar
            WHERE
                R12 = 'C12'
        )
        AND OPP_STATUS = 'CLOSED'
    GROUP BY
        DHC_IDN_NAME__C
)
SELECT
    A.*,
    CASE
        WHEN VA_HCA.ASP_r12 IS NOT NULL
        AND ISIMPL = 1 THEN VA_HCA.ASP_r12
        WHEN VA_HCA.ASP_r12 IS NOT NULL
        AND ISIMPL = 0 THEN 0
        WHEN STAGENAME = 'Revenue Recognized'
        AND VA_HCA.ASP_r12 IS NULL THEN SALES
        ELSE 0
    END AS SALES_COMMISSIONABLE
FROM
    qOpps A
    LEFT JOIN VA_HCA ON A.DHC_IDN_NAME__C = VA_HCA.DHC_IDN_NAME__C