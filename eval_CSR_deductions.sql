SELECT
    *,
    sum(TGT_PO) over (
        PARTITION by PAID_TO_EMAIL
        ORDER BY
            CLOSEDATE,
            OPP_ID
    ) AS TOTAL_PAID
FROM
    (
        SELECT
            A.SALES_CREDIT_FCE_EMAIL AS PAID_TO_EMAIL,
            A.NAME_REP AS PAID_TO_NAME,
            CASE
                WHEN AO.EMAIL IS NULL THEN O.OPP_OWNER_EMAIL
                ELSE AO.EMAIL
            END AS DEDUCTED_FROM_EMAIL,
            A.OPP_ID,
            CASE
                WHEN A.TYPE = 'ACCT' THEN O.ACT_ID
                WHEN A.TYPE = 'DOC' THEN O.PHYSICIAN_ID
            END AS OBJ_ID,
            CASE
                WHEN A.TYPE = 'ACCT' THEN O.ACCOUNT_INDICATION__C
                WHEN A.TYPE = 'DOC' THEN O.PHYSICIAN
            END AS [DESCRIPTION],
            O.REASON_FOR_IMPLANT__C,
            A.CLOSEDATE,
            A.CLOSE_YYYYMM,
            A.TGT_PO,
            A.TYPE
        FROM
            [dbo].[qry_COMP_FCE_DETAIL] A
            LEFT JOIN tblAlign_Opp AO ON AO.OPP_ID = A.OPP_ID
            LEFT JOIN qryOpps O ON A.OPP_ID = O.OPP_ID
        WHERE
            A.TGT_PO > 0
    ) AS A
WHERE
    CLOSE_YYYYMM = '2024_08'
    /***** INTEGRITY CHECK *******/
    -- AND DEDUCTED_FROM_EMAIL = PAID_TO_EMAIL