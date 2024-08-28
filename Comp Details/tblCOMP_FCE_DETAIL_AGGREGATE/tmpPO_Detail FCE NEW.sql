SELECT
    [SALES_CREDIT_FCE_EMAIL],
    [NAME_REP],
    [SALES_CREDIT_REP_EMAIL],
    [ROLE],
    [DOH],
    [CLOSEDATE],
    [REGION],
    [REGION_ID],
    [ACCOUNT],
    [PHYSICIAN],
    sum(isnull([isTarget?], 0)) AS [isTarget?],
    sum([PO_PER]) AS [PO_PER],
    sum([CPAS_SPIFF_DEDUCTION]) AS [CPAS_SPIFF_DEDUCTION],
    sum([TGT_PO]) AS [TGT_PO],
    [OPP_NAME],
    [OPP_ID],
    [IPG],
    [CLOSE_YYYYMM],
    [CLOSE_YYYYQQ],
    [IMPLANTED_YYYYMM],
    [IMPLANTED_YYYYQQ],
    sum(
        CASE
            WHEN [TYPE] IN ('ACCT', 'DOC') THEN 0
            ELSE [QTY]
        END
    ) AS [QTY],
    sum(
        CASE
            WHEN [TYPE] IN ('ACCT', 'DOC') THEN 0
            ELSE [BATWIRE_QTY]
        END
    ) AS [BATWIRE_QTY],
    [SALES],
    [isComp?],
    qry_COMP_FCE_DETAIL.ACCOUNT AS ACT_NAME --INTO tblCOMP_FCE_DETAIL_AGGREGATE
FROM
    qry_COMP_FCE_DETAIL
GROUP BY
    [SALES_CREDIT_FCE_EMAIL],
    [NAME_REP],
    [SALES_CREDIT_REP_EMAIL],
    [ROLE],
    [DOH],
    [CLOSEDATE],
    [REGION],
    [REGION_ID],
    [ACCOUNT],
    [PHYSICIAN],
    [OPP_NAME],
    [OPP_ID],
    [IPG],
    [CLOSE_YYYYMM],
    [CLOSE_YYYYQQ],
    [IMPLANTED_YYYYMM],
    [IMPLANTED_YYYYQQ],
    [SALES],
    [isComp?],
    qry_COMP_FCE_DETAIL.ACCOUNT;

-- select * from tblCOMP_FCE_DETAIL_AGGREGATE