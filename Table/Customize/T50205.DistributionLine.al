table 50205 "Distribution Line"
{
    Caption = 'Distribution Line';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; Year; code[20])
        {
            Caption = 'Year';
            TableRelation = "Reference Data".Code where(Type = const(Year));
            Editable = false;
        }

        field(2; Month; code[20])
        {
            Caption = 'Month';
            TableRelation = "Reference Data".Code where(Type = const(Month));
            Editable = false;
        }

        field(3; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1),
                                                          Blocked = CONST(false));
            Editable = false;

        }

        field(5; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2),
                                                          Blocked = CONST(false));
            Editable = false;

        }

        field(6; "Shortcut Dimension 3 Code"; Code[20])
        {
            CaptionClass = UserCustManage.GetFieldCaption(3, 'One');
            Caption = 'Shortcut Dimension 3 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(3),
                                                          Blocked = CONST(false));
            Editable = false;
        }

        field(7; "Shortcut Dimension 3 Two"; Code[20])
        {
            CaptionClass = UserCustManage.GetFieldCaption(3, 'Two');
            Caption = 'Shortcut Dimension 3 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(3),
                                                          Blocked = CONST(false));
            Editable = false;
        }

        field(8; "Shortcut Dimension 3 Three"; Code[20])
        {
            CaptionClass = UserCustManage.GetFieldCaption(3, 'Three');
            Caption = 'Shortcut Dimension 3 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(3),
                                                          Blocked = CONST(false));
            Editable = false;
        }

        field(12; "Shortcut Dimension 3 Four"; Code[20])
        {
            CaptionClass = UserCustManage.GetFieldCaption(3, 'Four');
            Caption = 'Shortcut Dimension 3 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(3),
                                                          Blocked = CONST(false));
            Editable = false;
        }

        field(13; "Shortcut Dimension 3 Five"; Code[20])
        {
            CaptionClass = UserCustManage.GetFieldCaption(3, 'Five');
            Caption = 'Shortcut Dimension 3 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(3),
                                                          Blocked = CONST(false));
            Editable = false;
        }

        field(9; "Percentage One"; Decimal)
        {
            Caption = 'Percentage One';
            Editable = false;
        }

        field(10; "Percentage Two"; Decimal)
        {
            Caption = 'Percentage Two';
            Editable = false;
        }

        field(11; "Percentage Three"; Decimal)
        {
            Caption = 'Percentage Three';
            Editable = false;
        }

        field(14; "Percentage Four"; Decimal)
        {
            Caption = 'Percentage Four';
            Editable = false;
        }
        field(15; "Percentage Five"; Decimal)
        {
            Caption = 'Percentage Five';
            Editable = false;
        }
    }
    keys
    {
        key(PK; Year, Month, "Shortcut Dimension 1 Code")
        {
            Clustered = true;
        }
    }

    var
        UserCustManage: Codeunit "User Customize Manage";
}