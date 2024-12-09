SELECT
    A.*,
    E.DOH,
    E.DOT
FROM
    tblAlign_Act A
    LEFT JOIN tblEmployee E ON A.OWNER_EMAIL = E.[WORK E-MAIL]
WHERE
    END_DT > DOT;


