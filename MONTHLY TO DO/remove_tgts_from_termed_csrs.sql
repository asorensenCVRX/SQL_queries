SELECT
    FTP.*
FROM
    tblACCT_TGT FTP
    LEFT JOIN (
        SELECT
            *
        FROM
            qryRoster
        WHERE
            role = 'FCE'
    ) R ON FTP.EMAIL = R.REP_EMAIL
WHERE
    FTP.YYYYMM_END > R.DOT_YYYYMM
    AND PO_TYPE <> 'MBO';