SELECT
    *,
    ROW_NUMBER() OVER (
        PARTITION BY SPIFF_CREDIT_EMAIL
        ORDER BY
            IMPLANTED_DT
    ) AS IMPLANT_NUMBER
FROM
    (
        SELECT
            o.NAME [OPP_NAME],
            o.OPP_ID,
            o.ACCOUNT_INDICATION__C,
            o.INDICATION_FOR_USE__C,
            o.REASON_FOR_IMPLANT__C,
            o.ACT_OWNER_NAME,
            o.OPP_OWNER_NAME,
            o.SALES_CREDIT_REP,
            a.REP_EMAIL [SPLIT_EMAIL],
            a.SPLIT,
            o.ACT_OWNER_REGION [REGION],
            o.SALES * isnull(a.SPLIT, 1) [SALES],
            o.TOTALOPPORTUNITYQUANTITY * isnull(a.SPLIT, 1) TOTALOPPORTUNITYQUANTITY,
            o.IMPLANT_UNITS * isnull(a.SPLIT, 1) IMPLANT_UNITS,
            o.IMPLANTED_DT,
            o.IMPLANTED_YYYYMM,
            o.IMPLANTED_YYYYQQ,
            CASE
                WHEN (
                    O.ACT_OWNER_EMAIL IN (
                        'ashapiro@cvrx.com',
                        'bkelly@cvrx.com',
                        'bfagan@cvrx.com',
                        'cmaxson@cvrx.com',
                        'dabesamis@cvrx.com',
                        'dking@cvrx.com',
                        'dwalusis@cvrx.com',
                        'dabbring@cvrx.com',
                        'glink@cvrx.com',
                        'jlowery@cvrx.com',
                        'jelinburg@cvrx.com',
                        'jhall@cvrx.com',
                        'jtalbert@cvrx.com',
                        'jviduna@cvrx.com',
                        'jsmith@cvrx.com',
                        'pdickerson@cvrx.com',
                        'rdegeus@cvrx.com',
                        'sfuller@cvrx.com',
                        'sharrienger@cvrx.com',
                        'scroxdale@cvrx.com',
                        'tkirk@cvrx.com',
                        'tbarker@cvrx.com',
                        'tvaccaro@cvrx.com',
                        'wsteinhoff@cvrx.com',
                        'ycruea@cvrx.com'
                    )
                    OR o.SALES_CREDIT_REP_EMAIL IN (
                        'ashapiro@cvrx.com',
                        'bkelly@cvrx.com',
                        'bfagan@cvrx.com',
                        'cmaxson@cvrx.com',
                        'dabesamis@cvrx.com',
                        'dking@cvrx.com',
                        'dwalusis@cvrx.com',
                        'dabbring@cvrx.com',
                        'glink@cvrx.com',
                        'jlowery@cvrx.com',
                        'jelinburg@cvrx.com',
                        'jhall@cvrx.com',
                        'jtalbert@cvrx.com',
                        'jviduna@cvrx.com',
                        'jsmith@cvrx.com',
                        'pdickerson@cvrx.com',
                        'rdegeus@cvrx.com',
                        'sfuller@cvrx.com',
                        'sharrienger@cvrx.com',
                        'scroxdale@cvrx.com',
                        'tkirk@cvrx.com',
                        'tbarker@cvrx.com',
                        'tvaccaro@cvrx.com',
                        'wsteinhoff@cvrx.com',
                        'ycruea@cvrx.com'
                    )
                    OR o.OPP_OWNER_EMAIL IN (
                        'ashapiro@cvrx.com',
                        'bkelly@cvrx.com',
                        'bfagan@cvrx.com',
                        'cmaxson@cvrx.com',
                        'dabesamis@cvrx.com',
                        'dking@cvrx.com',
                        'dwalusis@cvrx.com',
                        'dabbring@cvrx.com',
                        'glink@cvrx.com',
                        'jlowery@cvrx.com',
                        'jelinburg@cvrx.com',
                        'jhall@cvrx.com',
                        'jtalbert@cvrx.com',
                        'jviduna@cvrx.com',
                        'jsmith@cvrx.com',
                        'pdickerson@cvrx.com',
                        'rdegeus@cvrx.com',
                        'sfuller@cvrx.com',
                        'sharrienger@cvrx.com',
                        'scroxdale@cvrx.com',
                        'tkirk@cvrx.com',
                        'tbarker@cvrx.com',
                        'tvaccaro@cvrx.com',
                        'wsteinhoff@cvrx.com',
                        'ycruea@cvrx.com'
                    )
                    OR a.REP_EMAIL IN (
                        'ashapiro@cvrx.com',
                        'bkelly@cvrx.com',
                        'bfagan@cvrx.com',
                        'cmaxson@cvrx.com',
                        'dabesamis@cvrx.com',
                        'dking@cvrx.com',
                        'dwalusis@cvrx.com',
                        'dabbring@cvrx.com',
                        'glink@cvrx.com',
                        'jlowery@cvrx.com',
                        'jelinburg@cvrx.com',
                        'jhall@cvrx.com',
                        'jtalbert@cvrx.com',
                        'jviduna@cvrx.com',
                        'jsmith@cvrx.com',
                        'pdickerson@cvrx.com',
                        'rdegeus@cvrx.com',
                        'sfuller@cvrx.com',
                        'sharrienger@cvrx.com',
                        'scroxdale@cvrx.com',
                        'tkirk@cvrx.com',
                        'tbarker@cvrx.com',
                        'tvaccaro@cvrx.com',
                        'wsteinhoff@cvrx.com',
                        'ycruea@cvrx.com'
                    )
                    OR r.REP_EMAIL IN (
                        'ashapiro@cvrx.com',
                        'bkelly@cvrx.com',
                        'bfagan@cvrx.com',
                        'cmaxson@cvrx.com',
                        'dabesamis@cvrx.com',
                        'dking@cvrx.com',
                        'dwalusis@cvrx.com',
                        'dabbring@cvrx.com',
                        'glink@cvrx.com',
                        'jlowery@cvrx.com',
                        'jelinburg@cvrx.com',
                        'jhall@cvrx.com',
                        'jtalbert@cvrx.com',
                        'jviduna@cvrx.com',
                        'jsmith@cvrx.com',
                        'pdickerson@cvrx.com',
                        'rdegeus@cvrx.com',
                        'sfuller@cvrx.com',
                        'sharrienger@cvrx.com',
                        'scroxdale@cvrx.com',
                        'tkirk@cvrx.com',
                        'tbarker@cvrx.com',
                        'tvaccaro@cvrx.com',
                        'wsteinhoff@cvrx.com',
                        'ycruea@cvrx.com'
                    )
                ) THEN 1
                ELSE 0
            END AS [isSPIFFEligible?],
            CASE
                WHEN a.REP_EMAIL IN (
                    'ashapiro@cvrx.com',
                    'bkelly@cvrx.com',
                    'bfagan@cvrx.com',
                    'cmaxson@cvrx.com',
                    'dabesamis@cvrx.com',
                    'dking@cvrx.com',
                    'dwalusis@cvrx.com',
                    'dabbring@cvrx.com',
                    'glink@cvrx.com',
                    'jlowery@cvrx.com',
                    'jelinburg@cvrx.com',
                    'jhall@cvrx.com',
                    'jtalbert@cvrx.com',
                    'jviduna@cvrx.com',
                    'jsmith@cvrx.com',
                    'pdickerson@cvrx.com',
                    'rdegeus@cvrx.com',
                    'sfuller@cvrx.com',
                    'sharrienger@cvrx.com',
                    'scroxdale@cvrx.com',
                    'tkirk@cvrx.com',
                    'tbarker@cvrx.com',
                    'tvaccaro@cvrx.com',
                    'wsteinhoff@cvrx.com',
                    'ycruea@cvrx.com'
                ) THEN a.REP_EMAIL
                WHEN O.ACT_OWNER_EMAIL IN (
                    'ashapiro@cvrx.com',
                    'bkelly@cvrx.com',
                    'bfagan@cvrx.com',
                    'cmaxson@cvrx.com',
                    'dabesamis@cvrx.com',
                    'dking@cvrx.com',
                    'dwalusis@cvrx.com',
                    'dabbring@cvrx.com',
                    'glink@cvrx.com',
                    'jlowery@cvrx.com',
                    'jelinburg@cvrx.com',
                    'jhall@cvrx.com',
                    'jtalbert@cvrx.com',
                    'jviduna@cvrx.com',
                    'jsmith@cvrx.com',
                    'pdickerson@cvrx.com',
                    'rdegeus@cvrx.com',
                    'sfuller@cvrx.com',
                    'sharrienger@cvrx.com',
                    'scroxdale@cvrx.com',
                    'tkirk@cvrx.com',
                    'tbarker@cvrx.com',
                    'tvaccaro@cvrx.com',
                    'wsteinhoff@cvrx.com',
                    'ycruea@cvrx.com'
                ) THEN O.ACT_OWNER_EMAIL
                WHEN o.SALES_CREDIT_REP_EMAIL IN (
                    'ashapiro@cvrx.com',
                    'bkelly@cvrx.com',
                    'bfagan@cvrx.com',
                    'cmaxson@cvrx.com',
                    'dabesamis@cvrx.com',
                    'dking@cvrx.com',
                    'dwalusis@cvrx.com',
                    'dabbring@cvrx.com',
                    'glink@cvrx.com',
                    'jlowery@cvrx.com',
                    'jelinburg@cvrx.com',
                    'jhall@cvrx.com',
                    'jtalbert@cvrx.com',
                    'jviduna@cvrx.com',
                    'jsmith@cvrx.com',
                    'pdickerson@cvrx.com',
                    'rdegeus@cvrx.com',
                    'sfuller@cvrx.com',
                    'sharrienger@cvrx.com',
                    'scroxdale@cvrx.com',
                    'tkirk@cvrx.com',
                    'tbarker@cvrx.com',
                    'tvaccaro@cvrx.com',
                    'wsteinhoff@cvrx.com',
                    'ycruea@cvrx.com'
                ) THEN o.SALES_CREDIT_REP_EMAIL
                WHEN o.OPP_OWNER_EMAIL IN (
                    'ashapiro@cvrx.com',
                    'bkelly@cvrx.com',
                    'bfagan@cvrx.com',
                    'cmaxson@cvrx.com',
                    'dabesamis@cvrx.com',
                    'dking@cvrx.com',
                    'dwalusis@cvrx.com',
                    'dabbring@cvrx.com',
                    'glink@cvrx.com',
                    'jlowery@cvrx.com',
                    'jelinburg@cvrx.com',
                    'jhall@cvrx.com',
                    'jtalbert@cvrx.com',
                    'jviduna@cvrx.com',
                    'jsmith@cvrx.com',
                    'pdickerson@cvrx.com',
                    'rdegeus@cvrx.com',
                    'sfuller@cvrx.com',
                    'sharrienger@cvrx.com',
                    'scroxdale@cvrx.com',
                    'tkirk@cvrx.com',
                    'tbarker@cvrx.com',
                    'tvaccaro@cvrx.com',
                    'wsteinhoff@cvrx.com',
                    'ycruea@cvrx.com'
                ) THEN o.OPP_OWNER_EMAIL
                ELSE NULL
            END AS [SPIFF_CREDIT_EMAIL],
            CASE
                WHEN a.act_ID IS NOT NULL THEN 1
                ELSE 0
            END AS [isSplit?],
            isnull(r.NAME_REP, o.act_OWNER_NAME) [NAME_REP]
        FROM
            tmpOpps O
            LEFT JOIN tblActSplits A ON A.ACT_ID = o.ACT_ID
            AND o.IMPLANTED_YYYYMM BETWEEN A.YYYYMM_ST
            AND A.YYYYMM_END
            LEFT JOIN qryroster R ON (
                CASE
                    WHEN a.REP_EMAIL IN (
                        'ashapiro@cvrx.com',
                        'bkelly@cvrx.com',
                        'bfagan@cvrx.com',
                        'cmaxson@cvrx.com',
                        'dabesamis@cvrx.com',
                        'dking@cvrx.com',
                        'dwalusis@cvrx.com',
                        'dabbring@cvrx.com',
                        'glink@cvrx.com',
                        'jlowery@cvrx.com',
                        'jelinburg@cvrx.com',
                        'jhall@cvrx.com',
                        'jtalbert@cvrx.com',
                        'jviduna@cvrx.com',
                        'jsmith@cvrx.com',
                        'pdickerson@cvrx.com',
                        'rdegeus@cvrx.com',
                        'sfuller@cvrx.com',
                        'sharrienger@cvrx.com',
                        'scroxdale@cvrx.com',
                        'tkirk@cvrx.com',
                        'tbarker@cvrx.com',
                        'tvaccaro@cvrx.com',
                        'wsteinhoff@cvrx.com',
                        'ycruea@cvrx.com'
                    ) THEN a.REP_EMAIL
                    WHEN O.ACT_OWNER_EMAIL IN (
                        'ashapiro@cvrx.com',
                        'bkelly@cvrx.com',
                        'bfagan@cvrx.com',
                        'cmaxson@cvrx.com',
                        'dabesamis@cvrx.com',
                        'dking@cvrx.com',
                        'dwalusis@cvrx.com',
                        'dabbring@cvrx.com',
                        'glink@cvrx.com',
                        'jlowery@cvrx.com',
                        'jelinburg@cvrx.com',
                        'jhall@cvrx.com',
                        'jtalbert@cvrx.com',
                        'jviduna@cvrx.com',
                        'jsmith@cvrx.com',
                        'pdickerson@cvrx.com',
                        'rdegeus@cvrx.com',
                        'sfuller@cvrx.com',
                        'sharrienger@cvrx.com',
                        'scroxdale@cvrx.com',
                        'tkirk@cvrx.com',
                        'tbarker@cvrx.com',
                        'tvaccaro@cvrx.com',
                        'wsteinhoff@cvrx.com',
                        'ycruea@cvrx.com'
                    ) THEN O.ACT_OWNER_EMAIL
                    WHEN o.SALES_CREDIT_REP_EMAIL IN (
                        'ashapiro@cvrx.com',
                        'bkelly@cvrx.com',
                        'bfagan@cvrx.com',
                        'cmaxson@cvrx.com',
                        'dabesamis@cvrx.com',
                        'dking@cvrx.com',
                        'dwalusis@cvrx.com',
                        'dabbring@cvrx.com',
                        'glink@cvrx.com',
                        'jlowery@cvrx.com',
                        'jelinburg@cvrx.com',
                        'jhall@cvrx.com',
                        'jtalbert@cvrx.com',
                        'jviduna@cvrx.com',
                        'jsmith@cvrx.com',
                        'pdickerson@cvrx.com',
                        'rdegeus@cvrx.com',
                        'sfuller@cvrx.com',
                        'sharrienger@cvrx.com',
                        'scroxdale@cvrx.com',
                        'tkirk@cvrx.com',
                        'tbarker@cvrx.com',
                        'tvaccaro@cvrx.com',
                        'wsteinhoff@cvrx.com',
                        'ycruea@cvrx.com'
                    ) THEN o.SALES_CREDIT_REP_EMAIL
                    ELSE NULL
                END
            ) = R.REP_EMAIL
            AND r.[isLATEST?] = 1
        WHERE
            ISIMPL = 1
            AND IMPLANTED_YYYYMM >= '2024_08'
            AND REASON_FOR_IMPLANT__C = 'De novo'
            AND STAGENAME IN ('Implant Completed', 'Revenue Recognized')
            AND INDICATION_FOR_USE__C = 'Heart Failure - Reduced Ejection Fraction'
        UNION
        ALL
        SELECT
            NULL AS [OPP_NAME],
            NULL AS OPP_ID,
            NULL AS [ACCOUNT_INDICATION__C],
            NULL AS [ACCOUNT_INDICATION__C],
            NULL AS [ACCOUNT_INDICATION__C],
            NULL AS [ACT_OWNER_NAME],
            NULL AS [OPP_OWNER_NAME],
            NULL AS [SALES_CREDIT_REP],
            NULL AS [SPLIT_EMAIL],
            NULL AS [SPLIT],
            NULL AS [REGION],
            NULL AS [SALES],
            NULL AS [TOTALOPPORTUNITYQUANTITY],
            0.0 AS [IMPLANT_UNITS],
            NULL AS [IMPLANTED_DT],
            NULL AS [IMPLANTED_YYYYMM],
            NULL AS [IMPLANTED_YYYYQQ],
            1 AS [isSPIFFEligible?],
            NULL AS [SPIFF_CREDIT_EMAIL],
            NULL AS [isSplit?],
            [NAME_REP]
        FROM
            qryroster R
        WHERE
            (
                R.role = 'REP'
                OR R.REP_EMAIL = 'ycrea@cvrx.com'
            )
            AND r.[islatest?] = 1
            AND r.rep_Email IN (
                'ashapiro@cvrx.com',
                'bkelly@cvrx.com',
                'bfagan@cvrx.com',
                'cmaxson@cvrx.com',
                'dabesamis@cvrx.com',
                'dking@cvrx.com',
                'dwalusis@cvrx.com',
                'dabbring@cvrx.com',
                'glink@cvrx.com',
                'jlowery@cvrx.com',
                'jelinburg@cvrx.com',
                'jhall@cvrx.com',
                'jtalbert@cvrx.com',
                'jviduna@cvrx.com',
                'jsmith@cvrx.com',
                'pdickerson@cvrx.com',
                'rdegeus@cvrx.com',
                'sfuller@cvrx.com',
                'sharrienger@cvrx.com',
                'scroxdale@cvrx.com',
                'tkirk@cvrx.com',
                'tbarker@cvrx.com',
                'tvaccaro@cvrx.com',
                'wsteinhoff@cvrx.com',
                'ycruea@cvrx.com'
            )
    ) A
WHERE
    spiff_credit_email IS NOT NULL