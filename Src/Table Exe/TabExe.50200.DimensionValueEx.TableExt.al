tableextension 50200 DimensionValueEx extends "Dimension Value"
{
    fields
    {
        field(50210; "Distribute Enable"; Boolean)
        {
            Caption = 'Distribute Enable';
            Editable = false;
        }
        field(50211; "Team Leader"; Boolean)
        {
            Caption = 'Team Leader';
        }
        field(50212; "Manager"; Boolean)
        {
            Caption = 'Manager';
        }
    }
    var UserCustManage: Codeunit "User Customize Manage";
}
