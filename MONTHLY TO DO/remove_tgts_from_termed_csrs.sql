SELECT
    FTP.*
FROM
    tblFCE_TGT_PO FTP
    LEFT JOIN (
        SELECT
            *
        FROM
            qryRoster
        WHERE
            role = 'FCE'
    ) R ON FTP.EMAIL = R.REP_EMAIL
WHERE
    FTP.YYYYMM_END > R.DOT_YYYYMM;