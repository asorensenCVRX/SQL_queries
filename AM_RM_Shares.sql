-- CREATE VIEW qryQ2_REP_IMPLANT_ROSTER AS
-- SELECT
--     SALES_CREDIT_REP_EMAIL,
--     B.ROLE,
--     B.[isTM?],
--     L.TM_EMAIL,
--     B.RM_EMAIL,
--     CASE
--         /* Kyle Wolf went on LOA 7/19, 2 accounts moved to Jordan Viduna and 9 moved to D Harper (not an AM until 7/1) */
--         WHEN SALES_CREDIT_REP_EMAIL = 'jviduna@cvrx.com' THEN 1
--         WHEN SALES_CREDIT_REP_EMAIL = 'kwolf@cvrx.com' THEN 11
--         ELSE SUM(IMPLANT_UNITS_SPLIT)
--     END AS IMPLANT_UNITS
-- FROM
--     /****** Q2 IMPLANTS START *****/
--     (
--         SELECT
--             A.ACCOUNT_INDICATION__C,
--             A.ACCOUNT_OWNER_ALIAS__C,
--             A.ISACU,
--             A.OPP_ID,
--             A.ACT_ID,
--             CASE
--                 WHEN b.ACT_ID IS NOT NULL THEN 1
--                 ELSE 0
--             END AS [isSplit?],
--             A.SHIPPINGSTATECODE,
--             A.SHIPPINGCITY,
--             A.OPPORTUNITY_REGION__C,
--             A.OPP_COUNTRY,
--             A.SALES_CREDIT_REP,
--             ISNULL(
--                 B.REP_EMAIL,
--                 ISNULL(A.SALES_CREDIT_REP_EMAIL, A.OPP_OWNER_EMAIL)
--             ) AS SALES_CREDIT_REP_EMAIL,
--             A.OPP_OWNER_NAME,
--             A.OPP_OWNER_LNAME,
--             A.OPP_OWNER_ALIAS,
--             A.OPP_OWNER_EMAIL,
--             A.OPP_OWNER_TITLE,
--             A.OPP_OWNER_ISACTIVE,
--             A.OPP_OWNER_REGION,
--             A.REG_ID AS OPP_OWNER_REGION_ID,
--             A.ACT_OWNER_NAME,
--             A.ACT_OWNER_LNAME,
--             A.ACT_OWNER_ALIAS,
--             A.ACT_OWNER_TITLE,
--             A.ACT_OWNER_EMAIL,
--             A.ACT_OWNER_ISACTIVE,
--             A.ACT_OWNER_REGION,
--             A.PHYSICIAN,
--             A.PHYSICIAN_SPECIALTY,
--             A.RECORD_TYPE,
--             A.IMPLANT_COMPLETE_NAME,
--             A.IMPLANT_COMPLETE_REGION,
--             A.TOTALOPPORTUNITYQUANTITY,
--             CASE
--                 WHEN REASON_FOR_IMPLANT__C = 'De novo' THEN TOTALOPPORTUNITYQUANTITY
--                 ELSE 0
--             END AS TOTALOPPORTUNITYQUANTITY_NEW,
--             CASE
--                 WHEN REASON_FOR_IMPLANT__C = 'Replacement' THEN TOTALOPPORTUNITYQUANTITY
--                 ELSE 0
--             END AS TOTALOPPORTUNITYQUANTITY_REPLC,
--             A.IMPLANT_UNITS,
--             CASE
--                 WHEN B.SPLIT IS NOT NULL THEN A.IMPLANT_UNITS * B.SPLIT
--                 ELSE A.IMPLANT_UNITS
--             END [IMPLANT_UNITS_SPLIT],
--             A.CREATEDDATE,
--             A.CREATED_YYYYMM,
--             A.CREATED_YYYY,
--             A.CLOSEDATE,
--             A.CLOSE_YYYYMM,
--             A.CLOSE_YYYYQQ,
--             A.CLOSE_YYYY,
--             A.SALES,
--             CASE
--                 WHEN REASON_FOR_IMPLANT__C = 'De novo' THEN SALES
--                 ELSE 0
--             END AS SALES_NEW,
--             CASE
--                 WHEN REASON_FOR_IMPLANT__C = 'Replacement' THEN SALES
--                 ELSE 0
--             END AS SALES_REPLC,
--             A.ASP,
--             A.INDICATION_FOR_USE__C,
--             A.ISCLOSED,
--             A.NAME,
--             A.PATIENT_IPG_SERIAL_NUMBER__C,
--             A.PO_RECEIVED__C,
--             A.PO_REIMBURSEMENT_STATUS__C,
--             A.REASON_FOR_IMPLANT__C,
--             A.REPLACEMENT_TYPE__C,
--             A.STAGENAME,
--             A.INTERESTED_DT,
--             A.IMPLANTED_DT,
--             A.IMPLANTED_YYYYMM,
--             A.IMPLANTED_YYYY,
--             A.IMPLANTED_YYYYQQ,
--             A.ISIMPL,
--             A.REGION,
--             ISNULL(
--                 A.SALES_CREDIT_RM,
--                 (
--                     SELECT
--                         DISTINCT D.RM_EMAIL
--                     FROM
--                         qryRoster D
--                     WHERE
--                         D.REP_EMAIL = ISNULL(
--                             B.REP_EMAIL,
--                             ISNULL(A.SALES_CREDIT_REP_EMAIL, A.OPP_OWNER_EMAIL)
--                         )
--                         AND [isLATEST?] = 1
--                 )
--             ) [SALES_CREDIT_RM],
--             A.isAIC,
--             A.PHYSICIAN_ID,
--             A.REFERRAL_TYPE,
--             A.[isMDRTarget?],
--             A.OPPORTUNITY_SOURCE__C
--         FROM
--             dbo.qryOpps AS A
--             LEFT JOIN tblActSplits B ON A.ACT_ID = B.ACT_ID
--             AND IMPLANTED_YYYYMM BETWEEN b.YYYYMM_ST
--             AND b.YYYYMM_END
--         WHERE
--             A.STAGENAME IN('Revenue Recognized', 'Implant Completed')
--             AND IMPLANTED_YYYYQQ = '2024_Q2'
--             AND OPP_COUNTRY = 'US'
--             AND INDICATION_FOR_USE__C = 'Heart Failure - Reduced Ejection Fraction'
--             AND REASON_FOR_IMPLANT__C = 'De Novo'
--     ) AS A
--     /****** Q2 IMPLANTS END ******/
--     LEFT JOIN qryRoster B ON A.SALES_CREDIT_REP_EMAIL = B.REP_EMAIL
--     LEFT JOIN qryReport_Ladder L ON A.SALES_CREDIT_REP_EMAIL = L.REP_EMAIL
-- WHERE
--     B.[isLATEST?] = 1
--     AND B.REP_EMAIL <> 'dharper@cvrx.com'
-- GROUP BY
--     SALES_CREDIT_REP_EMAIL,
--     B.ROLE,
--     L.TM_EMAIL,
--     B.[isTM?],
--     B.RM_EMAIL
-- UNION
-- SELECT
--     EMP_EMAIL,
--     ROLE,
--     NULL,
--     NULL,
--     NULL,
--     NULL
-- FROM
--     qryRoster_RM;
;


