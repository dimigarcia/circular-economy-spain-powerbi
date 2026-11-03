let
    Source = Table.SelectColumns(WorksRaw, {"id", "authorships"}),
    ExpandAuthorships = Table.ExpandListColumn(Source, "authorships"),
    Institutions = Table.AddColumn(ExpandAuthorships, "institutions", each try [authorships][institutions] otherwise {}),
    ExpandInstitutions = Table.ExpandListColumn(Table.SelectColumns(Institutions, {"id", "institutions"}), "institutions"),
    Fields = Table.AddColumn(ExpandInstitutions, "R", each [
        InstitutionID = try Text.AfterDelimiter([institutions][id], "/", {0, RelativePosition.FromEnd}) otherwise null,
        Country = try [institutions][country_code] otherwise null
    ]),
    Expand = Table.ExpandRecordColumn(Fields, "R", {"InstitutionID", "Country"}),
    SpainOnly = Table.SelectRows(Expand, each [Country] = "ES" and [InstitutionID] <> null),
    Keep = Table.RenameColumns(Table.SelectColumns(SpainOnly, {"id", "InstitutionID"}), {{"id", "PaperID"}}),
    Distinct = Table.Distinct(Keep),
    Types = Table.TransformColumnTypes(Distinct, {{"PaperID", type text}, {"InstitutionID", type text}})
in
    Types
