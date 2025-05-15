DECLARE @columns AS VARCHAR(MAX);


DECLARE @sql AS NVARCHAR(MAX);


SELECT
    @columns = STRING_AGG(QUOTENAME(YYYYMM), ', ')
FROM
    (
        SELECT
            DISTINCT YYYYMM
        FROM
            qryCalendar
        WHERE
            [YEAR] = 2025
    ) AS A;


SET
    @sql = N'SELECT
    * 
    -- INTO tmpATM_PO
FROM
    (
        SELECT
            NAME_REP,
            REP_EMAIL,
            C.YYYYMM,
            ISNULL(A.MBO_COMPLETION, 0) * 7500 AS MBO_COMPLETION
        FROM
            qryRoster R
            CROSS JOIN (
                SELECT
                    DISTINCT YYYYMM
                FROM
                    qryCalendar
                WHERE
                    YEAR = 2025
            ) AS C
            LEFT JOIN tblATM_MBO A ON R.REP_EMAIL = A.EID
            AND C.YYYYMM = A.YYYYMM
        WHERE
            [isLATEST?] = 1
            AND role = ''ATM''
            AND format(
                ISNULL(DOT, ''2099-12-31''),
                ''yyyy_MM''
            ) >= FORMAT(DATEADD(MONTH, -1, GETDATE()), ''yyyy_MM'')
            AND ISNULL(DOT, ''2099-12-31'') >= DATEADD(MONTH, -1, GETDATE())
    ) AS SOURCE PIVOT (SUM(MBO_COMPLETION) FOR YYYYMM IN (' + @columns + ')) AS PVT';


EXEC sp_executesql @sql