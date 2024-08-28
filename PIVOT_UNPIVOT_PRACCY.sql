-- PIVOT converts rows into columns
-- UNPIVOT converts columns into rows
SELECT
    *
FROM
    (
        SELECT
            YYYYMM,
            CATEGORY,
            CAST(VALUE AS MONEY) AS VALUE
        FROM
            tblPayout
        WHERE
            eid = 'jclemmons@cvrx.com'
            AND YYYYMM IN ('2024_04', '2024_05')
            AND CATEGORY IN (
                'AM_L1_REV',
                'AM_L1_PO',
                'AM_L2_REV',
                'AM_L2_PO',
                'FCE_DEDUCTION',
                'CPAS_SPIFF_PO',
                'PO_AMT'
            )
    ) AS SOURCE PIVOT (SUM(VALUE) FOR YYYYMM IN ([2024_04], [2024_05])) AS PIVOT_TABLE