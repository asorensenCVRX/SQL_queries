-- CREATE VIEW qryRoster AS
SELECT
    A.ROLE,
    A.TERRITORY_ID,
    ISNULL(B.TERRITORY, BB.REGION) AS TERRITORY,
    ISNULL(B.TERRITORY, BB.REGION) + ' (' + UPPER(D.LNAME) + ')' AS TERR_NM,
    ISNULL(B.REGION, BB.REGION) AS REGION,
    ISNULL(B.REGION_ID, BB.REGION_ID) AS REGION_ID,
    ISNULL(B.REGION, BB.REGION) + ' (' + UPPER(E.LNAME) + ')' AS REGION_NM,
    ISNULL(C.EMP_EMAIL, CC.EMP_EMAIL) AS RM_EMAIL,
    (
        SELECT
            DISTINCT ID
        FROM
            dbo.qryUsers
        WHERE
            (EMAIL = ISNULL(C.EMP_EMAIL, CC.EMP_EMAIL))
    ) AS RM_ID,
    A.EMP_EMAIL AS REP_EMAIL,
    CASE
        WHEN RANK() OVER (
            PARTITION BY A.EMP_EMAIL
            ORDER BY
                ISNULL(A.START_DT, D.DOH) DESC
        ) = 1 THEN 1
        ELSE 0
    END [isLATEST?],
    (
        SELECT
            DISTINCT ID
        FROM
            dbo.qryUsers
        WHERE
            (EMAIL = A.EMP_EMAIL)
    ) AS REP_ID,
    D.LNAME AS LNAME_REP,
    d.FNAME AS FNAME_REP,
    d.FNAME + ' ' + D.LNAME AS NAME_REP,
    G.YYYYMM_ST_DT,
    G.YYYYMM_END_DT,
    CAST(D.DOH AS DATE) AS DOH,
    CAST(YEAR(A.START_DT) AS VARCHAR) + '_' + RIGHT('0' + CAST(MONTH(A.START_DT) AS VARCHAR), 2) AS ACTIVE_YYYYMM,
    CAST(YEAR(D.DOH) AS VARCHAR) + '_' + RIGHT('Q' + CAST(DATEPART(q, D.DOH) AS VARCHAR), 2) AS DOH_YYYYQQ,
    CAST(YEAR(D.DOH) AS VARCHAR) + '_' + RIGHT('0' + CAST(MONTH(D.DOH) AS VARCHAR), 2) AS DOH_YYYYMM,
    CAST(D.[DOH_+6] AS DATE) AS DOH_6MNTH
    /*, DATEDIFF(m, a.START_DT, ISNULL(D.dot, GETDATE())) AS TENNURE_MONTHS*/
,
    CASE
        WHEN SUM(
            DATEDIFF(m, a.START_DT, ISNULL(D.dot, GETDATE()))
        ) OVER (PARTITION BY a.EMP_EMAIL, a.role) < 0 THEN 0
        ELSE SUM(
            DATEDIFF(m, a.START_DT, ISNULL(D.dot, GETDATE()))
        ) OVER (PARTITION BY a.EMP_EMAIL, a.role)
    END AS TENNURE_MONTHS,
    CASE
        WHEN CAST(ISNULL(D.DOT, A.END_DT) AS DATE) = '2099-12-31' THEN NULL
        WHEN (
            CASE
                WHEN RANK() OVER (
                    PARTITION BY A.EMP_EMAIL
                    ORDER BY
                        ISNULL(A.START_DT, D.DOH) DESC
                ) = 1 THEN 1
                ELSE 0
            END
        ) = 1
        AND D.DOT IS NOT NULL THEN d.dot
        ELSE A.END_DT
    END AS DOT,
    CASE
        WHEN CAST(ISNULL(D.DOT, A.END_DT) AS DATE) = '2099-12-31' THEN NULL
        WHEN (
            CASE
                WHEN RANK() OVER (
                    PARTITION BY A.EMP_EMAIL
                    ORDER BY
                        ISNULL(A.START_DT, D.DOH) DESC
                ) = 1 THEN 1
                ELSE 0
            END
        ) = 1
        AND D.DOT IS NOT NULL THEN CAST(YEAR(D.DOT) AS VARCHAR) + '_' + RIGHT('0' + CAST(MONTH(d.DOT) AS VARCHAR), 2)
        ELSE CAST(YEAR(A.END_DT) AS VARCHAR) + '_' + RIGHT('0' + CAST(MONTH(A.END_DT) AS VARCHAR), 2)
    END AS DOT_YYYYMM,
    E.LNAME AS LNAME_RM,
    z.TIER [Tier],
    f.[isTargetedCSR?],
    d.[isActivated],
    CASE
        WHEN GETDATE() > A.END_DT THEN 'TERMED'
        ELSE 'ACTIVE'
    END AS STATUS,
    ISNULL(E.TERM_REASON, D.TERM_REASON) AS TERM_REASON,
    ISNULL(E.[REGRETTABLE?], D.[REGRETTABLE?]) AS [REGRETTABLE?]
FROM
    dbo.tblRoster AS A
    LEFT OUTER JOIN (
        SELECT
            *
        FROM
            (
                SELECT
                    *,
                    RANK() OVER (
                        PARTITION BY [TERRITORY_ID]
                        ORDER BY
                            [END_DT] DESC
                    ) AS [RANK]
                FROM
                    dbo.tblTerritory
            ) A
        WHERE
            [RANK] = 1
    ) AS B ON A.TERRITORY_ID = B.TERRITORY_ID
    LEFT OUTER JOIN (
        SELECT
            DISTINCT REGION_ID,
            REGION
        FROM
            dbo.tblTerritory
    ) AS BB ON A.TERRITORY_ID = BB.REGION_ID
    AND A.ROLE = 'FCE'
    /* REGION JOINS --*/
    LEFT OUTER JOIN dbo.tblRoster AS C ON B.REGION_ID = C.TERRITORY_ID
    AND C.ROLE = 'RM'
    AND C.END_DT > GETDATE()
    LEFT OUTER JOIN dbo.tblRoster AS CC ON BB.REGION_ID = CC.TERRITORY_ID
    AND CC.ROLE = 'RM'
    AND CC.END_DT > GETDATE()
    LEFT OUTER JOIN dbo.qryEmployee AS E ON ISNULL(C.EMP_EMAIL, CC.EMP_EMAIL) = E.[WORK E-MAIL]
    LEFT OUTER JOIN dbo.qryEmployee AS D ON A.EMP_EMAIL = D.[WORK E-MAIL]
    LEFT OUTER JOIN (
        SELECT
            EMP_EMAIL,
            MAX(END_DT) AS END_DT,
            MIN(ST_DT) AS ST_DT,
            CAST(YEAR(MIN(ST_DT)) AS VARCHAR) + '_' + RIGHT('0' + CAST(MONTH(MIN(ST_DT)) AS VARCHAR), 2) AS YYYYMM_ST_DT,
            CAST(YEAR(MAX(END_DT)) AS VARCHAR) + '_' + RIGHT('0' + CAST(MONTH(MAX(END_DT)) AS VARCHAR), 2) AS YYYYMM_END_DT
        FROM
            dbo.tblGuarantee
        GROUP BY
            EMP_EMAIL
    ) AS G ON A.EMP_EMAIL = G.EMP_EMAIL
    LEFT JOIN tblRates_TM Z ON A.EMP_EMAIL = Z.EID
    AND A.ROLE = 'REP'
    LEFT JOIN tblFCE_COMP F ON A.EMP_EMAIL = f.FCE_EMAIL
WHERE
    (A.ROLE IN ('FCE', 'REP', 'MDR'));