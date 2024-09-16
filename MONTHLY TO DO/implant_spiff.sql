DECLARE @IMPLANTED_YYYYMM AS NVARCHAR(7) = '2024_08';


/****** INSERT ******/
-- INSERT INTO
--     tblCPAS_PO
/********************/
SELECT
    OPP_ID,
    NULL AS CASENUMBER,
    SPIFF_CREDIT_EMAIL,
    CASE
        WHEN SPIFF_CREDIT_EMAIL = 'ycruea@cvrx.com' THEN 'CSR'
        ELSE R.ROLE
    END AS [ROLE],
    2500 AS PO,
    NULL AS PO_RECOUP_NQ,
    @IMPLANTED_YYYYMM AS SPIF_PO_YYYYMM,
    NULL AS NOTES,
    'IMPLANT' AS SPIF_TYPE
FROM
    qry_COMP_IMPLANT_SPIF C
    LEFT JOIN (
        SELECT
            REP_EMAIL,
            ROLE
        FROM
            qryRoster
        WHERE
            [isLATEST?] = 1
            AND STATUS = 'ACTIVE'
        UNION
        SELECT
            EMP_EMAIL,
            ROLE
        FROM
            qryRoster_RM
        WHERE
            [isLatest?] = 1
    ) R ON C.SPIFF_CREDIT_EMAIL = R.REP_EMAIL
WHERE
    IMPLANTED_YYYYMM = @IMPLANTED_YYYYMM
    AND IMPLANT_NUMBER <= 6
    AND OPP_ID NOT IN (
        SELECT
            OPP_ID
        FROM
            tblCPAS_PO
        WHERE
            SPIF_TYPE = 'IMPLANT'
    )