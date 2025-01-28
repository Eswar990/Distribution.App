tableextension 50200 DimensionValueEx extends "Dimension Value"
{
    fields
    {
        field(50211; "Team Leader"; Boolean)
        {
            Caption = 'Team Leader';
        }

        field(50212; "Manager"; Boolean)
        {
            Caption = 'Manager';
        }

        field(50210; "Distribute Enable"; Boolean)
        {
            Caption = 'Distribute Enable';
            Editable = false;
        }
    }
    var
        UserCustManage: Codeunit "User Customize Manage";
}