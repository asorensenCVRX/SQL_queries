SELECT
    *
FROM
    tblTerritory
WHERE
    TERRITORY_ID NOT IN (
        SELECT
            DISTINCT A.TERRITORY_ID
        FROM
            tblRoster A
            INNER JOIN tblTerritory B ON A.TERRITORY_ID = B.TERRITORY_ID
        WHERE
            A.END_DT > GETDATE()
    )
    AND LEFT(END_DT, 4) = '2099'
ORDER BY
    REGION_ID;