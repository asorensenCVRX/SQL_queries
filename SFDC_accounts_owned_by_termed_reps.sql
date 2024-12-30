SELECT
    A.NAME,
    A.ID,
    U.EMAIL,
    U.NAME
FROM
    sfdcAccount A
    LEFT JOIN sfdcUser U ON A.OWNERID = U.ID
WHERE
    U.EMAIL IN (
        SELECT
            [WORK E-MAIL]
        FROM
            tblEmployee
        WHERE
            DOT IS NOT NULL
            AND DOT < GETDATE()
    )
    AND U.EMAIL <> 'mdagley@cvrx.com'