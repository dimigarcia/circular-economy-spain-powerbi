let
    Source = WorksRaw,
    AddColumns = Table.AddColumn(Source, "Fields", each [
        PublicationDate = try Date.FromText([publication_date], [Format = "yyyy-MM-dd"]) otherwise null,
        TopicID = try Text.AfterDelimiter([primary_topic][id], "/", {0, RelativePosition.FromEnd}) otherwise "none",
        SourceID = try Text.AfterDelimiter([primary_location][source][id], "/", {0, RelativePosition.FromEnd}) otherwise "none",
        OAStatus = try [open_access][oa_status] otherwise "unknown",
        IsOpenAccess = try [open_access][is_oa] = true otherwise false,
        TaggedSDG12 = try List.AnyTrue(List.Transform([sustainable_development_goals], each _[id] = "https://metadata.un.org/sdg/12")) otherwise false,
        DOI = [doi]
    ]),
    Expand = Table.ExpandRecordColumn(AddColumns, "Fields",
        {"PublicationDate", "TopicID", "SourceID", "OAStatus", "IsOpenAccess", "TaggedSDG12", "DOI"}),
    Keep = Table.SelectColumns(Expand,
        {"id", "title", "PublicationDate", "type", "cited_by_count", "TopicID", "SourceID", "OAStatus", "IsOpenAccess", "TaggedSDG12", "DOI"}),
    Rename = Table.RenameColumns(Keep, {{"id", "PaperID"}, {"title", "Title"}, {"type", "DocumentType"}, {"cited_by_count", "Citations"}}),
    // Replace null ids with "none" so every paper joins a dimension row
    FillIds = Table.ReplaceValue(Rename, null, "none", Replacer.ReplaceValue, {"TopicID", "SourceID"}),
    // Merge queries: flag papers found by the consumption and production queries
    MergeConsumption = Table.NestedJoin(FillIds, {"PaperID"}, ConsumptionIds, {"id"}, "C", JoinKind.LeftOuter),
    ExpandConsumption = Table.ExpandTableColumn(MergeConsumption, "C", {"MentionsConsumption"}),
    MergeProduction = Table.NestedJoin(ExpandConsumption, {"PaperID"}, ProductionIds, {"id"}, "P", JoinKind.LeftOuter),
    ExpandProduction = Table.ExpandTableColumn(MergeProduction, "P", {"MentionsProduction"}),
    FillFlags = Table.ReplaceValue(ExpandProduction, null, false, Replacer.ReplaceValue, {"MentionsConsumption", "MentionsProduction"}),
    AddFocus = Table.AddColumn(FillFlags, "Focus", each
        if [MentionsConsumption] and [MentionsProduction] then "Both"
        else if [MentionsConsumption] then "Consumption only"
        else if [MentionsProduction] then "Production only"
        else "Neither", type text),
    RemoveNoDate = Table.SelectRows(AddFocus, each [PublicationDate] <> null),
    Types = Table.TransformColumnTypes(RemoveNoDate, {
        {"PaperID", type text}, {"Title", type text}, {"PublicationDate", type date}, {"DocumentType", type text},
        {"Citations", Int64.Type}, {"TopicID", type text}, {"SourceID", type text}, {"OAStatus", type text},
        {"IsOpenAccess", type logical}, {"TaggedSDG12", type logical}, {"DOI", type text},
        {"MentionsConsumption", type logical}, {"MentionsProduction", type logical}}),
    #"Added Custom" = Table.AddColumn(Types, "Focus Order", each if [Focus] = "Consumption only" then 1 else if [Focus] = "Both" then 2 else if [Focus] = "Production only" then 3 else 4),
    #"Changed Type" = Table.TransformColumnTypes(#"Added Custom",{{"Focus Order", Int64.Type}})
in
    #"Changed Type"
