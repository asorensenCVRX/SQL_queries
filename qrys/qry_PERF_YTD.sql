SELECT
    o.OPP_ID,
    o.NAME AS OPP_NAME,
    o.REASON_FOR_IMPLANT__C,
    o.ACT_OWNER_REGION,
    o.STAGENAME,
    ISNULL(
        ISNULL(
            ISNULL(
                ISNULL(A.REP_EMAIL, SS.SALES_CREDIT_REP_EMAIL),
                o.SALES_CREDIT_REP_EMAIL
            ),
            /* should this actually be OPP_OWNER_EMAIL like in our comp queries? */
            o.AM_FOR_CREDIT_EMAIL
        ),
        o.ACT_OWNER_EMAIL
    ) AS SALES_CREDIT_REP_EMAIL,
    ISNULL(ISNULL(A.SPLIT, SS.SPLIT), 1) AS SPLIT,
    ISNULL(ISNULL(A.SPLIT, SS.SPLIT), 1) * ISNULL(o.IMPLANT_UNITS, 0) AS IMPLANT_UNITS,
    ISNULL(ISNULL(A.SPLIT, SS.SPLIT), 1) * ISNULL(o.TOTALOPPORTUNITYQUANTITY, 0) AS QTY,
    CAST(
        ISNULL(ISNULL(A.SPLIT, SS.SPLIT), 1) * ISNULL(o.SALES, 0) AS MONEY
    ) AS SALES,
    CASE
        WHEN STAGENAME = 'Revenue Recognized'
        AND CLOSE_YYYY = '2024' THEN CAST(
            ISNULL(isnull(A.SPLIT, ss.split), 1) * ISNULL(SALES, 0) AS MONEY
        )
        ELSE 0
    END AS REV_REC_YTD,
    CASE
        WHEN STAGENAME = 'Revenue Recognized'
        AND CLOSE_YYYY = '2024' THEN ISNULL(isnull(A.SPLIT, ss.split), 1) * isnull(TOTALOPPORTUNITYQUANTITY, 0)
        ELSE 0
    END AS REV_REC_U_YTD,
    CASE
        WHEN o.[isimpl] = 1
        AND IMPLANTED_YYYY = '2024' THEN ISNULL(isnull(A.SPLIT, ss.split), 1) * isnull(IMPLANT_UNITS, 0)
        ELSE 0
    END AS IMPLANT_UNITS_YTD,
    o.IMPLANTED_YYYYMM,
    o.CLOSE_YYYYMM
FROM
    dbo.qryOpps AS o
    LEFT OUTER JOIN dbo.tblActSplits AS A ON o.ACT_ID = A.ACT_ID
    AND o.CLOSE_YYYYMM BETWEEN A.YYYYMM_ST
    AND A.YYYYMM_END
    LEFT OUTER JOIN dbo.tblSalesSplits AS SS ON o.OPP_ID = SS.OPP_ID
    AND SS.NOTES = 'Split Adjustment'
    AND SS.SPLIT IS NOT NULL
WHERE
    (
        o.STAGENAME IN ('Revenue Recognized', 'Implant Completed')
    )
    AND (
        o.INDICATION_FOR_USE__C = 'Heart Failure - Reduced Ejection Fraction'
    )
    AND (o.REASON_FOR_IMPLANT__C <> 'De Novo - BATwire')
    AND (o.SHIPPINGCOUNTRYCODE = 'US')