SELECT
    qryQ2_REP_IMPLANT_ROSTER.*,
    TM.implant_units AS TM_DIRECT_REPORT_IMPLANTS,
    /****** if a rep had an implant in their name, they get 60 shares *****/
    qryQ2_REP_IMPLANT_ROSTER.IMPLANT_UNITS * 60 AS AM_TM_SELF,
    ASD.ASD_FROM_AM_TM,
    TM.TM_FROM_AM,
    RM_TM.RM_FROM_TM AS ASD_FROM_TM_AM,
    RM_ASD.ASD_FROM_RM_AM --INTO tmpOptions
FROM
    qryQ2_REP_IMPLANT_ROSTER
    /***** START ASD *****/
    -- ASDs get 40 shares for each implant that occured for an AM who does NOT report to a TM and does NOT report to an RM
    LEFT JOIN (
        SELECT
            RM_EMAIL,
            sum(implant_units) AS implant_units,
            SUM(IMPLANT_UNITS) * 40 AS ASD_FROM_AM_TM
        FROM
            qryQ2_REP_IMPLANT_ROSTER
        WHERE
            -- pulls in all AMs that DO NOT report to a TM
            SALES_CREDIT_REP_EMAIL IN (
                SELECT
                    EID
                FROM
                    qryRates_AM
                WHERE
                    TM_EID IS NULL
            )
        GROUP BY
            RM_EMAIL
    ) ASD ON qryQ2_REP_IMPLANT_ROSTER.SALES_CREDIT_REP_EMAIL = ASD.RM_EMAIL
    /***** END ASD *****/
    /***** START TM *****/
    -- TMs get 40 shares for each implant for a direct report
    LEFT JOIN (
        SELECT
            TM_EID,
            sum(implant_units) AS implant_units,
            sum(implant_units) * 40 AS TM_FROM_AM
        FROM
            qryQ2_REP_IMPLANT_ROSTER
            LEFT JOIN (
                -- pulls in all reps who report to a TM
                SELECT
                    EID,
                    TM_EID
                FROM
                    qryRates_AM
                WHERE
                    TM_EID IS NOT NULL
            ) TM ON qryQ2_REP_IMPLANT_ROSTER.SALES_CREDIT_REP_EMAIL = TM.EID
        GROUP BY
            TM_EID
    ) TM ON qryQ2_REP_IMPLANT_ROSTER.SALES_CREDIT_REP_EMAIL = TM.TM_EID
    /***** END TM *****/
    /***** START RM_TM *****/
    -- ASDs get 20 shares for each implant that occured for an AM who reports to a TM
    LEFT JOIN (
        SELECT
            RM_EMAIL,
            sum(implant_units) AS implant_units,
            sum(implant_units) * 20 AS RM_FROM_TM
        FROM
            qryRoster
            RIGHT JOIN (
                SELECT
                    TM_EID,
                    sum(implant_units) AS implant_units,
                    sum(implant_units) * 40 AS TM_FROM_AM
                FROM
                    qryQ2_REP_IMPLANT_ROSTER
                    LEFT JOIN (
                        SELECT
                            EID,
                            TM_EID
                        FROM
                            qryRates_AM
                        WHERE
                            TM_EID IS NOT NULL
                    ) TM ON qryQ2_REP_IMPLANT_ROSTER.SALES_CREDIT_REP_EMAIL = TM.EID
                GROUP BY
                    TM_EID
            ) TM ON qryRoster.REP_EMAIL = TM.TM_EID
        WHERE
            [isTM?] = 1
        GROUP BY
            RM_EMAIL
    ) RM_TM ON qryQ2_REP_IMPLANT_ROSTER.SALES_CREDIT_REP_EMAIL = RM_TM.RM_EMAIL
    /***** END RM_TM *****/
    /***** START RM_ASD *****/
    -- ASDs get 20 shares for each implant that occured for a rep who reports to kdenton, jgarner, ccastillo (RMs)
    LEFT JOIN (
        SELECT
            CASE
                WHEN RM_EMAIL = 'ccastillo@cvrx.com' THEN 'mbrown@cvrx.com'
                WHEN RM_EMAIL = 'jgarner@cvrx.com' THEN 'jheimsoth@cvrx.com'
                WHEN RM_EMAIL = 'kdenton@cvrx.com' THEN 'pknight@cvrx.com'
            END AS ASD_EMAIL,
            sum(implant_units) AS implant_units,
            sum(implant_units) * 20 AS ASD_FROM_RM_AM
        FROM
            qryQ2_REP_IMPLANT_ROSTER
        WHERE
            rm_email IN (
                'kdenton@cvrx.com',
                'jgarner@cvrx.com',
                'ccastillo@cvrx.com'
            )
        GROUP BY
            RM_EMAIL
    ) RM_ASD ON qryQ2_REP_IMPLANT_ROSTER.SALES_CREDIT_REP_EMAIL = RM_ASD.ASD_EMAIL
    /***** END RM_ASD *****/
