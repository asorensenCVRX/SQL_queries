SELECT
    TERR_ID,
    EID,
    Tier,
    QUOTA_TIER,
    L1A,
    L1B,
    L2,
    L3
FROM
    tblRates_AM
WHERE
    (
        Tier = 'Tier 1'
        AND QUOTA_TIER NOT IN ('Tier 1', 'Tier 2')
    )
    OR (
        Tier = 'Tier 2'
        AND QUOTA_TIER NOT IN ('Tier 3', 'Tier 4')
    )
    OR (
        Tier = 'Tier 1'
        AND L2 <> 0.25
        AND L3 <> 0.25
    )
    OR (
        Tier = 'Tier 2'
        AND L2 <> 0.2
        AND L3 <> 0.2
    )