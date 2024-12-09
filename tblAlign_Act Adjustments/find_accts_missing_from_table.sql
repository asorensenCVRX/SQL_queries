SELECT
    CREATEDDATE,
    CREATED_BY_EMAIL,
    CLOSEDATE,
    CLOSE_YYYYMM,
    ACCOUNT_INDICATION__C,
    ACT_ID,
    ACT_OWNER_EMAIL,
    NAME,
    OPP_ID,
    OPP_STATUS
FROM
    qryOpps
WHERE
    SHIPPINGCOUNTRYCODE = 'US'
    AND YEAR(CREATEDDATE) >= 2023
    AND ACT_ID NOT IN (
        SELECT
            ACT_ID
        FROM
            tblAlign_Act
        WHERE
            END_DT = '2099-12-31'
    )