;


-- SELECT
--     *,
--     NULL AS NOTES INTO tblOptionsPayout
-- FROM
--     (
--         SELECT
--             '2024_Q2' AS YYYYQQ,
--             SALES_CREDIT_REP_EMAIL AS EID,
--             [ROLE],
--             CAST(IMPLANT_UNITS AS VARCHAR(MAX)) AS IMPLANTS,
--             CAST(TM_DIRECT_REPORT_IMPLANTS AS VARCHAR(MAX)) AS TM_DIRECT_REPORT_IMPLANTS,
--             CAST(AM_TM_SELF AS VARCHAR(MAX)) AS SELF_SHARES,
--             CAST(ASD_FROM_AM_TM AS VARCHAR(MAX)) AS ASD_FROM_AM_TM,
--             CAST(TM_FROM_AM AS VARCHAR(MAX)) AS TM_FROM_AM,
--             CAST(ASD_FROM_TM_AM AS VARCHAR(MAX)) AS ASD_FROM_TM_AM,
--             CAST(ASD_FROM_RM_AM AS VARCHAR(MAX)) AS ASD_FROM_RM_AM
--         FROM
--             tmpOptions
--     ) AS SOURCE UNPIVOT (
--         [VALUE] FOR CATEGORY IN (
--             [IMPLANTS],
--             [TM_DIRECT_REPORT_IMPLANTS],
--             [SELF_SHARES],
--             [ASD_FROM_AM_TM],
--             [TM_FROM_AM],
--             [ASD_FROM_TM_AM],
--             [ASD_FROM_RM_AM]
--         )
--     ) AS PVT;