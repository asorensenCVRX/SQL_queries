DECLARE @YYYY_MM AS NVARCHAR(7) = '2024_08';


-- INSERT INTO  tblAlign_Opp
SELECT
    --start--
    A.[ACT_ID],
    A.[OPP_ID],
    CASE
        WHEN c.REP_ID IS NOT NULL THEN c.LNAME_REP
        ELSE OPP_OWNER_LNAME
    END AS [L_NAME],
    (
        SELECT
            DISTINCT TOP 1 [Customer #]
        FROM
            [dbo].[tblAlign_Opp] B
        WHERE
            B.ACT_ID = A.ACT_ID
    ) AS [CUSTOMER],
    CASE
        WHEN INDICATION_FOR_USE__C = 'Hypertension' THEN 'HTN'
        ELSE 'HF'
    END AS [Indication],
    CASE
        WHEN c.REP_ID IS NOT NULL THEN AM_FOR_CREDIT_EMAIL
        ELSE OPP_OWNER_EMAIL
    END AS [EID],
    CASE
        WHEN c.REP_ID IS NOT NULL THEN c.REP_ID
        ELSE OPP_OWNER_ID
    END AS [SFDC_ID] --end--
    ---Debugging Fields----
    -- ,
    --     z.*,
    --     AM_FOR_CREDIT_EMAIL,
    --     c.REP_ID [AM_FOR_CREDIT_ID],
    --     z.Rep,
    --     a.AM_FOR_CREDIT,
    --     a.OPP_OWNER_EMAIL,
    --     a.OPP_OWNER_ID,
    --     a.ACCOUNT_INDICATION__C,
    --     a.SALES,
    --     a.TOTALOPPORTUNITYQUANTITY,
    --     a.INDICATION_FOR_USE__C,
    --     a.REASON_FOR_IMPLANT__C,
    --     a.ACT_OWNER_NAME,
    --     a.CLOSEDATE,
    --     b.NAME_REP,
    --     b.ROLE,
    --     b.STATUS,
    --     b.DOT,
    --     a.SALES,
    --     a.TOTALOPPORTUNITYQUANTITY,
    --     ACT_OWNER_EMAIL,
    --     SALES_CREDIT_REP_EMAIL,
    --     b.role
FROM
    qryOpps A
    LEFT JOIN qryRoster B ON a.OPP_OWNER_EMAIL = b.REP_EMAIL
    AND b.[isLATEST?] = 1
    LEFT JOIN qryRoster C ON a.AM_FOR_CREDIT_EMAIL = C.REP_EMAIL
    AND c.[isLATEST?] = 1
    LEFT JOIN tblAlign_Opp Z ON a.OPP_ID = z.OPP_ID
WHERE
    (
        CLOSE_YYYYMM = @YYYY_MM
        AND OPP_COUNTRY = 'US'
        AND OPP_STATUS = 'CLOSED'
        AND STAGENAME = 'Revenue Recognized'
        AND ISNULL(sales, 0) <> 0
    ) ------------Integrity Checks
    -- AND (
    --     OPP_OWNER_EMAIL <> ACT_OWNER_EMAIL
    --     OR OPP_OWNER_EMAIL <> SALES_CREDIT_REP_EMAIL
    --     OR OPP_OWNER_EMAIL <> AM_FOR_CREDIT_EMAIL
    --     OR ACT_OWNER_EMAIL <> SALES_CREDIT_REP_EMAIL
    -- ) 
    ------------Integrity Checks
    -- AND z.OPP_ID is not null  
    -- and Z.OPP_ID IN ('0064u00001HnevLAAR')
    -- and a.OPP_ID = '0064u00001HnevLAAR'
ORDER BY
    a.CLOSEDATE,
    b.region,
    b.DOT DESC,
    NAME;