SELECT
    *
FROM
    qryAlign_Act
WHERE
    END_DT = '2099-12-31'
    AND REP_TERR_ID <> ZIP_TERR_ID
    AND COVERAGE_TYPE = 'Normal'