/* if a CPAS payout shows up on this table, it means the account it is credited to
 has an active split. Check all cases in this table to make sure POs are properly split
 according to account splits. */
DECLARE @YYYY_MM AS NVARCHAR(7) = '2024_12'
SELECT
    CASENUMBER,
    REP_PO_YYYYMM,
    CSR_PO_YYYYMM,
    OPP_COMP_YYYYMM,
    AM_EMAIL,
    CSR_EMAIL,
    ACT_ID,
    ACCOUNT_NAME,
    AM_PO,
    RANK() OVER(
        PARTITION BY CASENUMBER
        ORDER BY
            AM_EMAIL
    ) AS SPLIT_NUMBER
FROM
    (
        SELECT
            DISTINCT OPP_ID,
            OPP_NAME,
            CASENUMBER,
            REP_PO_YYYYMM,
            CSR_PO_YYYYMM,
            OPP_COMP_YYYYMM,
            C.ACT_ID,
            C.AM_EMAIL,
            CSR_EMAIL,
            AM_PO,
            CSR_PO,
            A.NAME AS ACCOUNT_NAME,
            CASE
                WHEN YYYYMM_END IS NULL THEN NULL
                ELSE CONVERT(
                    DATE,
                    REPLACE(CONCAT(YYYYMM_END, '_30'), '_', '-')
                )
            END AS YYYYMM_END
        FROM
            qry_COMP_CPAS_SPIF C
            LEFT JOIN (
                SELECT
                    DISTINCT NAME,
                    ACT_ID,
                    YYYYMM_END,
                    NOTES
                FROM
                    tblActSplits
            ) A ON C.ACT_ID = A.ACT_ID
        WHERE
            REP_PO_YYYYMM = @YYYY_MM
    ) AS A
WHERE
    YYYYMM_END >= FORMAT(
        DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 1, 0),
        'yyyy-MM-dd'
    )
ORDER BY
    CASENUMBER;