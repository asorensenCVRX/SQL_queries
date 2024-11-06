SELECT
    T.EMAIL,
    CASE
        WHEN t.ACTIVE_YYYYMM IS NOT NULL THEN t.ACTIVE_YYYYMM
        ELSE (
            SELECT
                ACTIVE_YYYYMM
            FROM
                qryRoster A
            WHERE
                A.REP_EMAIL = t.EMAIL
                AND A.ROLE = 'FCE'
                AND [isLATEST?] = 1
        )
    END AS [ACTIVE_YYYYMM],
    isnull(
        END_YYYYMM,
        ISNULL (
            (
                SELECT
                    DOT_YYYYMM
                FROM
                    qryRoster A
                WHERE
                    A.REP_EMAIL = t.EMAIL
                    AND A.ROLE = 'FCE'
                    AND [isLATEST?] = 1
            ),
            '2099_12'
        )
    ) AS [DOT_YYYYMM],
    T.[KEY],
    T.TYPE,
    CASE
        WHEN T.TYPE = 'ACCT' THEN (
            SELECT
                DISTINCT C.NAME
            FROM
                qryCust C
            WHERE
                C.ID = T.[KEY]
        )
        WHEN T.TYPE = 'DOC' THEN (
            SELECT
                C.NAME
            FROM
                sfdcContact C
            WHERE
                C.ID = T.[KEY]
        )
        WHEN T.TYPE = 'TERR' THEN (
            SELECT
                TERR_NM
            FROM
                qryRoster R
            WHERE
                R.STATUS = 'ACTIVE'
                AND R.TERRITORY_ID = T.[KEY]
        )
        WHEN T.TYPE = 'REGION' THEN (
            SELECT
                REGION
            FROM
                qryRoster_RM R
            WHERE
                R.STATUS = 'ACTIVE'
                AND R.TERRITORY_ID = T.[KEY]
        )
        ELSE NULL
    END AS [NAME_KEY],
    PO_PER,
    [PO_%]
FROM
    (
        SELECT
            Y.EMAIL,
            Y.OBJ_ID [KEY],
            Y.TYPE,
            Y.PO_PER,
            Y.[PO_%],
            Y.YYYYMM_START AS ACTIVE_YYYYMM,
            y.YYYYMM_END AS [END_YYYYMM]
        FROM
            (
                /*UNION ALL*/
                SELECT
                    F.EMAIL,
                    f.OBJ_ID,
                    F.[TYPE],
                    f.PO_PER,
                    f.[PO_%],
                    f.YYYYMM_START,
                    f.YYYYMM_END
                FROM
                    tblFCE_TGT_PO F
                UNION
                ALL
                SELECT
                    FCE_EMAIL,
                    A.TERR_ID [KEY],
                    CASE
                        WHEN LEFT(A.TERR_ID, 2) = 'RE' THEN 'REGION'
                        WHEN LEFT(A.TERR_ID, 2) = 'TE' THEN 'TERR'
                    END AS [TYPE],
                    0 AS PO_PER,
                    0 AS [PO_%],
                    NULL AS [ACTIVE_YYYYMM],
                    NULL AS [end]
                FROM
                    (
                        SELECT
                            FCE_EMAIL,
                            LTRIM(RTRIM(m.n.value('.[1]', 'varchar(8000)'))) AS TERR_ID
                        FROM
                            (
                                SELECT
                                    FCE_EMAIL,
                                    CAST(
                                        '<XMLRoot><RowData>' + REPLACE(ID, ',', '</RowData><RowData>') + '</RowData></XMLRoot>' AS XML
                                    ) AS x
                                FROM
                                    tblFCE_ALIGN
                            ) t
                            CROSS APPLY x.nodes('/XMLRoot/RowData') m(n)
                    ) A
            ) AS Y
    ) AS T;