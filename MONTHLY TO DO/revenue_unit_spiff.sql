DECLARE @YYYYMM NVARCHAR(7) = '2024_08'
-- INSERT INTO
--     tblCPAS_PO
SELECT
    OPP_ID,
    NULL AS CASENUMBER,
    SALES_CREDIT_REP_EMAIL AS EMAIL,
    'REP' AS [ROLE],
    SPIFF_PO AS PO,
    NULL AS PO_RECOUP,
    @YYYYMM AS SPIF_PO_YYYYMM,
    NULL AS NOTES,
    'REVENUE' AS SPIF_TYPE
FROM
    qry_COMP_REVENUE_UNIT_SPIFF
WHERE
    OPP_ID NOT IN (
        SELECT
            OPP_ID
        FROM
            tblCPAS_PO
        WHERE
            SPIF_TYPE = 'REVENUE'
    )