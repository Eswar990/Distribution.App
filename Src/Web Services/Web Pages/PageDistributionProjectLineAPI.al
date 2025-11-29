page 50216 "Distribution Project Line API"
{
    PageType = API;
    APIPublisher = 'MyCompany';  // Change this to your actual publisher name
    APIGroup = 'ProjectManagement';
    APIVersion = 'v1.0';
    EntityName = 'DistributionProjectLine';
    EntitySetName = 'DistributionProjectLines';
    SourceTable = 50200;  // Your custom table
    ODataKeyFields = "Entry No.";
    RefreshOnActivate = true;
    Editable = false; // Set to false if you only want to allow reading
    DelayedInsert = true;
    Permissions = TableData 50200 = RIMD;
    Extensible = false;
    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(EmployeeCode; Rec."Shortcut Dimension 1 Code")
                {
                    ToolTip = 'Specifies the value of the Shortcut Dimension 1 Code field.';
                    Editable = false;
                }
                field(BranchCode; Rec."Shortcut Dimension 2 Code")
                {
                    ToolTip = 'Specifies the value of the Shortcut Dimension 2 Code field.';
                    Editable = false;
                }
                field(ProjectCode; Rec."Shortcut Dimension 3 Code")
                {
                    ToolTip = 'Specifies the value of the Shortcut Dimension 3 Code field.';
                    Editable = false;
                }
                field(AmountAllocated; Rec."Amount Allocated")
                {
                    ToolTip = 'Specifies the value of the Amount Allocated field.';
                }
                field(EntryNo; Rec."Entry No.")
                {
                    ToolTip = 'Specifies the value of the Entry No. field.';
                    Editable = false;
                }
                field(EmpProjectPercentage; Rec."Emp. Project Percentage")
                {
                    ToolTip = 'Specifies the value of the Emp. Project Percentage field.';
                    Visible = false;
                }
                field(GLAccountNo; Rec."G/L Account No.")
                {
                    ToolTip = 'Specifies the value of the G/L Account No. field.';
                }
                field(LineNo; Rec."Line No.")
                {
                    ToolTip = 'Specifies the value of the Line No. field.';
                    Editable = false;
                }

                field(CompanyName; Rec."Company Name")
                {
                    ToolTip = 'Specifies The Value of the Company Name field';
                }
                field(AccountCategory; Rec."Account Category")
                {
                    ToolTip = 'Specifies The Value of the Account Category field';
                }
                field(PostingDate; Rec."Posting Date")
                {
                    ToolTip = 'Specifies The Value of the Posting Datefield';
                }
                field(DocumentNo; Rec."Document No.")
                {
                    ToolTip = 'Specifies The Value of the Document No field';
                }
                field(EmpProjectCount; Rec."Emp. Project Count")
                {
                    ToolTip = 'Specifies the value of the Emp. Project Count field.';
                    Visible = false;
                }
                field(TeamLeaderNo; Rec."Team Leader No.")
                {
                    ToolTip = 'Specifies the value of the Team Leader No. field.';
                }
                field(Leader; Rec."Team Leader")
                {
                    ToolTip = 'Specifies the value of the Team Leader field.';
                }
                field(ManagerNo; Rec."Manager No.")
                {
                    ToolTip = 'Specifies the value of the Manager No. field.';
                }
                field(Manager; Rec.Manager)
                {
                    ToolTip = 'Specifies the value of the Manager field.';
                }
            }
        }
    }


    // Defines the key field for API access

    // Permissions (optional)
    // Read, Insert, Modify, Delete access
}