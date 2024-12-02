DECLARE @SUBMIT_YYYYMM NVARCHAR(7) = '2024_11',
@PO_YYYYMM NVARCHAR(7) = '2024_11' 
-- INSERT INTO
--        tblCPAS_PO
SELECT
       DISTINCT *
FROM
       (
              SELECT
                     OPP_ID,
                     CASENUMBER,
                     AM_EMAIL,
                     'REP' AS [ROLE],
                     AM_PO,
                     NULL AS PO_RECOUP_NQ,
                     --sales,
                     --    TOTALOPPORTUNITYQUANTITY, 
                     @PO_YYYYMM AS PO_YYYYMM,
                     -- TotalCases,
                     NULL AS notes,
                     'CPAS' AS SPIF_TYPE --,[isEligibleForPaymentThisPeriod?]
              FROM
                     [dbo].[qry_COMP_CPAS_SPIF]
              WHERE
                     [isAMQualified?] = 1
                     AND [IsOppPaid?] = 0
                     AND CPAS_SUBMIT_YYYYMM = @SUBMIT_YYYYMM
              UNION
              ALL
              SELECT
                     OPP_ID,
                     CASENUMBER,
                     CSR_EMAIL,
                     'CSR' AS [ROLE],
                     CSR_PO,
                     NULL,
                     --sales,
                     --    TOTALOPPORTUNITYQUANTITY, 
                     @PO_YYYYMM AS PO_YYYYMM,
                     -- TotalCases,
                     NULL AS notes,
                     'CPAS' AS SPIF_TYPE
              FROM
                     [dbo].[qry_COMP_CPAS_SPIF]
              WHERE
                     [iscsrqualified?] = 1
                     AND [IsOppPaid?] = 0
                     AND CSR_EMAIL IS NOT NULL
                     AND CPAS_SUBMIT_YYYYMM = @SUBMIT_YYYYMM
       ) AS A