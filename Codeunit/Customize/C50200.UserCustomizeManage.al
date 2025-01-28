codeunit 50200 "User Customize Manage"
{
    Permissions = tabledata "G/L Entry" = rm;
    procedure GetFieldCaption(Inx: Integer; FieldNoTxt: Text): Text[100]

    var
        GenLedSetup: Record "General Ledger Setup";
        Dim: Record Dimension;
    begin
        GenLedSetup.Get();
        GenLedSetup.TestField("Shortcut Dimension 3 Code");
        if (Inx = 3) then
            if Dim.Get(GenLedSetup."Shortcut Dimension 3 Code") then
                if FieldNoTxt = '' then
                    exit(Dim.Name)
                else
                    exit(Dim.Name + ' ' + FieldNoTxt);

        if (Inx = 4) then
            if Dim.Get(GenLedSetup."Shortcut Dimension 4 Code") then
                exit(Dim.Name);

        if (Inx = 5) then
            if Dim.Get(GenLedSetup."Shortcut Dimension 5 Code") then
                exit(Dim.Name);
    end;

    procedure GetDimValueAssigned(ShortDimCodeOne: Code[20]; var ShortDimCodeTwo: Code[20]; var ShortDimCodeThree: Code[20])
    var
        GenLedSetup: Record "General Ledger Setup";
        DimValue: Record "Dimension Value";
    begin
        GenLedSetup.Get();
        Clear(ShortDimCodeTwo);
        Clear(ShortDimCodeThree);
        if (DimValue.Get(GenLedSetup."Global Dimension 1 Code", ShortDimCodeOne) = false) then
            exit;

        // ShortDimCodeTwo := DimValue."Shortcut Dimension 2 Code";
        // ShortDimCodeThree := DimValue."Shortcut Dimension 3 Code";
    end;

    procedure InitDistributionProjectLine(EntryNo: Integer; DocNo: code[20]; NegValue: Boolean; DimTwoCode: Code[20]; DimOneCode: Code[20]; GLAccNo: code[20])
    var
        GLEntry: Record "G/L Entry";
        GLAcc: Record "G/L Account";
        DistProject: Record "Distribution Project";
        DimValue: Record "Dimension Value";
        DimValueTwoCode: Code[20];
        OldDimValueTwoCode: Code[20];
        DimValueThreeCode: Code[20];
        Inx: Integer;
        LineCraeted: Boolean;
    begin
        Clear(DistProject);
        DistProject.SetRange("Entry No.", EntryNo);
        if DistProject.FindSet() then
            exit;

        Clear(GLEntry);
        GLEntry.SetCurrentKey("Document No.");
        GLEntry.SetRange("Document No.", DocNo);
        GLEntry.SetFilter("Global Dimension 1 Code", DimOneCode);
        GLEntry.SetFilter("Global Dimension 2 Code", DimTwoCode);
        GLEntry.SetFilter("G/L Account No.", GLAccNo);
        GLEntry.SetFilter("Account Category", '%1|%2', GLEntry."Account Category"::Income, GLEntry."Account Category"::Expense);
        if not GLEntry.FindSet() then
            exit;
        repeat
            Clear(GLAcc);
            GLAcc.Get(GLEntry."G/L Account No.");
            if not GLAcc."VAT Account" then
                if GLEntry."Dimension Set ID" <> 0 then begin
                    Inx += 1;
                    Clear(DimValueTwoCode);
                    DimValueTwoCode := GetDimValueCode(GLEntry, 2);
                    if Inx = 1 then
                        OldDimValueTwoCode := DimValueTwoCode;

                    if OldDimValueTwoCode <> DimValueTwoCode then
                        Error('Branch code must be same.');

                    Clear(DimValueThreeCode);
                    DimValueThreeCode := GetDimValueCode(GLEntry, 3);
                    if DimValueThreeCode <> '' then begin
                        LineCraeted := true;
                        if DistProject.Get(EntryNo, DimValueThreeCode, DimValueTwoCode) then begin
                            DistProject."Project Amount" += GLEntry."Credit Amount";
                            DistProject.Modify();
                        end
                        else begin
                            // Inx += 1;
                            // Clear(DistProject);
                            // DistProject."Entry No." := EntryNo;
                            // DistProject."Shortcut Dimension 2 Code" := DimValueTwoCode;
                            // DistProject."Shortcut Dimension 3 Code" := DimValueThreeCode;
                            // DistProject."Project Amount" += GLEntry."Credit Amount";
                            // DistProject."Project Line" := true;
                            // DistProject."Line No." := Inx;
                            // DistProject."G/L Account No." := GLEntry."G/L Account No.";
                            // DistProject.Insert();
                        end;
                    end;
                end;
        until GLEntry.Next() = 0;
        if LineCraeted then
            exit;

        Clear(Inx);
        Clear(OldDimValueTwoCode);
        GLEntry.FindSet();
        repeat
            if GLEntry."Dimension Set ID" <> 0 then
                if not ProceedDimProjectType(GLEntry) then begin
                    Clear(DimValueTwoCode);

                    DimValueTwoCode := GetDimValueCode(GLEntry, 2);
                    Inx += 1;
                    if Inx = 1 then
                        OldDimValueTwoCode := DimValueTwoCode;

                    if OldDimValueTwoCode <> DimValueTwoCode then
                        Error('Branch code must be same.');

                    // DimValue.SetRange("Shortcut Dimension 2 Code", DimValueTwoCode);
                    // if DimValue.FindSet() then
                    //     repeat
                    //         if DimValue."Shortcut Dimension 3 Code" <> '' then
                    //             CreateDistProjectValue(EntryNo, DimValueTwoCode, DimValue."Shortcut Dimension 3 Code", GLEntry."G/L Account No.");
                    //         if DimValue."Shortcut Dimension 3 Two" <> '' then
                    //             CreateDistProjectValue(EntryNo, DimValueTwoCode, DimValue."Shortcut Dimension 3 Two", GLEntry."G/L Account No.");
                    //         if DimValue."Shortcut Dimension 3 Three" <> '' then
                    //             CreateDistProjectValue(EntryNo, DimValueTwoCode, DimValue."Shortcut Dimension 3 Three", GLEntry."G/L Account No.");
                    //     until DimValue.Next() = 0;
                end;
        until GLEntry.Next() = 0;
        Commit();
    end;

    procedure CreateProjectDistFromDistributionLine(EntryNo: Integer; RecDimensionValue: Code[20]; xRecDimensionValue: Code[20]; GLAccountNo: Code[20]; Integer: Integer);
    var
        DistProject: Record "Distribution Project";
        GLEntry: Record "G/L Entry";
    begin
        Clear(DistProject);
        DistProject.SetRange("Entry No.", EntryNo);
        if RecDimensionValue <> xRecDimensionValue then begin
            DistProject.SetRange("Shortcut Dimension 2 Code", xRecDimensionValue);
            if DistProject.FindSet() then begin
                DistProject.DeleteAll(true);
                if RecDimensionValue = '' then
                    exit;
            end;
        end;
        DistProject.SetRange("Shortcut Dimension 2 Code", RecDimensionValue);
        if DistProject.FindSet() then
            Error('Distribution projects lines exists, please delete projects lines.');

        if (GLEntry.Get(EntryNo) = false) then
            exit
        else
            DistributionProjectLinesArePopulatedFromDistributionSetup(GLEntry, RecDimensionValue, GLAccountNo, Integer);
    end;

    procedure CreateProjectDistRuleFilter(EntryNo: Integer; DimValueCode: Code[20]; xDimValueCode: Code[20]; GLAccNo: code[20])
    var
        DistProject: Record "Distribution Project";
        DimValue: Record "Dimension Value";
        GLEntry: Record "G/L Entry";
        GenJrnlDebitedAmount: Boolean;
    begin
        Clear(DistProject);
        DistProject.SetRange("Entry No.", EntryNo);
        if DimValueCode <> xDimValueCode then begin
            DistProject.SetRange("Shortcut Dimension 2 Code", xDimValueCode);
            if DistProject.FindSet() then begin
                DistProject.DeleteAll(true);
                if DimValueCode = '' then
                    exit;
            end;
        end;
        DistProject.SetRange("Shortcut Dimension 2 Code", DimValueCode);
        if DistProject.FindSet() then
            Error('Distribution projects lines exists, please delete projects lines.');

        if (GLEntry.Get(EntryNo) = false) then
            exit
        else
            if (GLEntry."Debit Amount" <> 0) then begin
                GenJrnlDebitedAmount := true;
                // DistributionProjectLineInGeneralJournal(EntryNo, DimValueCode, DimValue."Shortcut Dimension 3 Code", GLAccNo, GenJrnlDebitedAmount);
            end;
        // else begin
        //     DimValue.SetRange("Shortcut Dimension 2 Code", DimValueCode);
        //     DimValue.SetRange("Distribute Enable", true);
        //     if DimValue.FindSet() then
        //         repeat
        //             if DimValue."Shortcut Dimension 3 Code" <> '' then
        //                 CreateDistProjectValue(EntryNo, DimValueCode, DimValue."Shortcut Dimension 3 Code", GLAccNo);
        //             if DimValue."Shortcut Dimension 3 Two" <> '' then
        //                 CreateDistProjectValue(EntryNo, DimValueCode, DimValue."Shortcut Dimension 3 Two", GLAccNo);
        //             if DimValue."Shortcut Dimension 3 Three" <> '' then
        //                 CreateDistProjectValue(EntryNo, DimValueCode, DimValue."Shortcut Dimension 3 Three", GLAccNo);
        //         until DimValue.Next() = 0;

        // end;
    end;

    procedure DistributionProjectLinesArePopulatedFromDistributionSetup(GLEntry: Record "G/L Entry"; RecDimensionValue: Code[20]; GLAccNo: code[20]; Integer: Integer)
    var
        DistributionLine: Record "Distribution Line";
        DistributionRuleFilter: Record "Distribution Rule Filter";
        DimensionValue: Record "Dimension Value";
        Dimension: Record Dimension;
        GLAccount: Record "G/L Account";
        BranchCodeList: List of [Text];
        BranchCodeList2: List of [Text];
        IntegerOfList: Integer;
        IntegerOfList2: Integer;
        ValueOfText: Text;
        BranchCode: Text;
        EmployeeCount: Integer;
        DimensionValueCode: Code[20];
        ProjectCode: Boolean;
    begin
        DistributionYear := GetDistributionYear(GLEntry."Entry No.");
        DistributionMonth := GetDistributionMonth(GLEntry."Entry No.");
        DistributionLine.SetRange("Shortcut Dimension 2 Code", RecDimensionValue);
        DistributionLine.SetRange(Year, DistributionYear);
        DistributionLine.SetRange(Month, DistributionMonth);
        if (DistributionLine.FindSet() = true) then
            repeat
                BranchCodeList.Add(DistributionLine."Shortcut Dimension 2 Code");
                EmployeeCount += 1;
            until DistributionLine.Next() = 0;

        for IntegerOfList := 1 to BranchCodeList.Count do begin
            ValueOfText := BranchCodeList.Get(IntegerOfList);
            if (BranchCodeList2.IndexOf(ValueOfText) = 0) then
                BranchCodeList2.Add(ValueOfText);
        end;

        for IntegerOfList2 := 1 to BranchCodeList2.Count do begin
            if (BranchCode = '') then
                BranchCode := BranchCodeList2.Get(IntegerOfList2)
            else
                BranchCode += '|' + BranchCodeList2.Get(IntegerOfList2)
        end;

        if (DistributionRuleFilter.Get(GLEntry."Entry No.") = false) then
            exit;

        if (DistributionRuleFilter."Sales Invoice" = true) then begin
            if (DistributionRuleFilter."Distribution Options" = DistributionRuleFilter."Distribution Options"::"Single Project") then begin
                if ((GLEntry."Document Type"::Invoice = GLEntry."Document Type") and (GLEntry."Credit Amount" <> 0)) then begin
                    if (GLAccount.Get(GLEntry."G/L Account No.") = true) then begin
                        if (Dimension.Get('PROJECT') = true) then begin
                            DimensionValue.SetRange("Dimension Code", Dimension.Code);
                            DimensionValue.SetRange(Name, GLAccount.Name);
                            if (DimensionValue.FindFirst() = true) then
                                DimensionValueCode := DimensionValue.Code
                            else
                                Error('There is no Dimension With the Name of %1', GLAccount.Name);
                        end;
                    end;

                    DistributionLine.SetRange("Shortcut Dimension 2 Code", RecDimensionValue);
                    DistributionLine.SetRange(Year, DistributionYear);
                    DistributionLine.SetRange(Month, DistributionMonth);
                    if (DistributionLine.FindSet(false) = true) then begin
                        repeat
                            if (DistributionLine."Shortcut Dimension 3 Code" = DimensionValueCode) then begin
                                ProjectCode := true;
                                DistributionProjectAndDistributionLinesAreUpdated(GLEntry, DistributionLine, Integer, GLAccNo, EmployeeCount, BranchCode, RecDimensionValue, ProjectCode, DimensionValueCode)
                            end;

                            if (DistributionLine."Shortcut Dimension 3 Two" = DimensionValueCode) then begin
                                ProjectCode := true;
                                DistributionProjectAndDistributionLinesAreUpdated(GLEntry, DistributionLine, Integer, GLAccNo, EmployeeCount, BranchCode, RecDimensionValue, ProjectCode, DimensionValueCode)
                            end;

                            if (DistributionLine."Shortcut Dimension 3 Three" = DimensionValueCode) then begin
                                ProjectCode := true;
                                DistributionProjectAndDistributionLinesAreUpdated(GLEntry, DistributionLine, Integer, GLAccNo, EmployeeCount, BranchCode, RecDimensionValue, ProjectCode, DimensionValueCode)
                            end;

                            if (DistributionLine."Shortcut Dimension 3 Four" = DimensionValueCode) then begin
                                ProjectCode := true;
                                DistributionProjectAndDistributionLinesAreUpdated(GLEntry, DistributionLine, Integer, GLAccNo, EmployeeCount, BranchCode, RecDimensionValue, ProjectCode, DimensionValueCode)
                            end;

                            if (DistributionLine."Shortcut Dimension 3 Five" = DimensionValueCode) then begin
                                ProjectCode := true;
                                DistributionProjectAndDistributionLinesAreUpdated(GLEntry, DistributionLine, Integer, GLAccNo, EmployeeCount, BranchCode, RecDimensionValue, ProjectCode, DimensionValueCode)
                            end;

                        until DistributionLine.Next() = 0
                    end;
                end;
            end else
                if (DistributionRuleFilter."Distribution Options" = DistributionRuleFilter."Distribution Options"::"Multiple Project") then
                    DistributionProjectAndDistributionLinesAreUpdated(GLEntry, DistributionLine, Integer, GLAccNo, EmployeeCount, BranchCode, RecDimensionValue, ProjectCode, '');
        end else
            DistributionProjectAndDistributionLinesAreUpdated(GLEntry, DistributionLine, Integer, GLAccNo, EmployeeCount, BranchCode, RecDimensionValue, ProjectCode, '');
    end;

    local procedure DistributionProjectAndDistributionLinesAreUpdated(GLEntry: Record "G/L Entry"; var DistributionLine: Record "Distribution Line"; Integer: Integer;
    GLAccNo: code[20]; EmployeeCount: Integer; BranchCode: Text; RecDimensionValue: Code[20]; ProjectCode: Boolean; DimensionValueCode: Code[20])
    var
        DistributionRule: Record "Distribution Rule";
        DistributionProject: Record "Distribution Project";
        DistributionRuleFilter: Record "Distribution Rule Filter";
        DistributionProjectLineNo: Integer;
        ProjectIncrementValue: Integer;
        DistRuleIncrementValue: Integer;
        DistributionRuleLineNo: Integer;
    begin
        if (ProjectCode = true) then begin
            Clear(DistributionProject);
            DistributionRuleFilter.Get(GLEntry."Entry No.");
            DistributionProject.Init();
            DistributionProject."Entry No." := GLEntry."Entry No.";
            DistributionProject."Shortcut Dimension 2 Code" := DistributionLine."Shortcut Dimension 2 Code";
            DistributionProject."Shortcut Dimension 3 Code" := DistributionLine."Shortcut Dimension 1 Code";
            DistributionProject."Line No." := DistributionProject."Line No." + 1000;
            if (Integer = 0) then
                DistributionProject."Project Amount" := Round(DistributionRuleFilter."Distribution Amount" / EmployeeCount, 0.01);

            DistributionProject."Project Line" := true;
            DistributionProject."Emp. Count" := GetEmployeeCountFromDistributionSetup(DistributionYear, DistributionMonth, DistributionLine."Shortcut Dimension 1 Code", BranchCode);
            EmployeeCount2 += DistributionProject."Emp. Count";
            DistributionProject."G/L Account No." := GLAccNo;
            DistributionProject.Insert(false);
            ProjectIncrementValue := 1;

            /* Distribution Rule tab is populating values*/

            Clear(DistributionRule);
            DistributionRule.SetRange("Entry No.", GLEntry."Entry No.");
            if (DistributionLine."Shortcut Dimension 3 Code" = DimensionValueCode) then begin
                DistRuleIncrementValue += 1;
                DistributionRuleLineNo := InsertDistributionRuleLineFromDistributionSetup(DistributionRuleFilter, DistributionRule, DistributionLine, DistributionRuleLineNo);
                DistributionRule."Shortcut Dimension 3 Code" := DistributionLine."Shortcut Dimension 3 Code";
                DistributionRule."Emp. Project Percentage" := DistributionLine."Percentage One";
                DistributionRule."Posting Date" := GLEntry."Posting Date";
                DistributionRule."Document No." := GLEntry."Document No.";
                GLEntry.CalcFields("Account Category");
                if ((GLEntry."Account Category"::Expense) = GLEntry."Account Category") then begin
                    DistributionRule."Account Category" := GLEntry."Account Category";
                end else
                    DistributionRule."Account Category" := GLEntry."Account Category";

                DistributionRule."Team Leader No." := DistributionLine."Team leader No.";
                DistributionRule."Team Leader" := DistributionLine."Team Leader";
                DistributionRule."Manager No." := DistributionLine."Manager No.";
                DistributionRule.Manager := DistributionLine.Manager;
                DistributionRule.Modify(false);
            end;

            if (DistributionLine."Shortcut Dimension 3 Two" = DimensionValueCode) then begin
                DistRuleIncrementValue += 1;
                DistributionRuleLineNo := InsertDistributionRuleLineFromDistributionSetup(DistributionRuleFilter, DistributionRule, DistributionLine, DistributionRuleLineNo);
                DistributionRule."Shortcut Dimension 3 Code" := DistributionLine."Shortcut Dimension 3 Two";
                DistributionRule."Emp. Project Percentage" := DistributionLine."Percentage Two";
                DistributionRule."Posting Date" := GLEntry."Posting Date";
                DistributionRule."Document No." := GLEntry."Document No.";
                GLEntry.CalcFields("Account Category");
                if ((GLEntry."Account Category"::Expense) = GLEntry."Account Category") then begin
                    DistributionRule."Account Category" := GLEntry."Account Category";
                end else
                    DistributionRule."Account Category" := GLEntry."Account Category";

                DistributionRule."Team Leader No." := DistributionLine."Team leader No.";
                DistributionRule."Team Leader" := DistributionLine."Team Leader";
                DistributionRule."Manager No." := DistributionLine."Manager No.";
                DistributionRule.Manager := DistributionLine.Manager;
                DistributionRule.Modify(false);
            end;

            if (DistributionLine."Shortcut Dimension 3 Three" = DimensionValueCode) then begin
                DistRuleIncrementValue += 1;
                DistributionRuleLineNo := InsertDistributionRuleLineFromDistributionSetup(DistributionRuleFilter, DistributionRule, DistributionLine, DistributionRuleLineNo);
                DistributionRule."Shortcut Dimension 3 Code" := DistributionLine."Shortcut Dimension 3 Three";
                DistributionRule."Emp. Project Percentage" := DistributionLine."Percentage Three";
                DistributionRule."Posting Date" := GLEntry."Posting Date";
                DistributionRule."Document No." := GLEntry."Document No.";
                GLEntry.CalcFields("Account Category");
                if ((GLEntry."Account Category"::Expense) = GLEntry."Account Category") then begin
                    DistributionRule."Account Category" := GLEntry."Account Category";
                end else
                    DistributionRule."Account Category" := GLEntry."Account Category";

                DistributionRule."Team Leader No." := DistributionLine."Team leader No.";
                DistributionRule."Team Leader" := DistributionLine."Team Leader";
                DistributionRule."Manager No." := DistributionLine."Manager No.";
                DistributionRule.Manager := DistributionLine.Manager;
                DistributionRule.Modify(false);
            end;

            if (DistributionLine."Shortcut Dimension 3 Four" = DimensionValueCode) then begin
                DistRuleIncrementValue += 1;
                DistributionRuleLineNo := InsertDistributionRuleLineFromDistributionSetup(DistributionRuleFilter, DistributionRule, DistributionLine, DistributionRuleLineNo);
                DistributionRule."Shortcut Dimension 3 Code" := DistributionLine."Shortcut Dimension 3 Four";
                DistributionRule."Emp. Project Percentage" := DistributionLine."Percentage Four";
                DistributionRule."Posting Date" := GLEntry."Posting Date";
                DistributionRule."Document No." := GLEntry."Document No.";
                GLEntry.CalcFields("Account Category");
                if ((GLEntry."Account Category"::Expense) = GLEntry."Account Category") then begin
                    DistributionRule."Account Category" := GLEntry."Account Category";
                end else
                    DistributionRule."Account Category" := GLEntry."Account Category";

                DistributionRule."Team Leader No." := DistributionLine."Team leader No.";
                DistributionRule."Team Leader" := DistributionLine."Team Leader";
                DistributionRule."Manager No." := DistributionLine."Manager No.";
                DistributionRule.Manager := DistributionLine.Manager;
                DistributionRule.Modify(false);
            end;

            if (DistributionLine."Shortcut Dimension 3 Five" = DimensionValueCode) then begin
                DistRuleIncrementValue += 1;
                DistributionRuleLineNo := InsertDistributionRuleLineFromDistributionSetup(DistributionRuleFilter, DistributionRule, DistributionLine, DistributionRuleLineNo);
                DistributionRule."Shortcut Dimension 3 Code" := DistributionLine."Shortcut Dimension 3 Five";
                DistributionRule."Emp. Project Percentage" := DistributionLine."Percentage Five";
                DistributionRule."Posting Date" := GLEntry."Posting Date";
                DistributionRule."Document No." := GLEntry."Document No.";
                GLEntry.CalcFields("Account Category");
                if ((GLEntry."Account Category"::Expense) = GLEntry."Account Category") then begin
                    DistributionRule."Account Category" := GLEntry."Account Category";
                end else
                    DistributionRule."Account Category" := GLEntry."Account Category";

                DistributionRule."Team Leader No." := DistributionLine."Team leader No.";
                DistributionRule."Team Leader" := DistributionLine."Team Leader";
                DistributionRule."Manager No." := DistributionLine."Manager No.";
                DistributionRule.Manager := DistributionLine.Manager;
                DistributionRule.Modify(false);
            end;

            Clear(ProjectIncrementValue);
            Clear(DistRuleIncrementValue);
        end else begin
            DistributionRuleFilter.Get(GLEntry."Entry No.");
            if (DistributionLine.FindSet(false) = true) then begin
                repeat
                    Clear(DistributionProject);
                    DistributionProject.Init();
                    DistributionProject."Entry No." := GLEntry."Entry No.";
                    DistributionProject."Shortcut Dimension 2 Code" := DistributionLine."Shortcut Dimension 2 Code";
                    DistributionProject."Shortcut Dimension 3 Code" := DistributionLine."Shortcut Dimension 1 Code";
                    if (Integer = 0) then
                        DistributionProject."Project Amount" := Round(DistributionRuleFilter."Distribution Amount" / EmployeeCount, 0.01);

                    DistributionProject."Project Line" := true;
                    DistributionProject."Line No." := DistributionProjectLineNo + 1000;
                    DistributionProject."Emp. Count" := GetEmployeeCountFromDistributionSetup(DistributionYear, DistributionMonth, DistributionLine."Shortcut Dimension 1 Code", BranchCode);
                    EmployeeCount2 += DistributionProject."Emp. Count";
                    DistributionProject."G/L Account No." := GLAccNo;
                    DistributionProject.Insert(false);
                    ProjectIncrementValue := 1;

                    /* Distribution Rule tab is populating values*/

                    Clear(DistributionRule);
                    DistributionRule.SetRange("Entry No.", GLEntry."Entry No.");
                    if (DistributionLine."Shortcut Dimension 3 Code" <> '') then begin
                        DistRuleIncrementValue += 1;
                        DistributionRuleLineNo := InsertDistributionRuleLineFromDistributionSetup(DistributionRuleFilter, DistributionRule, DistributionLine, DistributionRuleLineNo);
                        DistributionRule."Shortcut Dimension 3 Code" := DistributionLine."Shortcut Dimension 3 Code";
                        DistributionRule."Emp. Project Percentage" := DistributionLine."Percentage One";
                        DistributionRule."Posting Date" := GLEntry."Posting Date";
                        DistributionRule."Document No." := GLEntry."Document No.";
                        GLEntry.CalcFields("Account Category");
                        if ((GLEntry."Account Category"::Expense) = GLEntry."Account Category") then begin
                            DistributionRule."Account Category" := GLEntry."Account Category";
                        end else
                            DistributionRule."Account Category" := GLEntry."Account Category";

                        DistributionRule."Team Leader No." := DistributionLine."Team leader No.";
                        DistributionRule."Team Leader" := DistributionLine."Team Leader";
                        DistributionRule."Manager No." := DistributionLine."Manager No.";
                        DistributionRule.Manager := DistributionLine.Manager;
                        DistributionRule.Modify(false);
                    end;

                    if (DistributionLine."Shortcut Dimension 3 Two" <> '') then begin
                        DistRuleIncrementValue += 1;
                        DistributionRuleLineNo := InsertDistributionRuleLineFromDistributionSetup(DistributionRuleFilter, DistributionRule, DistributionLine, DistributionRuleLineNo);
                        DistributionRule."Shortcut Dimension 3 Code" := DistributionLine."Shortcut Dimension 3 Two";
                        DistributionRule."Emp. Project Percentage" := DistributionLine."Percentage Two";
                        DistributionRule."Posting Date" := GLEntry."Posting Date";
                        DistributionRule."Document No." := GLEntry."Document No.";
                        GLEntry.CalcFields("Account Category");
                        if ((GLEntry."Account Category"::Expense) = GLEntry."Account Category") then begin
                            DistributionRule."Account Category" := GLEntry."Account Category";
                        end else
                            DistributionRule."Account Category" := GLEntry."Account Category";

                        DistributionRule."Team Leader No." := DistributionLine."Team leader No.";
                        DistributionRule."Team Leader" := DistributionLine."Team Leader";
                        DistributionRule."Manager No." := DistributionLine."Manager No.";
                        DistributionRule.Manager := DistributionLine.Manager;
                        DistributionRule.Modify(false);
                    end;

                    if (DistributionLine."Shortcut Dimension 3 Three" <> '') then begin
                        DistRuleIncrementValue += 1;
                        DistributionRuleLineNo := InsertDistributionRuleLineFromDistributionSetup(DistributionRuleFilter, DistributionRule, DistributionLine, DistributionRuleLineNo);
                        DistributionRule."Shortcut Dimension 3 Code" := DistributionLine."Shortcut Dimension 3 Three";
                        DistributionRule."Emp. Project Percentage" := DistributionLine."Percentage Three";
                        DistributionRule."Posting Date" := GLEntry."Posting Date";
                        DistributionRule."Document No." := GLEntry."Document No.";
                        GLEntry.CalcFields("Account Category");
                        if ((GLEntry."Account Category"::Expense) = GLEntry."Account Category") then begin
                            DistributionRule."Account Category" := GLEntry."Account Category";
                        end else
                            DistributionRule."Account Category" := GLEntry."Account Category";

                        DistributionRule."Team Leader No." := DistributionLine."Team leader No.";
                        DistributionRule."Team Leader" := DistributionLine."Team Leader";
                        DistributionRule."Manager No." := DistributionLine."Manager No.";
                        DistributionRule.Manager := DistributionLine.Manager;
                        DistributionRule.Modify(false);
                    end;

                    if (DistributionLine."Shortcut Dimension 3 Four" <> '') then begin
                        DistRuleIncrementValue += 1;
                        DistributionRuleLineNo := InsertDistributionRuleLineFromDistributionSetup(DistributionRuleFilter, DistributionRule, DistributionLine, DistributionRuleLineNo);
                        DistributionRule."Shortcut Dimension 3 Code" := DistributionLine."Shortcut Dimension 3 Four";
                        DistributionRule."Emp. Project Percentage" := DistributionLine."Percentage Four";
                        DistributionRule."Posting Date" := GLEntry."Posting Date";
                        DistributionRule."Document No." := GLEntry."Document No.";
                        GLEntry.CalcFields("Account Category");
                        if ((GLEntry."Account Category"::Expense) = GLEntry."Account Category") then begin
                            DistributionRule."Account Category" := GLEntry."Account Category";
                        end else
                            DistributionRule."Account Category" := GLEntry."Account Category";

                        DistributionRule."Team Leader No." := DistributionLine."Team leader No.";
                        DistributionRule."Team Leader" := DistributionLine."Team Leader";
                        DistributionRule."Manager No." := DistributionLine."Manager No.";
                        DistributionRule.Manager := DistributionLine.Manager;
                        DistributionRule.Modify(false);
                    end;

                    if (DistributionLine."Shortcut Dimension 3 Five" <> '') then begin
                        DistRuleIncrementValue += 1;
                        DistributionRuleLineNo := InsertDistributionRuleLineFromDistributionSetup(DistributionRuleFilter, DistributionRule, DistributionLine, DistributionRuleLineNo);
                        DistributionRule."Shortcut Dimension 3 Code" := DistributionLine."Shortcut Dimension 3 Five";
                        DistributionRule."Emp. Project Percentage" := DistributionLine."Percentage five";
                        DistributionRule."Posting Date" := GLEntry."Posting Date";
                        DistributionRule."Document No." := GLEntry."Document No.";
                        GLEntry.CalcFields("Account Category");
                        if ((GLEntry."Account Category"::Expense) = GLEntry."Account Category") then begin
                            DistributionRule."Account Category" := GLEntry."Account Category";
                        end else
                            DistributionRule."Account Category" := GLEntry."Account Category";

                        DistributionRule."Team Leader No." := DistributionLine."Team leader No.";
                        DistributionRule."Team Leader" := DistributionLine."Team Leader";
                        DistributionRule."Manager No." := DistributionLine."Manager No.";
                        DistributionRule.Manager := DistributionLine.Manager;
                        DistributionRule.Modify(false);
                    end;

                    Clear(ProjectIncrementValue);
                    Clear(DistRuleIncrementValue);
                until DistributionLine.Next() = 0;
            end;
        end;
    end;

    procedure DistributeAmountbasedOnBranch(GLEntryNo: Integer)
    var
        DistributionProject: Record "Distribution Project";
        DistributionRuleFilter: Record "Distribution Rule Filter";
        DistributionProjectAmount: Decimal;
        DistEmployee: Integer;
    begin
        // Amount should be Distributed based on Employee Count
        DistributionProject.SetRange("Entry No.", GLEntryNo);
        if (DistributionProject.FindSet(false) = true) then begin
            Clear(EmployeeCount2);
            repeat
                EmployeeCount2 += DistributionProject."Emp. Count";
            until DistributionProject.Next() = 0;
        end;

        DistributionRuleFilter.Get(GLEntryNo);
        DistributionProject.SetRange("Entry No.", GLEntryNo);
        if (DistributionProject.FindSet(false) = true) then
            repeat
                DistributionProject."Project Amount" := Round(DistributionRuleFilter."Distribution Amount" / EmployeeCount2, 0.01);
                DistributionProject.Modify(false);
            until DistributionProject.Next() = 0;

        if ((DistributionRuleFilter."Distribution Amount One" = 0) and (DistributionRuleFilter."Dimension Value One" <> '')) then begin
            DistributionProject.SetRange("Shortcut Dimension 2 Code", DistributionRuleFilter."Dimension Value One");
            Clear(DistributionProjectAmount);
            if (DistributionProject.FindSet(false) = true) then
                repeat
                    DistributionProjectAmount += DistributionProject."Project Amount";
                until DistributionProject.Next() = 0;

            DistributionRuleFilter."Distribution Amount One" := DistributionProjectAmount;
            DistributionRuleFilter.Modify(false);
        end;

        if ((DistributionRuleFilter."Distribution Amount Two" = 0) and (DistributionRuleFilter."Dimension Value Two" <> '')) then begin
            DistributionProject.SetRange("Shortcut Dimension 2 Code", DistributionRuleFilter."Dimension Value Two");
            Clear(DistributionProjectAmount);
            if (DistributionProject.FindSet(false) = true) then
                repeat
                    DistributionProjectAmount += DistributionProject."Project Amount";
                until DistributionProject.Next() = 0;

            DistributionRuleFilter."Distribution Amount Two" := DistributionProjectAmount;
            DistributionProject.SetRange("Shortcut Dimension 2 Code", DistributionRuleFilter."Dimension Value One");
            if (DistributionProject.FindSet(false) = true) then begin
                Clear(DistributionRuleFilter."Distribution Amount One");
                repeat
                    DistributionRuleFilter."Distribution Amount One" += DistributionProject."Project Amount";
                until DistributionProject.Next() = 0;
            end;

            DistributionRuleFilter.Modify(false);
        end;

        if ((DistributionRuleFilter."Distribution Amount Three" = 0) and (DistributionRuleFilter."Dimension Value Three" <> '')) then begin
            DistributionProject.SetRange("Shortcut Dimension 2 Code", DistributionRuleFilter."Dimension Value Three");
            Clear(DistributionProjectAmount);
            if (DistributionProject.FindSet(false) = true) then
                repeat
                    DistributionProjectAmount += DistributionProject."Project Amount";
                until DistributionProject.Next() = 0;

            DistributionRuleFilter."Distribution Amount Three" := DistributionProjectAmount;
            DistributionProject.SetRange("Shortcut Dimension 2 Code", DistributionRuleFilter."Dimension Value One");
            if (DistributionProject.FindSet(false) = true) then begin
                Clear(DistributionRuleFilter."Distribution Amount One");
                repeat
                    DistributionRuleFilter."Distribution Amount One" += DistributionProject."Project Amount";
                until DistributionProject.Next() = 0;

            end;
            DistributionProject.SetRange("Shortcut Dimension 2 Code", DistributionRuleFilter."Dimension Value Two");
            if (DistributionProject.FindSet(false) = true) then begin
                Clear(DistributionRuleFilter."Distribution Amount Two");
                repeat
                    DistributionRuleFilter."Distribution Amount Two" += DistributionProject."Project Amount";
                until DistributionProject.Next() = 0;
            end;

            DistributionRuleFilter.Modify(false);
        end;

        if ((DistributionRuleFilter."Distribution Amount Four" = 0) and (DistributionRuleFilter."Dimension Value Four" <> '')) then begin
            DistributionProject.SetRange("Shortcut Dimension 2 Code", DistributionRuleFilter."Dimension Value Four");
            Clear(DistributionProjectAmount);
            if (DistributionProject.FindSet(false) = true) then
                repeat
                    DistributionProjectAmount += DistributionProject."Project Amount";
                until DistributionProject.Next() = 0;

            DistributionRuleFilter."Distribution Amount Four" := DistributionProjectAmount;
            DistributionProject.SetRange("Shortcut Dimension 2 Code", DistributionRuleFilter."Dimension Value One");
            if (DistributionProject.FindSet(false) = true) then begin
                Clear(DistributionRuleFilter."Distribution Amount One");
                repeat
                    DistributionRuleFilter."Distribution Amount One" += DistributionProject."Project Amount";
                until DistributionProject.Next() = 0;
            end;

            DistributionProject.SetRange("Shortcut Dimension 2 Code", DistributionRuleFilter."Dimension Value Two");
            if (DistributionProject.FindSet(false) = true) then begin
                Clear(DistributionRuleFilter."Distribution Amount Two");
                repeat
                    DistributionRuleFilter."Distribution Amount Two" += DistributionProject."Project Amount";
                until DistributionProject.Next() = 0;
            end;

            DistributionProject.SetRange("Shortcut Dimension 2 Code", DistributionRuleFilter."Dimension Value Three");
            if (DistributionProject.FindSet(false) = true) then begin
                Clear(DistributionRuleFilter."Distribution Amount Three");
                repeat
                    DistributionRuleFilter."Distribution Amount Three" += DistributionProject."Project Amount";
                until DistributionProject.Next() = 0;
            end;

            DistributionRuleFilter.Modify(false);
        end;

        if ((DistributionRuleFilter."Distribution Amount Five" = 0) and (DistributionRuleFilter."Dimension Value Five" <> '')) then begin
            DistributionProject.SetRange("Shortcut Dimension 2 Code", DistributionRuleFilter."Dimension Value Five");
            Clear(DistributionProjectAmount);
            if (DistributionProject.FindSet(false) = true) then
                repeat
                    DistributionProjectAmount += DistributionProject."Project Amount";
                until DistributionProject.Next() = 0;

            DistributionRuleFilter."Distribution Amount Five" := DistributionProjectAmount;
            DistributionProject.SetRange("Shortcut Dimension 2 Code", DistributionRuleFilter."Dimension Value One");
            if (DistributionProject.FindSet(false) = true) then begin
                Clear(DistributionRuleFilter."Distribution Amount One");
                repeat
                    DistributionRuleFilter."Distribution Amount One" += DistributionProject."Project Amount";
                until DistributionProject.Next() = 0;
            end;

            DistributionProject.SetRange("Shortcut Dimension 2 Code", DistributionRuleFilter."Dimension Value Two");
            if (DistributionProject.FindSet(false) = true) then begin
                Clear(DistributionRuleFilter."Distribution Amount Two");
                repeat
                    DistributionRuleFilter."Distribution Amount Two" += DistributionProject."Project Amount";
                until DistributionProject.Next() = 0;
            end;

            DistributionProject.SetRange("Shortcut Dimension 2 Code", DistributionRuleFilter."Dimension Value Three");
            if (DistributionProject.FindSet(false) = true) then begin
                Clear(DistributionRuleFilter."Distribution Amount Three");
                repeat
                    DistributionRuleFilter."Distribution Amount Three" += DistributionProject."Project Amount";
                until DistributionProject.Next() = 0;
            end;

            DistributionProject.SetRange("Shortcut Dimension 2 Code", DistributionRuleFilter."Dimension Value Four");
            if (DistributionProject.FindSet(false) = true) then begin
                Clear(DistributionRuleFilter."Distribution Amount Four");
                repeat
                    DistributionRuleFilter."Distribution Amount Four" += DistributionProject."Project Amount";
                until DistributionProject.Next() = 0;
            end;

            DistributionRuleFilter.Modify(false);
        end;
    end;

    procedure GetDistributionYear(GlEntryNo: Integer): Text
    var
        GlEntry: Record "G/L Entry";
        DistributionPostingDate: Date;
        PostingDate: Text;
        Month: Text;
        Year: Text;
    begin
        if (GlEntry.Get(GlEntryNo) = true) then begin
            DistributionPostingDate := GLEntry."Posting Date";
            PostingDate := Format(DistributionPostingDate); // 01/10/23
            Year := CopyStr(PostingDate, 7, 8);
            DistributionYear := InsStr(Year, '20', 1);
        end;

        exit(DistributionYear)
    end;

    procedure GetDistributionMonth(GlEntryNo: Integer): Text
    var
        GlEntry: Record "G/L Entry";
        UserPersonalization: Record "User Personalization";
        ID: Text;
        DistributionPostingDate: Date;
        PostingDate: Text;
        Month: Text;
        Year: Text;
    begin
        ID := UserSecurityId();
        if (GlEntry.Get(GlEntryNo) = true) then begin
            DistributionPostingDate := GLEntry."Posting Date";
            if (UserPersonalization.Get(ID) = true) then
                if (UserPersonalization."Locale ID" = 1033) then begin
                    PostingDate := Format(DistributionPostingDate); // 11/27/2024(M/D/Y)
                    Month := CopyStr(PostingDate, 1, 2);
                    DistributionMonth := ConvertingMonthAndYear(Month);
                end else begin
                    if (UserPersonalization."Locale ID" = 2057) then begin
                        PostingDate := Format(DistributionPostingDate); // 27/11/2024(D/M/Y)
                        Month := CopyStr(PostingDate, 4, 2);
                        DistributionMonth := ConvertingMonthAndYear(Month);
                    end;
                end;
        end;
        exit(DistributionMonth);
    end;

    procedure ConvertingMonthAndYear(Month: Text): Text
    var
        MonthDataTxt: Text;
    begin
        case Month of
            '01':
                MonthDataTxt := 'JAN';
            '02':
                MonthDataTxt := 'FEB';
            '03':
                MonthDataTxt := 'MAR';
            '04':
                MonthDataTxt := 'APR';
            '05':
                MonthDataTxt := 'MAY';
            '06':
                MonthDataTxt := 'JUN';
            '07':
                MonthDataTxt := 'JUL';
            '08':
                MonthDataTxt := 'AUG';
            '09':
                MonthDataTxt := 'SEP';
            '10':
                MonthDataTxt := 'OCT';
            '11':
                MonthDataTxt := 'NOV';
            '12':
                MonthDataTxt := 'DEC';
        end;
        exit(MonthDataTxt);
    end;


    /* Getting Employee Count From Distribution Line*/
    procedure GetEmployeeCountFromDistributionSetup(Year: Text; Month: Text; EmployeeCode: Code[20]; BranchCode: Text): Integer
    var
        Distributionline: Record "Distribution Line";
        EmpCount: Integer;
    begin
        Distributionline.SetRange(Year, Year);
        Distributionline.SetRange(Month, Month);
        Distributionline.SetRange("Shortcut Dimension 1 Code", EmployeeCode);
        Distributionline.SetFilter("Shortcut Dimension 2 Code", BranchCode);
        if (Distributionline.FindSet() = true) then
            repeat
                Clear(EmpCount);
                EmpCount += 1
            until Distributionline.Next() = 0;
        exit(EmpCount);
    end;

    local procedure CreateDistProjectValue(EntryNo: Integer; DimValueTwoCode: Code[20]; DimValueThreeCode: Code[20]; GLAccNo: code[20])
    var
        DistProject: Record "Distribution Project";
    begin
        Clear(DistProject);
        if DistProject.Get(EntryNo, DimValueThreeCode, DimValueTwoCode) then
            exit;
        Clear(DistProject);
        DistProject."Entry No." := EntryNo;
        DistProject."Shortcut Dimension 2 Code" := DimValueTwoCode;
        DistProject."Shortcut Dimension 3 Code" := DimValueThreeCode;
        // DistProject."Emp. Count" := GetEmployeeCount(DimValueTwoCode, DimValueThreeCode);
        DistProject."G/L Account No." := GLAccNo;
        DistProject."Line No." := 0;
        DistProject.Insert();

    end;

    local procedure ProceedDimProjectType(GLEntry: Record "G/L Entry"): Boolean
    var
        GenLedSetup: Record "General Ledger Setup";
        DimSetEntry: Record "Dimension Set Entry";
    begin
        GenLedSetup.Get();
        if DimSetEntry.Get(GLEntry."Dimension Set ID", GenLedSetup."Shortcut Dimension 8 Code") then
            exit(true);
        if DimSetEntry.Get(GLEntry."Dimension Set ID", GenLedSetup."Shortcut Dimension 7 Code") then
            exit(true);
        if DimSetEntry.Get(GLEntry."Dimension Set ID", GenLedSetup."Shortcut Dimension 6 Code") then
            exit(true);
        if DimSetEntry.Get(GLEntry."Dimension Set ID", GenLedSetup."Shortcut Dimension 5 Code") then
            exit(true);
        if DimSetEntry.Get(GLEntry."Dimension Set ID", GenLedSetup."Shortcut Dimension 4 Code") then
            exit(true);
        if DimSetEntry.Get(GLEntry."Dimension Set ID", GenLedSetup."Shortcut Dimension 3 Code") then
            exit(true);
        if DimSetEntry.Get(GLEntry."Dimension Set ID", GenLedSetup."Shortcut Dimension 2 Code") then
            exit(false);

    end;

    local procedure GetDimValueCode(GLEntry: Record "G/L Entry"; ValNo: Integer): Code[20]
    var
        GenLedSetup: Record "General Ledger Setup";
        DimSetEntry: Record "Dimension Set Entry";
    begin
        GenLedSetup.Get();
        if ValNo = 2 then
            if DimSetEntry.Get(GLEntry."Dimension Set ID", GenLedSetup."Shortcut Dimension 2 Code") then
                exit(DimSetEntry."Dimension Value Code");
        if ValNo = 3 then
            if DimSetEntry.Get(GLEntry."Dimension Set ID", GenLedSetup."Shortcut Dimension 3 Code") then
                exit(DimSetEntry."Dimension Value Code");
    end;

    procedure UploadDistributionRuleFromExcel(var DistRule: Record "Distribution Rule")
    var
        DistRuleFilter: Record "Distribution Rule Filter";
        TempExcelBuffer: Record "Excel Buffer" temporary;
        FileManage: Codeunit "File Management";
        InStm: InStream;
        FromFile: Text[250];
        FileName: Text[250];
        UploadExcelMsg: Text[100];
        SheetName: Text[100];
        SheetVal: Decimal;
        EmployeeCode: Code[20];
        EntryNo: Integer;
        LineNo: Integer;
        MaxRowCount: Integer;
        RowCount: Integer;
        LoopInx: Integer;
    begin
        UploadExcelMsg := 'Please select the excel file.';
        UploadIntoStream(UploadExcelMsg, '', '', FromFile, InStm);
        if FromFile <> '' then begin
            FileName := FileManage.GetFileName(FromFile);
            SheetName := TempExcelBuffer.SelectSheetsNameStream(InStm);
        end
        else
            Error('No excel file selected.');

        Clear(TempExcelBuffer);
        TempExcelBuffer.DeleteAll();
        TempExcelBuffer.OpenBookStream(InStm, SheetName);
        TempExcelBuffer.ReadSheet();
        Clear(TempExcelBuffer);
        if TempExcelBuffer.FindLast() then
            MaxRowCount := TempExcelBuffer."Row No.";

        Clear(TempExcelBuffer);
        for RowCount := 2 to MaxRowCount do begin
            LoopInx += 1;
            Clear(EntryNo);
            Evaluate(EntryNo, GetValueAtCell(TempExcelBuffer, RowCount, 5));
            if LoopInx = 1 then
                DistRuleFilter.Get(EntryNo);

            DistRule.Reset();
            DistRule.SetRange("Entry No.", EntryNo);
            Clear(EmployeeCode);
            Evaluate(EmployeeCode, GetValueAtCell(TempExcelBuffer, RowCount, 1));
            DistRule.SetRange("Shortcut Dimension 1 Code", EmployeeCode);
            if (DistRule.FindFirst() = false) then
                Error('Line entry not found entry no %1 line no %2.', EntryNo, LineNo);

            Clear(SheetVal);
            Evaluate(SheetVal, GetValueAtCell(TempExcelBuffer, RowCount, 4));
            if DistRuleFilter."Negative Allocation" then
                DistRule.Validate("Amount Allocated", -SheetVal)
            else
                DistRule.Validate("Amount Allocated", SheetVal);

            DistRule.Modify(false);
        end;

        if (DistRuleFilter."Dist Single Line Amount" <> true) then
            CombineProjectCodeAndAmountThroughAlocationActionFromExcel(DistRule);

        Message('Allocation amount update process completed.');
    end;

    procedure UploadDistributionProjectFromExcel(DistributionProject: Record "Distribution Project")
    var
        DistRuleFilter: Record "Distribution Rule Filter";
        TempExcelBuffer: Record "Excel Buffer" temporary;
        FileManage: Codeunit "File Management";
        InStm: InStream;
        FromFile: Text[250];
        FileName: Text[250];
        UploadExcelMsg: Text[100];
        SheetName: Text[100];
        SheetVal: Decimal;
        DimensionAmountOne: Decimal;
        DimensionAmountTwo: Decimal;
        DimensionAmountThree: Decimal;
        DimensionAmountFour: Decimal;
        DimensionAmountFive: Decimal;
        DimensionTotalAmount: Decimal;
        DistributionTotalProjectAmount: Decimal;
        AddDimensionValue: Decimal;
        SubDimensionValue: Decimal;
        EmployeeCode: Code[20];
        EmployeeCodeTxt: Text;
        EntryNo: Integer;
        LineNo: Integer;
        MaxRowCount: Integer;
        RowCount: Integer;
        LoopInx: Integer;
    begin
        UploadExcelMsg := 'Please select the excel file.';
        UploadIntoStream(UploadExcelMsg, '', '', FromFile, InStm);
        if FromFile <> '' then begin
            FileName := FileManage.GetFileName(FromFile);
            SheetName := TempExcelBuffer.SelectSheetsNameStream(InStm);
        end
        else
            Error('No excel file selected.');

        Clear(TempExcelBuffer);
        TempExcelBuffer.DeleteAll();
        TempExcelBuffer.OpenBookStream(InStm, SheetName);
        TempExcelBuffer.ReadSheet();
        Clear(TempExcelBuffer);
        if TempExcelBuffer.FindLast() then
            MaxRowCount := TempExcelBuffer."Row No.";

        Clear(TempExcelBuffer);
        for RowCount := 2 to MaxRowCount do begin
            LoopInx += 1;
            Clear(EntryNo);
            Evaluate(EntryNo, GetValueAtCell(TempExcelBuffer, RowCount, 1));
            if LoopInx = 1 then
                DistRuleFilter.Get(EntryNo);

            DistributionProject.Reset();
            DistributionProject.SetRange("Entry No.", EntryNo);
            Clear(LineNo);
            Evaluate(LineNo, GetValueAtCell(TempExcelBuffer, RowCount, 7));
            DistributionProject.SetRange("Line No.", LineNo);
            Evaluate(EmployeeCode, GetValueAtCell(TempExcelBuffer, RowCount, 3));
            DistributionProject.SetRange("Shortcut Dimension 3 Code", EmployeeCode);
            if (DistributionProject.FindFirst() = false) then
                Error('Line entry not found entry no %1 line no %2.', EntryNo, LineNo);

            Clear(SheetVal);
            Evaluate(SheetVal, GetValueAtCell(TempExcelBuffer, RowCount, 5));
            if DistRuleFilter."Negative Allocation" then
                DistributionProject.Validate("Project Amount", -SheetVal)
            else
                DistributionProject.Validate("Project Amount", SheetVal);

            DistributionProject.Modify(false);
        end;

        DimensionTotalAmount := ((DistRuleFilter."Distribution Amount One") + (DistRuleFilter."Distribution Amount Two") + (DistRuleFilter."Distribution Amount Three") + (DistRuleFilter."Distribution Amount Four") + (DistRuleFilter."Distribution Amount Five"));
        if (DimensionTotalAmount <> DistRuleFilter."Distribution Amount") then begin
            Error('Dimensions Total Amount Must be equal to Distribution Amount');
        end;

        if (DistRuleFilter."Dimension Value One" <> '') then begin
            DistributionProject.Reset();
            DistributionProject.SetRange("Entry No.", EntryNo);
            DistributionProject.SetRange("Shortcut Dimension 2 Code", DistRuleFilter."Dimension Value One");
            if (DistributionProject.FindSet(false) = true) then
                repeat
                    DimensionAmountOne += DistributionProject."Project Amount";
                until DistributionProject.Next() = 0;

            if (DimensionAmountOne <> DistRuleFilter."Distribution Amount One") then begin
                Clear(AddDimensionValue);
                Clear(SubDimensionValue);
                AddDimensionValue := DimensionAmountOne + 10;
                SubDimensionValue := DimensionAmountOne - 10;
                if ((AddDimensionValue < DistRuleFilter."Distribution Amount One") or (DistRuleFilter."Distribution Amount One" < SubDimensionValue)) then
                    Error('In Employee tab Project Amount Must be equal to Distribution Amount One');
            end;
        end;
        if (DistRuleFilter."Dimension Value Two" <> '') then begin
            DistributionProject.SetRange("Entry No.", EntryNo);
            DistributionProject.SetRange("Shortcut Dimension 2 Code", DistRuleFilter."Dimension Value Two");
            if (DistributionProject.FindSet(false) = true) then
                repeat
                    DimensionAmountTwo += DistributionProject."Project Amount";
                until DistributionProject.Next() = 0;

            if (DimensionAmountTwo <> DistRuleFilter."Distribution Amount Two") then begin
                Clear(AddDimensionValue);
                Clear(SubDimensionValue);
                AddDimensionValue := DimensionAmountTwo + 10;
                SubDimensionValue := DimensionAmountTwo - 10;
                if ((AddDimensionValue < DistRuleFilter."Distribution Amount Two") or (DistRuleFilter."Distribution Amount Two" < SubDimensionValue)) then
                    Error('In Employee tab Project Amount Must be equal to Distribution Amount Two');
            end;
        end;
        if (DistRuleFilter."Dimension Value Three" <> '') then begin
            DistributionProject.SetRange("Entry No.", EntryNo);
            DistributionProject.SetRange("Shortcut Dimension 2 Code", DistRuleFilter."Dimension Value Three");
            if (DistributionProject.FindSet(false) = true) then
                repeat
                    DimensionAmountThree += DistributionProject."Project Amount";
                until DistributionProject.Next() = 0;

            if (DimensionAmountThree <> DistRuleFilter."Distribution Amount Three") then begin
                Clear(AddDimensionValue);
                Clear(SubDimensionValue);
                AddDimensionValue := DimensionAmountThree + 10;
                SubDimensionValue := DimensionAmountThree - 10;
                if ((AddDimensionValue < DistRuleFilter."Distribution Amount Three") or (DistRuleFilter."Distribution Amount Three" < SubDimensionValue)) then
                    Error('In Employee tab Project Amount Must be equal to Distribution Amount Three');
            end;
        end;
        if (DistRuleFilter."Dimension Value Four" <> '') then begin
            DistributionProject.SetRange("Entry No.", EntryNo);
            DistributionProject.SetRange("Shortcut Dimension 2 Code", DistRuleFilter."Dimension Value Four");
            if (DistributionProject.FindSet(false) = true) then
                repeat
                    DimensionAmountFour += DistributionProject."Project Amount";
                until DistributionProject.Next() = 0;

            if (DimensionAmountFour <> DistRuleFilter."Distribution Amount Four") then begin
                Clear(AddDimensionValue);
                Clear(SubDimensionValue);
                AddDimensionValue := DimensionAmountFour + 10;
                SubDimensionValue := DimensionAmountFour - 10;
                if ((AddDimensionValue < DistRuleFilter."Distribution Amount Four") or (DistRuleFilter."Distribution Amount Four" < SubDimensionValue)) then
                    Error('In Employee tab Project Amount Must be equal to Distribution Amount Four');
            end;
        end;
        if (DistRuleFilter."Dimension Value Five" <> '') then begin
            DistributionProject.SetRange("Entry No.", EntryNo);
            DistributionProject.SetRange("Shortcut Dimension 2 Code", DistRuleFilter."Dimension Value Five");
            if (DistributionProject.FindSet(false) = true) then
                repeat
                    DimensionAmountFive += DistributionProject."Project Amount";
                until DistributionProject.Next() = 0;

            if (DimensionAmountFive <> DistRuleFilter."Distribution Amount Five") then begin
                Clear(AddDimensionValue);
                Clear(SubDimensionValue);
                AddDimensionValue := DimensionAmountFive + 10;
                SubDimensionValue := DimensionAmountFive - 10;
                if ((AddDimensionValue < DistRuleFilter."Distribution Amount Five") or (DistRuleFilter."Distribution Amount Five" < SubDimensionValue)) then
                    Error('In Employee tab Project Amount Must be equal to Distribution Amount Five');
            end;
        end;
        Message('Allocation amount update process completed.');

        DistributionProject.Reset();
        DistributionProject.SetRange("Entry No.", EntryNo);
        if (DistributionProject.FindSet(false) = true) then
            repeat
                DistributionTotalProjectAmount += DistributionProject."Project Amount";
            until DistributionProject.Next() = 0;
        DeleteDistributionProjectLinesWhichAmountIsEqualToZero(DistributionProject."Entry No.", DistributionProject, 0);

        if (DistributionTotalProjectAmount <> DistRuleFilter."Distribution Amount") then begin
            Clear(AddDimensionValue);
            Clear(SubDimensionValue);
            AddDimensionValue := DistributionTotalProjectAmount + 10;
            SubDimensionValue := DistributionTotalProjectAmount - 10;
            if ((AddDimensionValue < DistRuleFilter."Distribution Amount") or (DistRuleFilter."Distribution Amount" < SubDimensionValue)) then
                Error('Distribution Total Project Amount Must be equal to Distribution Amount');
        end;
        Commit();
    end;

    procedure DeleteDistributionProjectLinesWhichAmountIsEqualToZero(GLEntryNo: Integer; DistributionProject: Record "Distribution Project"; Integer: Integer)
    var
        DistributionRuleFilter: Record "Distribution Rule Filter";
        Amount: Decimal;
        AddDistAmount: Decimal;
        SubDistAmount: Decimal;
    begin
        if (Integer = 0) then begin
            DistributionProject.SetRange("Entry No.", GLEntryNo);
            if (DistributionProject.FindSet(false) = true) then
                repeat
                    if (DistributionProject."Project Amount" = 0) then
                        DistributionProject.Delete(false);
                until DistributionProject.Next() = 0;
        end else begin
            DistributionProject.SetRange("Entry No.", GLEntryNo);
            if (DistributionProject.FindSet(false) = true) then
                repeat
                    Amount += DistributionProject."Project Amount";
                until DistributionProject.Next() = 0;

            if (DistributionRuleFilter.Get(GLEntryNo) = false) then
                exit;

            if (Amount = 0) then
                exit;

            if (DistributionRuleFilter."Distribution Amount" <> Amount) then
                AddDistAmount := DistributionRuleFilter."Distribution Amount" + 10;
            SubDistAmount := DistributionRuleFilter."Distribution Amount" - 10;
            if ((AddDistAmount >= Amount) or (Amount >= SubDistAmount)) then begin
                if (DistributionProject.FindSet(false) = true) then
                    repeat
                        if (DistributionProject."Project Amount" = 0) then
                            DistributionProject.Delete(false);
                    until DistributionProject.Next() = 0;
            end;
        end;
    end;

    local procedure GetValueAtCell(var TempExcelBuffer: Record "Excel Buffer" temporary; RowNo: Integer; ColNo: Integer): Text
    begin
        If TempExcelBuffer.Get(RowNo, ColNo) then
            exit(TempExcelBuffer."Cell Value as Text")
        else
            exit('');
    end;

    procedure UpdateGLEntryApplied(DocNo: Code[20]; DimTwoCode: Code[20]; DimOneCode: Code[20]; GLAccNo: code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        Clear(GLEntry);
        GLEntry.SetCurrentKey("Document No.");
        GLEntry.SetRange("Document No.", DocNo);
        GLEntry.SetFilter("Global Dimension 1 Code", DimOneCode);
        GLEntry.SetFilter("Global Dimension 2 Code", DimTwoCode);
        GLEntry.SetFilter("G/L Account No.", GLAccNo);
        GLEntry.ModifyAll("Distributio Rule Applied", true);
    end;

    procedure UpdateGLEntryUnApplied(DocNo: Code[20]; DimTwoCode: Code[20]; DimOneCode: Code[20]; GLAccNo: code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        Clear(GLEntry);
        GLEntry.SetCurrentKey("Document No.");
        GLEntry.SetRange("Document No.", DocNo);
        GLEntry.SetFilter("Global Dimension 1 Code", DimOneCode);
        GLEntry.SetFilter("Global Dimension 2 Code", DimTwoCode);
        GLEntry.SetFilter("G/L Account No.", GLAccNo);
        GLEntry.ModifyAll("Distributio Rule Applied", false);
    end;

    procedure UpdateGLEntryAppEntryNo(EntryNo: Integer; DocNo: Code[20]; DimTwoCode: Code[20]; DimOneCode: Code[20]; GLAccNo: code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        Clear(GLEntry);
        GLEntry.SetCurrentKey("Document No.");
        GLEntry.SetRange("Document No.", DocNo);
        GLEntry.SetFilter("Global Dimension 1 Code", DimOneCode);
        GLEntry.SetFilter("Global Dimension 2 Code", DimTwoCode);
        GLEntry.SetFilter("G/L Account No.", GLAccNo);
        GLEntry.ModifyAll("Dist. Entry No Applied", EntryNo);
    end;

    procedure CombineProjectCodeAndAmountThroughAlocationActionFromExcel(AzzDistributionRule: Record "Distribution Rule")
    var
        DistributionProjectLine: Record "Distribution Project Line";
        DistributionProject: Record "Distribution Project";
        BranchCodeList: List of [Text];
        BranchCodeListTwo: List of [Text];
        IntegerOfList: Integer;
        IntegerOfListTwo: Integer;
        CombinedAllcAmount: Decimal;
        DistributionTotalAmount: Decimal;
        ValueOfText: Text;
        BranchCode: Text;
    begin
        DistributionProject.SetRange("Entry No.", AzzDistributionRule."Entry No.");
        DistributionProject.FindFirst();
        AzzDistributionRule.Reset();
        AzzDistributionRule.SetRange("Entry No.", Distributionproject."Entry No.");
        if (AzzDistributionRule.FindSet(false) = true) then
            repeat
                BranchCodeList.Add(AzzDistributionRule."Shortcut Dimension 3 Code");
            until AzzDistributionRule.Next() = 0;

        for IntegerOfList := 1 to BranchCodeList.Count do begin
            ValueOfText := BranchCodeList.Get(IntegerOfList);
            if (BranchCodeListTwo.IndexOf(ValueOfText) = 0) then begin
                BranchCodeListTwo.Add(ValueOfText);
            end;
        end;

        for IntegerOfListTwo := 1 to BranchCodeListTwo.Count do begin
            DistributionProjectLine.Init();
            DistributionProjectLine."Entry No." := AzzDistributionRule."Entry No.";
            DistributionProjectLine."Line No." := DistributionProjectLine."Line No." + 1000;
            DistributionProjectLine."Shortcut Dimension 3 Code" := BranchCodeListTwo.Get(IntegerOfListTwo);

            AzzDistributionRule.Reset();
            AzzDistributionRule.SetRange("Entry No.", Distributionproject."Entry No.");
            AzzDistributionRule.SetRange("Shortcut Dimension 3 Code", DistributionProjectLine."Shortcut Dimension 3 Code");
            if (AzzDistributionRule.FindSet(false) = true) then
                repeat
                    CombinedAllcAmount += AzzDistributionRule."Amount Allocated";
                until AzzDistributionRule.Next() = 0;
            DistributionProjectLine."Amount Allocated" := CombinedAllcAmount;
            DistributionTotalAmount += DistributionProjectLine."Amount Allocated";
            DistributionProjectLine.Insert(false);
            Clear(CombinedAllcAmount);
        end;
    end;

    procedure CheckSalesInvoice(DocNo: Code[20]): Boolean
    var
        SalesInvHead: Record "Sales Invoice Header";
    begin
        if SalesInvHead.Get(DocNo) then
            exit(true);
    end;

    procedure GetGLDebitAmount(DocNo: Code[20]; DimTwoCode: Code[20]; DimOneCode: Code[20]; GLAccNo: code[20]): Decimal
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetCurrentKey("Document No.");
        GLEntry.SetRange("Document No.", DocNo);
        GLEntry.SetFilter("Global Dimension 1 Code", DimOneCode);
        GLEntry.SetFilter("Global Dimension 2 Code", DimTwoCode);
        GLEntry.SetFilter("G/L Account No.", GLAccNo);
        GLEntry.CalcSums("Debit Amount");
        exit(GLEntry."Debit Amount");
    end;

    procedure GetGLCreditAmount(DocNo: Code[20]; DimTwoCode: Code[20]; DimOneCode: Code[20]; GLAccNo: code[20]): Decimal
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetCurrentKey("Document No.");
        GLEntry.SetRange("Document No.", DocNo);
        GLEntry.SetFilter("Global Dimension 1 Code", DimOneCode);
        GLEntry.SetFilter("Global Dimension 2 Code", DimTwoCode);
        GLEntry.SetFilter("G/L Account No.", GLAccNo);
        GLEntry.SetFilter("Account Category", '%1|%2', GLEntry."Account Category"::Income, GLEntry."Account Category"::Expense);
        GLEntry.CalcSums("Credit Amount");
        exit(GLEntry."Credit Amount");
    end;

    // local procedure GetEmployeeCount(DimValueTwoCode: Code[20]; DimValueThreeCode: Code[20]): Integer
    // var
    //     DimValue: Record "Dimension Value";
    //     EmpCount: Integer;
    // begin
    //     DimValue.SetRange("Shortcut Dimension 2 Code", DimValueTwoCode);
    //     DimValue.SetRange("Distribute Enable", true);
    //     DimValue.SetRange("Shortcut Dimension 3 Code", DimValueThreeCode);
    //     EmpCount := DimValue.Count();
    //     DimValue.SetRange("Shortcut Dimension 3 Code");
    //     DimValue.SetRange("Shortcut Dimension 3 Two", DimValueThreeCode);
    //     EmpCount += DimValue.Count();
    //     DimValue.SetRange("Shortcut Dimension 3 Two");
    //     DimValue.SetRange("Shortcut Dimension 3 Three", DimValueThreeCode);
    //     EmpCount += DimValue.Count();
    //     exit(EmpCount);
    // end;


    procedure UpdateDistAmountManually(var DistRuleFilter: Record "Distribution Rule Filter"; FilterVal: Integer)
    var
        DistProject: Record "Distribution Project";
        DistAmount: Decimal;
        DistAmountEquly: Decimal;
        TotEmpCount: Integer;
        Inx: Integer;
    begin
        DistRuleFilter.TestField("Distribution Amount");
        DistProject.SetRange("Entry No.", DistRuleFilter."Entry No.");
        if FilterVal = 1 then
            DistProject.SetRange("Shortcut Dimension 2 Code", DistRuleFilter."Dimension Value One");
        if FilterVal = 2 then
            DistProject.SetRange("Shortcut Dimension 2 Code", DistRuleFilter."Dimension Value Two");
        if FilterVal = 3 then
            DistProject.SetRange("Shortcut Dimension 2 Code", DistRuleFilter."Dimension Value Three");
        if FilterVal = 4 then
            DistProject.SetRange("Shortcut Dimension 2 Code", DistRuleFilter."Dimension Value Four");
        if FilterVal = 5 then
            DistProject.SetRange("Shortcut Dimension 2 Code", DistRuleFilter."Dimension Value Five");
        DistProject.CalcSums("Emp. Count");
        TotEmpCount := DistProject."Emp. Count";
        Inx := DistProject.Count();
        if not DistProject.FindSet() then
            exit;
        if TotEmpCount = 0 then
            exit;
        if FilterVal = 0 then begin
            DistAmount := DistRuleFilter."Distribution Amount";
            DistAmountEquly := Round(DistAmount / TotEmpCount, 0.01);
        end;
        if FilterVal = 1 then begin
            DistAmount := DistRuleFilter."Distribution Amount One";
            DistAmountEquly := Round(DistAmount / TotEmpCount, 0.01);
        end;
        if FilterVal = 2 then begin
            DistAmount := DistRuleFilter."Distribution Amount Two";
            DistAmountEquly := Round(DistAmount / TotEmpCount, 0.01);
        end;
        if FilterVal = 3 then begin
            DistAmount := DistRuleFilter."Distribution Amount Three";
            DistAmountEquly := Round(DistAmount / TotEmpCount, 0.01);
        end;
        if FilterVal = 4 then begin
            DistAmount := DistRuleFilter."Distribution Amount Four";
            DistAmountEquly := Round(DistAmount / TotEmpCount, 0.01);
        end;
        if FilterVal = 5 then begin
            DistAmount := DistRuleFilter."Distribution Amount Five";
            DistAmountEquly := Round(DistAmount / TotEmpCount, 0.01);
        end;
        repeat
            if Inx <> 1 then
                DistProject."Project Amount" := DistAmountEquly * DistProject."Emp. Count"
            else
                DistProject."Project Amount" := DistAmount;
            DistProject.Modify();
            DistAmount := DistAmount - DistProject."Project Amount";
            Inx -= 1;
        until DistProject.Next() = 0;

    end;

    procedure CheckDistRuleExist(EntryNo: Integer)
    var
        DisRuleFilter: Record "Distribution Rule Filter";
        DistRule: Record "Distribution Rule";
    begin
        DisRuleFilter.Get(EntryNo);
        if (DisRuleFilter."Distribution Method" <> DisRuleFilter."Distribution Method"::Manually) then
            DisRuleFilter.TestField("Sales Invoice", false);
        DistRule.SetRange("Entry No.", EntryNo);
        if DistRule.FindSet() then
            if (DisRuleFilter."Distribution Method" <> DisRuleFilter."Distribution Method"::Manually) then
                Error('Distribution line exists, please delete lines.');
    end;

    procedure CheckDistProjectExist(EntryNo: Integer): Boolean
    var
        DistProject: Record "Distribution Project";
    begin
        Clear(DistProject);
        DistProject.SetRange("Entry No.", EntryNo);
        if not DistProject.FindSet() then
            exit(false);
        DistProject.CalcSums("Project Amount");
        if DistProject."Project Amount" = 0 then
            exit(false);
        exit(true);
    end;

    procedure CopyFromDimValueOne(Year: Code[20]; Month: Code[20])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionValue: Record "Dimension Value";
        DistributionLine: Record "Distribution Line";
    begin
        if (Confirm('Do you want to copy from employee details?', false) = false) then
            exit;

        DistributionLine.SetRange(Year, Year);
        DistributionLine.SetRange(Month, Month);
        if (DistributionLine.FindSet(false) = true) then
            DistributionLine.DeleteAll();

        Clear(DistributionLine);
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.TestField("Shortcut Dimension 1 Code");
        DimensionValue.SetRange("Dimension Code", GeneralLedgerSetup."Shortcut Dimension 1 Code");
        if (DimensionValue.FindSet(false) = false) then
            exit;
        repeat
            Clear(DistributionLine);
            DistributionLine.Init();
            DistributionLine.Validate(Year, Year);
            DistributionLine.Validate(Month, Month);
            DistributionLine.Validate("Shortcut Dimension 1 Code", DimensionValue.Code);
            // DistributionLine.Validate("Shortcut Dimension 2 Code", DimensionValue."Shortcut Dimension 2 Code");
            DistributionLine.Insert(true);
        until DimensionValue.Next() = 0;

        Message('Copy from employee details completed.');
    end;

    procedure CopyFromPreviousDetails(Year: Code[20]; Month: Code[20]; PreYear: Code[20]; PreMonth: Code[20])
    var
        FromDistributionLine: Record "Distribution Line";
        ToDistributionLine: Record "Distribution Line";
        DistributionSubform: Page "Distribution Subfrom";
        TotalPercentage: Decimal;
        Caption: Text;
    begin
        if (Confirm('Do you want to copy employee details from previous year and month?', false) = false) then
            exit;

        Clear(FromDistributionLine);
        FromDistributionLine.SetRange(Year, PreYear);
        FromDistributionLine.SetRange(Month, PreMonth);
        if (FromDistributionLine.FindSet(false) = false) then
            Error('Employee details not found for previous year and month');

        Clear(ToDistributionLine);
        ToDistributionLine.SetRange(Year, Year);
        ToDistributionLine.SetRange(Month, Month);
        if (ToDistributionLine.FindSet(false) = false) then
            ToDistributionLine.DeleteAll();
        repeat
            Clear(ToDistributionLine);
            ToDistributionLine.Init();
            ToDistributionLine.Validate(Year, Year);
            ToDistributionLine.Validate(Month, Month);
            ToDistributionLine.Validate("Shortcut Dimension 1 Code", FromDistributionLine."Shortcut Dimension 1 Code");
            ToDistributionLine.Validate("Team leader No.", FromDistributionLine."Team leader No.");
            ToDistributionLine.Validate("Team Leader", FromDistributionLine."Team Leader");
            ToDistributionLine.Validate("Manager No.", FromDistributionLine."Manager No.");
            ToDistributionLine.Validate(Manager, FromDistributionLine.Manager);
            ToDistributionLine.Validate("Shortcut Dimension 2 Code", FromDistributionLine."Shortcut Dimension 2 Code");
            ToDistributionLine.Validate("Shortcut Dimension 3 Code", FromDistributionLine."Shortcut Dimension 3 Code");
            ToDistributionLine.Validate("Shortcut Dimension 3 Two", FromDistributionLine."Shortcut Dimension 3 Two");
            ToDistributionLine.Validate("Shortcut Dimension 3 Three", FromDistributionLine."Shortcut Dimension 3 Three");
            ToDistributionLine.Validate("Shortcut Dimension 3 Four", FromDistributionLine."Shortcut Dimension 3 Four");
            ToDistributionLine.Validate("Shortcut Dimension 3 Five", FromDistributionLine."Shortcut Dimension 3 Five");
            ToDistributionLine.Validate("Percentage One", FromDistributionLine."Percentage One");
            ToDistributionLine.Validate("Percentage Two", FromDistributionLine."Percentage Two");
            ToDistributionLine.Validate("Percentage Three", FromDistributionLine."Percentage Three");
            ToDistributionLine.Validate("Percentage Four", FromDistributionLine."Percentage Four");
            ToDistributionLine.Validate("Percentage Five", FromDistributionLine."Percentage Five");
            TotalPercentage := (ToDistributionLine."Percentage One" + ToDistributionLine."Percentage Two" + ToDistributionLine."Percentage Three" + ToDistributionLine."Percentage Four" + ToDistributionLine."Percentage Five");
            if (TotalPercentage <> 100) then
                if (TotalPercentage > 100) then
                    Error('%1 Employee Code Percentage must be equal to 100 But It is greaterthan 100', ToDistributionLine."Shortcut Dimension 1 Code")
                else
                    Error('%1 Employee Code Percentage must be equal to 100 But It is Lessthan 100', ToDistributionLine."Shortcut Dimension 1 Code");

            ToDistributionLine.Insert(true);
        until FromDistributionLine.Next() = 0;
        Message('Copy from employee details completed.');
    end;

    procedure UpdateToDimValueOne(Year: Code[20]; Month: Code[20])
    var
        GeneLedSetup: Record "General Ledger Setup";
        DimValue: Record "Dimension Value";
        DistLine: Record "Distribution Line";
    begin
        if not Confirm('Do you want update employee details?', false) then
            exit;

        DistLine.SetRange(Year, Year);
        DistLine.SetRange(Month, Month);
        if not DistLine.FindSet() then
            exit;

        GeneLedSetup.Get();
        GeneLedSetup.TestField("Shortcut Dimension 1 Code");
        DimValue.SetRange("Dimension Code", GeneLedSetup."Shortcut Dimension 1 Code");
        if not DimValue.FindSet() then
            exit;
        repeat
            // DimValue.Year := Year;
            // DimValue.Month := Month;
            DimValue."Distribute Enable" := false;
            DimValue.Modify();
        until DimValue.Next() = 0;
        DimValue.FindSet();
        repeat
            Clear(DimValue);
            DimValue.Get(GeneLedSetup."Shortcut Dimension 1 Code", DistLine."Shortcut Dimension 1 Code");
            // DimValue."Shortcut Dimension 2 Code" := DistLine."Shortcut Dimension 2 Code";
            // DimValue."Shortcut Dimension 3 Code" := DistLine."Shortcut Dimension 3 Code";
            // DimValue."Shortcut Dimension 3 Two" := DistLine."Shortcut Dimension 3 Two";
            // DimValue."Shortcut Dimension 3 Three" := DistLine."Shortcut Dimension 3 Three";
            // DimValue."Percentage One" := DistLine."Percentage One";
            // DimValue."Percentage Two" := DistLine."Percentage Two";
            // DimValue."Percentage Three" := DistLine."Percentage Three";
            // DimValue.Year := Year;
            // DimValue.Month := Month;
            DimValue."Distribute Enable" := true;
            DimValue.Modify();
        until DistLine.Next() = 0;
        Message('Employee details update completed.');
    end;

    procedure UpdateDisSetupLineXL(Year: Code[20]; Month: Code[20])
    var
        DistributionLine: Record "Distribution Line";
        TempExcelBuffer: Record "Excel Buffer" temporary;
        DimensionValue: Record "Dimension Value";
        FileManage: Codeunit "File Management";
        InStm: InStream;
        ShortcutDimension1Code: Code[20];
        FromFile: Text[250];
        FileName: Text[250];
        UploadExcelMsg: Text[100];
        SheetName: Text[100];
        SheetVal, TotalPercentage : Decimal;
        LineNo: Integer;
        MaxRowCount: Integer;
        RowCount: Integer;
        ProjectFour, ProjectFive : Text;
    begin
        UploadExcelMsg := 'Please select the excel file.';
        UploadIntoStream(UploadExcelMsg, '', '', FromFile, InStm);
        if (FromFile <> '') then begin
            FileName := FileManage.GetFileName(FromFile);
            SheetName := TempExcelBuffer.SelectSheetsNameStream(InStm);
        end else
            Error('No excel file selected.');

        Clear(TempExcelBuffer);
        TempExcelBuffer.DeleteAll();
        TempExcelBuffer.OpenBookStream(InStm, SheetName);
        TempExcelBuffer.ReadSheet();
        Clear(TempExcelBuffer);
        if TempExcelBuffer.FindLast() then
            MaxRowCount := TempExcelBuffer."Row No.";

        Clear(TempExcelBuffer);
        DistributionLine.SetRange(Year, Year);
        DistributionLine.SetRange(Month, Month);
        if (DistributionLine.FindSet(false) = true) then
            DistributionLine.DeleteAll(false);

        for RowCount := 2 to MaxRowCount do begin
            if Year <> GetValueAtCell(TempExcelBuffer, RowCount, 1) then
                Error('Year must be same.');

            if Month <> GetValueAtCell(TempExcelBuffer, RowCount, 2) then
                Error('Month must be same.');

            Clear(DistributionLine);
            DistributionLine.Init();
            DistributionLine.Year := Year;
            DistributionLine.Month := Month;
            ShortcutDimension1Code := GetValueAtCell(TempExcelBuffer, RowCount, 3);
            DimensionValue.SetRange("Dimension Code", 'EMPLOYEE');
            DimensionValue.SetRange(Code, ShortcutDimension1Code);
            if (DimensionValue.FindFirst() = false) then begin
                Error('This Employee Code is not avaliable in Dimensions %1', ShortcutDimension1Code);
            end;

            DistributionLine."Shortcut Dimension 1 Code" := ShortcutDimension1Code;
            DistributionLine."Team leader No." := GetValueAtCell(TempExcelBuffer, RowCount, 4);
            DimensionValue.Reset();
            DimensionValue.SetRange("Dimension Code", 'EMPLOYEE');
            DimensionValue.SetRange(Code, DistributionLine."Team leader No.");
            if (DimensionValue.FindFirst() = true) then begin
                if (DimensionValue."Team Leader" = false) then
                    Error('Teamleaders %1 boolean should be true on the Dimensions page', DistributionLine."Team leader No.");
            end;

            DistributionLine."Team Leader" := GetValueAtCell(TempExcelBuffer, RowCount, 5);
            DistributionLine."Manager No." := GetValueAtCell(TempExcelBuffer, RowCount, 6);
            DimensionValue.Reset();
            DimensionValue.SetRange("Dimension Code", 'EMPLOYEE');
            DimensionValue.SetRange(Code, DistributionLine."Manager No.");
            if (DimensionValue.FindFirst() = true) then begin
                if (DimensionValue.Manager = false) then
                    Error('Managers %1 boolean should be true on the Dimensions page', DistributionLine."Manager No.");
            end;

            DistributionLine.Manager := GetValueAtCell(TempExcelBuffer, RowCount, 7);
            DistributionLine."Shortcut Dimension 2 Code" := GetValueAtCell(TempExcelBuffer, RowCount, 8);
            DistributionLine."Shortcut Dimension 3 Code" := GetValueAtCell(TempExcelBuffer, RowCount, 9);
            Clear(SheetVal);
            Evaluate(SheetVal, GetValueAtCell(TempExcelBuffer, RowCount, 10));
            DistributionLine."Percentage One" := SheetVal;
            TotalPercentage += SheetVal;
            Clear(SheetVal);
            DistributionLine."Shortcut Dimension 3 Two" := GetValueAtCell(TempExcelBuffer, RowCount, 11);
            Evaluate(SheetVal, GetValueAtCell(TempExcelBuffer, RowCount, 12));
            DistributionLine."Percentage Two" := SheetVal;
            TotalPercentage += SheetVal;
            Clear(SheetVal);
            DistributionLine."Shortcut Dimension 3 Three" := GetValueAtCell(TempExcelBuffer, RowCount, 13);
            Evaluate(SheetVal, GetValueAtCell(TempExcelBuffer, RowCount, 14));
            DistributionLine."Percentage Three" := SheetVal;
            TotalPercentage += SheetVal;
            Clear(SheetVal);
            ProjectFour := (GetValueAtCell(TempExcelBuffer, 1, 15));
            if (ProjectFour = 'Project Four') then begin
                DistributionLine."Shortcut Dimension 3 Four" := GetValueAtCell(TempExcelBuffer, RowCount, 15);
                Evaluate(SheetVal, GetValueAtCell(TempExcelBuffer, RowCount, 16));
                DistributionLine."Percentage Four" := SheetVal;
                TotalPercentage += SheetVal;
            end;

            ProjectFive := (GetValueAtCell(TempExcelBuffer, 1, 17));
            if (ProjectFive = 'Project Five') then begin
                Clear(SheetVal);
                DistributionLine."Shortcut Dimension 3 Five" := GetValueAtCell(TempExcelBuffer, RowCount, 17);
                Evaluate(SheetVal, GetValueAtCell(TempExcelBuffer, RowCount, 18));
                DistributionLine."Percentage Five" := SheetVal;
                TotalPercentage += SheetVal;

            end;

            DistributionLine.Insert(false);
            if (TotalPercentage <> 100) then
                Error('%1 Employee Code Total Percentage Must be equal to 100', ShortcutDimension1Code);

            Clear(TotalPercentage);
        end;

        Message('Excel update process completed.');
    end;

    local procedure CheckTheTotalPercentageOfDistributionLines(Year: Code[20]; Month: Code[20]; ShortcutDimension1Code: Code[20]; DistributionLine: Record "Distribution Line")
    begin

    end;

    procedure InsertDistributionRuleLineFromDistributionSetup(var DistributionruleFilter: Record "Distribution Rule Filter"; var DistributionRule: Record "Distribution Rule"; var DistributionLines: Record "Distribution Line"; DistributionRuleLineNo: Integer): Integer
    var
        RuleIncrement: Integer;
        LastLineNo: Integer;
    begin
        DistributionRule.Init();
        DistributionRule."Entry No." := DistributionruleFilter."Entry No.";
        if (DistributionRule.FindLast() = true) then
            DistributionRule."Line No." := DistributionRule."Line No." + 1000
        else
            DistributionRule."Line No." := DistributionRuleLineNo + 1000;

        DistributionRule."Shortcut Dimension 1 Code" := DistributionLines."Shortcut Dimension 1 Code";
        DistributionRule."Shortcut Dimension 2 Code" := DistributionLines."Shortcut Dimension 2 Code";
        DistributionRule."G/L Account No." := DistributionruleFilter."G/L Account No.";
        DistributionRule."Company Name" := CompanyName;
        DistributionRule.Insert();
        exit(DistributionRule."Line No.");
    end;

    procedure CombineProjectCodeAndAmount(AzzDistributionRule: Record "Distribution Rule"; Distributionproject: Record "Distribution Project")
    var
        DistributionProjectLine: Record "Distribution Project Line";
        BranchCodeList: List of [Text];
        BranchCodeListTwo: List of [Text];
        IntegerOfList: Integer;
        IntegerOfListTwo: Integer;
        CombinedAllcAmount: Decimal;
        DistributionTotalAmount: Decimal;
        ValueOfText: Text;
        BranchCode: Text;
    begin
        AzzDistributionRule.Reset();
        AzzDistributionRule.SetRange("Entry No.", Distributionproject."Entry No.");
        if (AzzDistributionRule.FindSet(false) = true) then
            repeat
                BranchCodeList.Add(AzzDistributionRule."Shortcut Dimension 3 Code");
            until AzzDistributionRule.Next() = 0;

        for IntegerOfList := 1 to BranchCodeList.Count do begin
            ValueOfText := BranchCodeList.Get(IntegerOfList);
            if (BranchCodeListTwo.IndexOf(ValueOfText) = 0) then begin
                BranchCodeListTwo.Add(ValueOfText);
            end;
        end;

        for IntegerOfListTwo := 1 to BranchCodeListTwo.Count do begin
            DistributionProjectLine.Init();
            DistributionProjectLine."Entry No." := AzzDistributionRule."Entry No.";
            DistributionProjectLine."Line No." := DistributionProjectLine."Line No." + 1000;
            DistributionProjectLine."Shortcut Dimension 3 Code" := BranchCodeListTwo.Get(IntegerOfListTwo);

            AzzDistributionRule.Reset();
            AzzDistributionRule.SetRange("Entry No.", Distributionproject."Entry No.");
            AzzDistributionRule.SetRange("Shortcut Dimension 3 Code", DistributionProjectLine."Shortcut Dimension 3 Code");
            if (AzzDistributionRule.FindSet(false) = true) then
                repeat
                    CombinedAllcAmount += AzzDistributionRule."Amount Allocated";
                until AzzDistributionRule.Next() = 0;
            DistributionProjectLine."Amount Allocated" := CombinedAllcAmount;
            DistributionTotalAmount += DistributionProjectLine."Amount Allocated";
            DistributionProjectLine.Insert(false);
            Clear(CombinedAllcAmount);
        end;
    end;

    procedure CalculateAndUpdateRemainingAmountonDistributionLines(GLEntry: Record "G/L Entry")
    var
        DistributionRule: Record "Distribution Rule";
        DistributionProject: Record "Distribution Project";
        Amount: Decimal;
        RemainingAmount: Decimal;
    begin
        Clear(DistributionProject);
        DistributionProject.SetRange("Entry No.", GLEntry."Entry No.");
        DistributionProject.CalcSums("Project Amount");
        Amount := DistributionProject."Project Amount";
        Clear(DistributionRule);
        DistributionRule.SetRange("Entry No.", GLEntry."Entry No.");
        DistributionRule.CalcSums("Amount Allocated");
        RemainingAmount := Amount - DistributionRule."Amount Allocated";
        if (RemainingAmount <> 0) then begin
            if (RemainingAmount < 10) then begin
                DistributionRule.SetRange("Entry No.", GLEntry."Entry No.");
                DistributionRule.SetFilter("Emp. Project Percentage", '< 80 & <> 90');
                DistributionRule.FindLast();
                DistributionRule."Amount Allocated" += RemainingAmount;
                DistributionRule.Modify(false);
            end;
        end;
    end;

    procedure InDistributionRuleAmountShouldBeUpdatedOnSingleLine(DistributionProject: Record "Distribution Project")
    var
        DistributionRule: Record "Distribution Rule";
        DistributionRulefilter: Record "Distribution Rule Filter";
        DistributionLine: Record "Distribution Line";
        DistributionProjectLine: Record "Distribution Project Line";
        BranchCodeList: List of [Text];
        BranchCodeList2: List of [Text];
        ProjectCodeList: List of [Text];
        ProjectCodeList2: List of [Text];
        ProjectIntegerList: Integer;
        IntegerOfList: Integer;
        IntegerOfListTwo: Integer;
        LineNo: Integer;
        ProjectText: Text;
        ValueOfText: Text;
        BranchCodeTxt: Text;
    begin
        DistributionProjectLine.DeleteAll();
        if (DistributionRulefilter.Get(DistributionProject."Entry No.") = false) then
            exit;

        DistributionRule.Reset();
        DistributionRule.SetRange("Entry No.", DistributionProject."Entry No.");
        if (DistributionRule.FindSet(false) = true) then
            repeat
                BranchCodeList.Add(DistributionRule."Shortcut Dimension 2 Code");
            until DistributionRule.Next() = 0;

        for IntegerOfList := 1 to BranchCodeList.Count do begin
            ValueOfText := BranchCodeList.Get(IntegerOfList);
            if (BranchCodeList2.IndexOf(ValueOfText) = 0) then
                BranchCodeList2.Add(ValueOfText);
        end;

        for IntegerOfListTwo := 1 to BranchCodeList2.count do begin
            BranchCodeTxt := BranchCodeList2.Get(IntegerOfListTwo);

            DistributionRule.Reset();
            DistributionRule.SetRange("Entry No.", DistributionProject."Entry No.");
            DistributionRule.SetRange("Shortcut Dimension 2 Code", BranchCodeTxt);
            if (DistributionRule.FindSet(false) = true) then
                repeat
                    ProjectCodeList.Add(DistributionRule."Shortcut Dimension 3 Code");
                until DistributionRule.Next() = 0;

            for ProjectIntegerList := 1 to ProjectCodeList.Count do begin
                ProjectText := ProjectCodeList.Get(ProjectIntegerList);
                if ((ProjectCodeList2.IndexOf(ProjectText) = 0) or (DistributionProjectLine."Shortcut Dimension 2 Code" <> BranchCodeTxt)) then begin
                    ProjectCodeList2.Add(ProjectText);

                    if (DistributionProjectLine.FindLast() = true) then
                        LineNo := DistributionProjectLine."Line No." + 1000
                    else
                        LineNo := 1000;

                    DistributionProjectLine.Init();
                    DistributionProjectLine."Line No." := LineNo;
                    DistributionProjectLine."Entry No." := DistributionProject."Entry No.";
                    DistributionProjectLine."Shortcut Dimension 3 Code" := ProjectText;
                    DistributionRule.Reset();
                    DistributionRule.SetRange("Entry No.", DistributionProject."Entry No.");
                    DistributionRule.SetRange("Shortcut Dimension 3 Code", ProjectText);
                    DistributionRule.SetRange("Shortcut Dimension 2 Code", BranchCodeTxt);
                    if (DistributionRule.FindSet(false) = true) then
                        repeat
                            DistributionProjectLine."Amount Allocated" += DistributionRule."Amount Allocated";
                        until DistributionRule.Next() = 0;

                    DistributionProjectLine."Shortcut Dimension 2 Code" := BranchCodeTxt;
                    DistributionProjectLine.Insert(false);
                end;
            end;
            Clear(ProjectCodeList2);
            Clear(ProjectCodeList);
        end;
    end;


    procedure DistributionProjectLineAmountUpdatedThroughDistributionProjectAmount(var DistributionProject: Record "Distribution Project")
    var
        DistributionRule: Record "Distribution Rule";
        DistributionRuleTwo: Record "Distribution Rule";
        DistributionProjectLine: Record "Distribution Project Line";
        ProjectCode: Code[20];
        NoOfLines: Integer;
    begin
        DistributionRuleTwo.Reset();
        DistributionRuleTwo.SetRange("Entry No.", DistributionProject."Entry No.");
        DistributionRuleTwo.SetRange("Shortcut Dimension 1 Code", Distributionproject."Shortcut Dimension 3 Code");
        DistributionRuleTwo.SetRange("Shortcut Dimension 2 Code", Distributionproject."Shortcut Dimension 2 Code");
        if (DistributionRuleTwo.FindSet(false) = true) then
            repeat
                DistributionRule.Reset();
                DistributionRule.SetRange("Entry No.", DistributionProject."Entry No.");
                DistributionRule.SetRange("Shortcut Dimension 1 Code", Distributionproject."Shortcut Dimension 3 Code");
                DistributionRule.SetRange("Shortcut Dimension 2 Code", Distributionproject."Shortcut Dimension 2 Code");
                DistributionRule.SetRange("Shortcut Dimension 3 Code", DistributionRuleTwo."Shortcut Dimension 3 Code");
                if (DistributionRule.FindSet(false) = true) then
                    repeat
                        DistributionProjectLine.Reset();
                        DistributionProjectLine.SetRange("Shortcut Dimension 2 Code", Distributionproject."Shortcut Dimension 2 Code");
                        DistributionProjectLine.SetRange("Shortcut Dimension 3 Code", DistributionRuleTwo."Shortcut Dimension 3 Code");
                        if (DistributionProjectLine.FindSet(false) = true) then begin
                            repeat
                                DistributionProjectLine."Amount Allocated" += DistributionRule."Amount Allocated";
                            until DistributionProjectLine.Next() = 0;
                        end else
                            Error('There is No Lines in Distribution ProjectLines on Combined ProjectLine Tab');

                        DistributionProjectLine.Modify(false);
                    until DistributionRule.Next() = 0
            until DistributionRuleTwo.Next() = 0;
    end;

    procedure CheckBeforeClosingDistributionProjectLinePageAmoutIsUpdateOrNot(var DistributionRuleFilter: Record "Distribution Rule Filter"): Decimal
    var
        DistributionProjectLine: Record "Distribution Project Line";
        DistributionProjectLineAmount: Decimal;
        AddDistributionProjectLineAmount: Decimal;
        SubDistributionProjectLineAmount: Decimal;
        Count: Integer;
    begin
        if (DistributionRuleFilter."Dist Single Line Amount" = true) then begin
            DistributionProjectLine.Reset();
            DistributionProjectLine.SetRange("Entry No.", DistributionRuleFilter."Entry No.");
            if (DistributionProjectLine.FindSet(false) = true) then begin
                repeat
                    Count += 1;
                    DistributionProjectLineAmount += DistributionProjectLine."Amount Allocated";
                until DistributionProjectLine.Next() = 0;
            end;
        end;
        exit(DistributionProjectLineAmount);
    end;

    procedure DeleteAndSendErrorDistributionProjectAndDistributionRuleLines(EntryNo: Integer; xRecDimensionValue: Code[20]; IntegerValue: Integer): Boolean
    var
        DistributionRule: Record "Distribution Rule";
        DistributionProject: Record "Distribution Project";
    begin
        DistributionProject.SetRange("Entry No.", EntryNo);
        DistributionProject.SetRange("Shortcut Dimension 2 Code", xRecDimensionValue);
        if (DistributionProject.FindSet(false) = true) then
            DistributionProject.DeleteAll()
        else
            exit(true);

        if (IntegerValue = 1) then begin
            DistributionRule.SetRange("Entry No.", EntryNo);
            DistributionRule.SetRange("Shortcut Dimension 2 Code", xRecDimensionValue);
            if (DistributionRule.FindSet(false) = true) then begin
                DistributionRule.DeleteAll();
            end;
        end;
    end;

    var
        DistributionYear: Text;
        DistributionMonth: Text;
        EmployeeCount2: Integer;
}