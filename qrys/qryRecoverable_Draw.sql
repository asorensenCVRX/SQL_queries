-- CREATE VIEW qryRecoverable_Draw AS 
WITH G AS (
    SELECT
        YYYYMM,
        EMP_EMAIL,
        CASE
            WHEN [ROLE] IN ('AM', 'REP', 'TM') THEN 'TM'
            WHEN [ROLE] = 'RM' THEN 'ASD'
            ELSE [ROLE]
        END AS [ROLE],
        PO_AMT AS GUR_AMT,
        RECOVERABLE_UNTIL
    FROM
        qryGuarantee
    WHERE
        isCurr = 1
        AND RECOVERABLE_UNTIL > GETDATE()
        AND [ROLE] IN ('REP', 'RM')
),
PO AS (
    SELECT
        YYYYMM,
        EID,
        CASE
            WHEN [ROLE] = 'AM' THEN 'TM'
            WHEN [ROLE] = 'RM' THEN 'ASD'
            ELSE [ROLE]
        END AS [ROLE],
        TRY_CAST(VALUE AS MONEY) AS AMT_EARNED
    FROM
        tblPayout
    WHERE
        CATEGORY = 'TTL_PO'
)
SELECT
    G.YYYYMM,
    G.EMP_EMAIL,
    CASE
        WHEN PO.AMT_EARNED > G.GUR_AMT THEN 0
        ELSE G.GUR_AMT
    END AS GUR_AMT_PAID,
    G.RECOVERABLE_UNTIL,
    PO.AMT_EARNED,
    CASE
        WHEN PO.AMT_EARNED > G.GUR_AMT THEN 0
        ELSE GUR_AMT - AMT_EARNED
    END AS RECOVERABLE_DRAW
FROM
    G
    LEFT JOIN PO ON PO.YYYYMM = G.YYYYMM
    AND G.EMP_EMAIL = PO.EID
    AND G.[ROLE] = PO.[ROLE]