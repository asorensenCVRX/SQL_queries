SELECT
    *
FROM
    qryAlign_Act
WHERE
    END_DT = '2099-12-31'
    AND [TERR_MISMATCH?] = 1 -- AND COVERAGE_TYPE = 'Normal'