SELECT
    dbo_qry_COMP_FCE_DETAIL.*,
    dbo_qry_COMP_FCE_DETAIL.ACCOUNT AS ACT_NAME,
    0 AS SALES_REPLC,
    0 AS UNITS_REPLC INTO tmpPO_Detail
FROM
    dbo_qry_COMP_FCE_DETAIL
WHERE
    (
        (
            (dbo_qry_COMP_FCE_DETAIL.SALES_CREDIT_FCE_EMAIL) = EID()
        )
        AND (
            (dbo_qry_COMP_FCE_DETAIL.CLOSE_YYYYMM) =(
                SELECT
                    Max(dbo_tblPayout.YYYYMM) AS MaxOfYYYYMM
                FROM
                    dbo_tblPayout
            )
        )
        AND ((dbo_qry_COMP_FCE_DETAIL.SALES_BASE) > 0)
    )
    OR (
        (
            (dbo_qry_COMP_FCE_DETAIL.SALES_CREDIT_FCE_EMAIL) = EID()
        )
        AND (
            (dbo_qry_COMP_FCE_DETAIL.CLOSE_YYYYMM) =(
                SELECT
                    Max(dbo_tblPayout.YYYYMM) AS MaxOfYYYYMM
                FROM
                    dbo_tblPayout
            )
        )
        AND ((dbo_qry_COMP_FCE_DETAIL.SALES_TGT) > 0)
    );