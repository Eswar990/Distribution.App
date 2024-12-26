pageextension 50200 DimensionValuesEx extends "Dimension Values"
{
    layout
    {
        addbefore(Totaling)
        {

            field("Team Leader"; Rec."Team Leader")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Team Leader field.';
            }

            field(Manager; Rec.Manager)
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Manager field.';
            }

            field("Distribute Enable"; Rec."Distribute Enable")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Distribute Enable field.';
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        CheckVisible();
    end;

    procedure CheckVisible()
    var
        GenLedSetup: Record "General Ledger Setup";
    begin
        GenLedSetup.Get();
        if GenLedSetup."Global Dimension 1 Code" = Rec."Dimension Code" then
            FieldVisible := true;
    end;

    var
        FieldVisible: Boolean;
}