let
    Source = WorksRaw,
    Rows = Table.AddColumn(Source, "R", each [
        SourceID = try Text.AfterDelimiter([primary_location][source][id], "/", {0, RelativePosition.FromEnd}) otherwise "none",
        SourceName = try [primary_location][source][display_name] otherwise "Unknown source",
        SourceType = try [primary_location][source][type] otherwise "unknown",
        Publisher = try [primary_location][source][host_organization_name] otherwise "Unknown"
    ]),
    Expand = Table.ExpandRecordColumn(Table.SelectColumns(Rows, {"R"}), "R", {"SourceID", "SourceName", "SourceType", "Publisher"}),
    FillNulls = Table.ReplaceValue(Expand, null, "Unknown", Replacer.ReplaceValue, {"SourceName", "SourceType", "Publisher"}),
    Distinct = Table.Distinct(FillNulls, {"SourceID"}),
    Types = Table.TransformColumnTypes(Distinct, {{"SourceID", type text}, {"SourceName", type text}, {"SourceType", type text}, {"Publisher", type text}})
in
    Types
