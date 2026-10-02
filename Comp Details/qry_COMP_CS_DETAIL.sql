-- CREATE VIEW qry_COMP_CS_DETAIL AS 
/* targeted accounts are paid ONLY ON DE NOVO, but also on implant completed.
 Region alignments are paid on de novo and replacement, but only on rev rec */
WITH SALES AS (
    SELECT
        O.*,
        A.DE_FACTO_TERR_ID,
        ISNULL(T.REGION_ID, O.REG_ID) AS REGION_ID_x,
        ISNULL(T.REGION, O.REGION) AS REGION_x
    FROM
        tmpOpps O
        LEFT JOIN qryAlign_Act A ON O.ACT_ID = A.ACT_ID
        AND O.CLOSEDATE BETWEEN A.ST_DT
        AND A.END_DT
        LEFT JOIN tblTerritory T ON A.DE_FACTO_TERR_ID = T.TERRITORY_ID
        AND O.CLOSEDATE BETWEEN T.START_DT
        AND T.END_DT
    WHERE
        (
            CLOSE_YYYY = 2026
            OR IMPLANTED_YYYY = 2026
        )
        AND OPP_COUNTRY = 'US' -- AND INDICATION_FOR_USE__C = 'Heart Failure - Reduced Ejection Fraction'
        AND REASON_FOR_IMPLANT__C IN ('De novo', 'Replacement')
        AND OPP_STATUS = 'CLOSED'
        AND STAGENAME IN ('Revenue Recognized', 'Implant Completed')
),
ROSTER AS (
    SELECT
        R.*
    FROM
        qryROSTER R
    WHERE
        ROLE = 'FCE'
        AND ISNULL(DOT_YYYYMM, '2099_12') >= FORMAT(DATEADD(MONTH, -1, GETDATE()), 'yyyy_MM')
)
SELECT
    RL.REP_EMAIL AS SALES_CREDIT_CS_EMAIL,
    RL.NAME_REP,
    RL.REGION_NM,
    RL.REGION_ID,
    ISNULL(
        EOMONTH(
            DATEFROMPARTS(LEFT(S.YYYYMM, 4), RIGHT(S.YYYYMM, 2), 1)
        ),
        CLOSEDATE
    ) AS CLOSEDATE,
    COALESCE(
        S.YYYYMM,
        CLOSE_YYYYMM,
        FORMAT(DATEADD(MONTH, -1, GETDATE()), 'yyyy_MM')
    ) AS CLOSE_YYYYMM,
    CASE
        WHEN S.YYYYMM IS NOT NULL THEN CONCAT(
            LEFT(S.YYYYMM, 4),
            '_Q',
            DATEPART(
                QUARTER,
                DATEFROMPARTS(LEFT(S.YYYYMM, 4), RIGHT(S.YYYYMM, 2), 1)
            )
        )
        ELSE CLOSE_YYYYQQ
    END AS CLOSE_YYYYQQ,
    IMPLANTED_DT,
    IMPLANTED_YYYYMM,
    IMPLANTED_YYYYQQ,
    ACCOUNT_INDICATION__C,
    DHC_IDN_NAME__C,
    ACT_ID,
    NAME AS OPP_NAME,
    SALES.OPP_ID,
    PHYSICIAN,
    PHYSICIAN_ID,
    CASE
        WHEN S.SPLIT IS NOT NULL THEN S.SPLIT * SALES
        ELSE ISNULL(SALES, 0)
    END AS SALES,
    -- ISNULL(SALES, 0) AS SALES,
    CASE
        WHEN S.SPLIT IS NOT NULL THEN S.SPLIT * SALES_COMMISSIONABLE
        ELSE ISNULL(SALES_COMMISSIONABLE, 0)
    END AS SALES_COMMISSIONABLE,
    -- ISNULL(SALES_COMMISSIONABLE, 0) AS SALES_COMMISSIONABLE,
    SUM(
        CASE
            WHEN STAGENAME = 'Revenue Recognized' THEN ISNULL(ISNULL(S.SPLIT, 1) * SALES_COMMISSIONABLE, 0)
            ELSE 0
        END
    ) OVER (
        PARTITION BY RL.REP_EMAIL,
        LEFT(ISNULL(S.YYYYMM, CLOSE_YYYYMM), 4)
        ORDER BY
            CLOSEDATE,
            NAME ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
    ) AS YTD_SALES_COMMISSIONABLE,
    CASE
        WHEN STAGENAME = 'Revenue Recognized' THEN 1
        ELSE 0
    END AS [REG_ALIGN_ELIGIBLE?],
    CASE
        WHEN S.SPLIT IS NOT NULL THEN S.SPLIT * IMPLANT_UNITS
        ELSE ISNULL(IMPLANT_UNITS, 0)
    END AS IMPLANT_UNITS,
    -- ISNULL(IMPLANT_UNITS, 0) AS IMPLANT_UNITS,
    CASE
        WHEN S.SPLIT IS NOT NULL THEN S.SPLIT * REVENUE_UNITS
        ELSE ISNULL(REVENUE_UNITS, 0)
    END AS REVENUE_UNITS,
    -- ISNULL(REVENUE_UNITS, 0) AS REVENUE_UNITS,
    REASON_FOR_IMPLANT__C,
    STAGENAME
FROM
    SALES FULL
    OUTER JOIN ROSTER RL ON SALES.REGION_ID_x = RL.REGION_ID
    /* ensure no credit is given for sales before DOH */
    AND SALES.CLOSEDATE >= RL.ROLE_START_DT
    /* ensure no credit is given for sales after DOT */
    AND SALES.CLOSEDATE <= ISNULL(DOT, '2099-12-31')
    /* sales splits */
    LEFT JOIN tblSalesSplits S ON S.OPP_ID = SALES.OPP_ID
    /* Baylor Scott & White 48-pack -- full amount paid to clinicals in December of 2025*/
    /* Baylor Scott & White 50-pack -- full amount paid to clinicals in September of 2026*/
    AND S.OPP_ID NOT IN ('006UY00000U6L5LYAV', '006UY00000dyKAHYA2')