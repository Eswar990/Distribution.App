tableextension 50209 "CustomerExt " extends Customer
{
    fields
    {
        field(50300; "Invoice No. Series"; Code[20])
        {
            Caption = 'Invoice No. Series';
            DataClassification = ToBeClassified;
            TableRelation = "No. Series";
        }
    }
}
