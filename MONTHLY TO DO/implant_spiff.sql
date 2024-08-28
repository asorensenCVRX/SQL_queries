SELECT
    R.REP_EMAIL,
    R.NAME_REP,
    COUNT(
        CASE
            WHEN IMPLANTED_YYYYMM = '2024_08' THEN OPP_ID
        END
    ) AS [2024_08]
FROM
    (
        SELECT
            *
        FROM
            qryRoster
        WHERE
            REP_EMAIL IN (
                'bfagan@cvrx.com',
                'ashapiro@cvrx.com',
                'cmaxson@cvrx.com',
                'dabbring@cvrx.com',
                'jelinburg@cvrx.com',
                'jhall@cvrx.com',
                'jlowery@cvrx.com',
                'jsmith@cvrx.com',
                'jtalbert@cvrx.com',
                'pdickerson@cvrx.com',
                'sfuller@cvrx.com',
                'sharrienger@cvrx.com',
                'tbarker@cvrx.com',
                'tkirk@cvrx.com',
                'wsteinhoff@cvrx.com',
                'dwalusis@cvrx.com',
                'bkelly@cvrx.com',
                'glink@cvrx.com',
                'rdegeus@cvrx.com',
                'scroxdale@cvrx.com',
                'tvaccaro@cvrx.com',
                'jviduna@cvrx.com',
                'dking@cvrx.com',
                'dabesamis@cvrx.com'
            )
            AND [isLATEST?] = 1
    ) R
    LEFT JOIN qryOpps O ON R.REP_EMAIL = O.AM_FOR_CREDIT_EMAIL
    AND O.OPP_STATUS = 'CLOSED'
    AND O.ISIMPL = 1
    AND O.REASON_FOR_IMPLANT__C = 'De novo'
    AND IMPLANTED_YYYYMM >= '2024_08'
GROUP BY
    R.REP_EMAIL,
    R.NAME_REP