let
    Source = fnOpenAlex("institutions", "country_code:ES", "id,display_name,type,geo"),
    ToTable = Table.FromRecords(Source, {"id", "display_name", "type", "geo"}, MissingField.UseNull),
    Fields = Table.AddColumn(ToTable, "R", each [
        InstitutionID = Text.AfterDelimiter([id], "/", {0, RelativePosition.FromEnd}),
        Institution = [display_name],
        InstitutionType = Text.Proper(Text.Replace([type] ?? "other", "_", " ")),
        City = try [geo][city] otherwise null,
        Region = try [geo][region] otherwise null,
        Latitude = try [geo][latitude] otherwise null,
        Longitude = try [geo][longitude] otherwise null
    ]),
    Expand = Table.ExpandRecordColumn(Table.SelectColumns(Fields, {"R"}), "R",
        {"InstitutionID", "Institution", "InstitutionType", "City", "Region", "Latitude", "Longitude"}),
    UsedIds = Table.Distinct(Table.SelectColumns(BridgePaperInstitution, {"InstitutionID"})),
    Merge = Table.NestedJoin(Expand, {"InstitutionID"}, UsedIds, {"InstitutionID"}, "Used", JoinKind.Inner),
    Keep = Table.RemoveColumns(Merge, {"Used"}),
    Types = Table.TransformColumnTypes(Keep, {
        {"InstitutionID", type text}, {"Institution", type text}, {"InstitutionType", type text},
        {"City", type text}, {"Region", type text}, {"Latitude", type number}, {"Longitude", type number}})
in
    Types
