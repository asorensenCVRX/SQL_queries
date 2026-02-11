DECLARE @PREV_YYYYMM VARCHAR(7) = FORMAT(DATEADD(MONTH, -1, GETDATE()), 'yyyy_MM');

SELECT
    *
    /******/
    -- INTO tmpATM_PO
    /******/
FROM
    (
        SELECT
            CLOSE_YYYYMM AS YYYYMM,
            CLOSE_YYYYQQ AS YYYYQQ,
            ATM_EMAIL,
            ATM_NAME,
            REGION,
            ISNULL(
                SUM(
                    CASE
                        WHEN IMPLANTED_YYYYMM = @PREV_YYYYMM THEN IMPLANT_UNITS
                        ELSE 0
                    END
                ),
                0
            ) AS IMPLANT_UNITS,
            ISNULL(
                SUM(
                    CASE
                        WHEN CLOSE_YYYYMM = @PREV_YYYYMM THEN REVENUE_UNITS
                        ELSE 0
                    END
                ),
                0
            ) AS REVENUE_UNITS,
            ISNULL(
                SUM(
                    CASE
                        WHEN CLOSE_YYYYMM = @PREV_YYYYMM THEN SALES_COMMISSIONABLE
                        ELSE 0
                    END
                ),
                0
            ) AS SALES_COMMISSIONABLE,
            ISNULL(SUM(PAYOUT), 0) AS PAYOUT
        FROM
            qry_COMP_ATM_DETAIL
        GROUP BY
            CLOSE_YYYYMM,
            CLOSE_YYYYQQ,
            ATM_EMAIL,
            ATM_NAME,
            REGION
    ) AS A
WHERE
    YYYYMM = @PREV_YYYYMM