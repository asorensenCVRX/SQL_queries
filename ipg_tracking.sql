WITH SN AS (
    /* all serial numbers for every IPG that has been sold and invoiced */
    SELECT
        Opportunity__c AS OPP_ID,
        Invoice_Line_Type__c,
        Serial_Number__c AS SERIAL_NUMBER
    FROM
        dbo.Invoice_Line__c
    WHERE
        Invoice_Line_Type__c = 'IPG'
        AND Serial_Number__c IS NOT NULL
),
OPPS AS (
    SELECT
        CAST(CLOSEDATE AS DATE) AS CLOSEDATE,
        CLOSE_YYYYMM,
        CAST(IMPLANTED_DT AS DATE) AS IMPLANTED_DT,
        IMPLANTED_YYYYMM,
        ACCOUNT_INDICATION__C AS ACT_NAME,
        ACT_ID,
        NAME AS OPP_NAME,
        OPP_ID,
        PATIENT_IPG_SERIAL_NUMBER__C AS SERIAL_NUMBER
    FROM
        qryOpps
    WHERE
        OPP_STATUS = 'CLOSED'
),
TERR AS (
    SELECT
        *
    FROM
        (
            SELECT
                *,
                ROW_NUMBER() over (
                    PARTITION BY TERRITORY_ID
                    ORDER BY
                        START_DT DESC
                ) AS RN
            FROM
                tblTerritory
        ) AS A
    WHERE
        RN = 1
),
TRK AS (
    SELECT
        SN.SERIAL_NUMBER,
        O.CLOSEDATE,
        O.CLOSE_YYYYMM,
        O.ACT_NAME AS PURCHASING_ACT,
        O.ACT_ID AS PURCHASING_ACT_ID,
        O2.ACT_NAME AS IMPLANTING_ACT,
        O2.ACT_ID AS IMPLANTING_ACT_ID,
        O.OPP_NAME AS PO_OPP_NAME,
        O.OPP_ID AS PO_OPP_ID,
        O2.OPP_NAME AS IMPLANTING_OPP_NAME,
        O2.OPP_ID AS IMPLANTING_OPP_ID,
        COUNT(*) OVER (PARTITION BY O.OPP_ID) AS IPG_COUNT_ON_PO,
        O2.IMPLANTED_DT,
        O2.IMPLANTED_YYYYMM
    FROM
        SN
        LEFT JOIN OPPS O ON SN.OPP_ID = O.OPP_ID
        LEFT JOIN OPPS O2 ON SN.SERIAL_NUMBER = O2.SERIAL_NUMBER
    WHERE
        O.ACT_NAME IS NOT NULL -- AND O.ACT_ID IN (
        --     SELECT
        --         ID
        --     FROM
        --         sfdcAccount
        --     WHERE
        --         DHC_IDN_NAME__C = 'HCA Healthcare'
        -- )
)
SELECT
    A.SERIAL_NUMBER,
    A.CLOSEDATE,
    A.CLOSE_YYYYMM,
    A.PURCHASING_ACT,
    -- A.PURCHASING_ACT_ID,
    A.IMPLANTING_ACT,
    -- A.IMPLANTING_ACT_ID,
    PO_OPP_NAME,
    -- PO_OPP_ID,
    IMPLANTING_OPP_NAME,
    -- IMPLANTING_OPP_ID,
    IPG_COUNT_ON_PO,
    IMPLANTED_DT,
    IMPLANTED_YYYYMM,
    T.TERRITORY AS PURCHASING_TERRITORY,
    T.REGION AS PURCHASING_REGION,
    T2.TERRITORY AS IMPLANTING_TERRITORY,
    T2.REGION AS IMPLANTING_REGION
FROM
    (
        SELECT
            TRK.*,
            A.DE_FACTO_TERR_ID AS PURCHASING_TERR_ID,
            A2.DE_FACTO_TERR_ID AS IMPLANTING_TERR_ID
        FROM
            TRK
            LEFT JOIN qryAlign_Act A ON TRK.PURCHASING_ACT_ID = A.ACT_ID
            AND CLOSEDATE BETWEEN A.ST_DT
            AND A.END_DT
            LEFT JOIN qryAlign_Act A2 ON TRK.IMPLANTING_ACT_ID = A2.ACT_ID
            AND IMPLANTED_DT BETWEEN A2.ST_DT
            AND A2.END_DT
    ) AS A
    LEFT JOIN TERR T ON A.PURCHASING_TERR_ID = T.TERRITORY_ID
    LEFT JOIN TERR T2 ON A.IMPLANTING_TERR_ID = T2.TERRITORY_ID