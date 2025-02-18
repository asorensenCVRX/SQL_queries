DECLARE @YYYY_MM AS NVARCHAR(7) = '2025_01';


-- INSERT INTO
--     tblAlign_Opp
SELECT
    ACT_ID,
    OPP_ID,
    R.LNAME_REP,
    (
        SELECT
            DISTINCT TOP 1 [Customer #]
        FROM
            [tblAlign_Opp] A
        WHERE
            A.ACT_ID = TM.ACT_ID
    ) AS [CUSTOMER],
    CASE
        WHEN INDICATION_FOR_USE__C = 'Hypertension' THEN 'HTN'
        ELSE 'HF'
    END AS [Indication],
    SALES_CREDIT_REP_EMAIL,
    R.REP_ID
    /****** DEBUGGING FIELDS ******/
-- ,
--     A.EMAIL AS SFDC_ACCOUNT_OWNER_EMAIL,
--     TM.OPP_OWNER_EMAIL,
--     R.DOT AS SALES_CREDIT_REP_DOT
    /*********************/
FROM
    qry_COMP_TM_DETAIL TM
    LEFT JOIN qryRoster R ON R.REP_EMAIL = TM.SALES_CREDIT_REP_EMAIL
    AND R.[isLATEST?] = 1
    LEFT JOIN (
        SELECT
            A.ID,
            A.NAME,
            U.EMAIL
        FROM
            sfdcAccount A
            LEFT JOIN sfdcUser U ON A.OWNERID = U.ID
    ) A ON A.ID = TM.ACT_ID
WHERE
    CLOSE_YYYYMM = @YYYY_MM
    AND CLOSEDATE IS NOT NULL
    AND STAGENAME = 'Revenue Recognized'
    /******** INTEGRITY CHECKS *******/
    -- AND (
    --     SALES_CREDIT_REP_EMAIL <> A.EMAIL
    --     OR SALES_CREDIT_REP_EMAIL <> CASE
    --         WHEN OPP_OWNER_EMAIL = 'gtemplin@cvrx.com' THEN SALES_CREDIT_REP_EMAIL
    --         ELSE OPP_OWNER_EMAIL
    --     END
    --     OR A.EMAIL <> CASE
    --         WHEN OPP_OWNER_EMAIL = 'gtemplin@cvrx.com' THEN SALES_CREDIT_REP_EMAIL
    --         ELSE OPP_OWNER_EMAIL
    --     END
    -- )