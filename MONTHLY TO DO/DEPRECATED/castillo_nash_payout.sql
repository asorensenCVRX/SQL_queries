DECLARE @BL AS INT DECLARE @QUOTA AS INT DECLARE @YYYY_QQ AS VARCHAR(10)
SET
    @BL = 205875 -- update to the current quarter's baseline
SET
    @QUOTA = 274500 -- update to the current quarter's quota
SET
    @YYYY_QQ = '2024_Q2' -- update to the current quarter
SELECT
    A.*,
    SALES * 0.15
    /* <-- rate goes here*/
    AS PO,
    CASE
        WHEN Q0_SALES > @BL THEN 'yes'
        ELSE 'no'
    END AS [OVER_BL?]
FROM
    (
        SELECT
            Q.ACCOUNT_INDICATION__C,
            Q.ACCOUNT_OWNER_ALIAS__C,
            OPP_ID,
            O.NAME,
            OPP_OWNER_NAME,
            OPP_OWNER_ALIAS,
            Q.INDICATION_FOR_USE__C,
            Q.REASON_FOR_IMPLANT__C,
            Q.CLOSEDATE,
            CLOSE_YYYYMM,
            CLOSE_YYYYQQ,
            RECORD_TYPE,
            REVENUE_UNITS,
            SALES,
            Q.AMOUNT,
            SUM(SALES) OVER(
                ORDER BY
                    Q.CLOSEDATE,
                    OPP_ID
            ) AS Q0_SALES,
            SUM(SALES) OVER(
                ORDER BY
                    Q.CLOSEDATE,
                    OPP_ID
            ) / @QUOTA AS [%_TO_QUOTA]
        FROM
            qryOpps AS Q
            LEFT JOIN sfdcOpps AS O ON Q.OPP_ID = O.ID
        WHERE
            SHIPPINGSTATECODE IN ('UT')
            AND OPP_STATUS = 'CLOSED'
            AND CLOSE_YYYYQQ = @YYYY_QQ
    ) AS A -- QUOTA FOR TERR_24 = 1098000
    -- Q2 BL = 205875