
codeunit 50203 SalesInvoiceNoSeriesExt
{
    Permissions =
        tabledata "Sales Invoice Header" = RIMD;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterInsertInvoiceHeader', '', false, false)]
    local procedure OnBeforeInsertSalesHeader(var SalesInvHeader: Record "Sales Invoice Header"; SalesHeader: Record "Sales Header")
    var
        Customer: Record Customer;
        NoSeriesMgt: Codeunit "No. Series";
    begin
        if SalesHeader."Document Type" = SalesHeader."Document Type"::Invoice then
            if Customer.Get(SalesHeader."Sell-to Customer No.") then
                if Customer."Invoice No. Series" <> '' then begin
                    SalesHeader."No. Series" := Customer."Invoice No. Series";
                    SalesHeader."No." := NoSeriesMgt.GetNextNo(SalesHeader."No. Series", WorkDate(), true);
                    SalesInvHeader."No." := SalesHeader."No.";
                    SalesInvHeader.Modify(false)
                end;
    end;
}