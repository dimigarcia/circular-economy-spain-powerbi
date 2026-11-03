let
    SpainAll = "authorships.institutions.country_code:ES,publication_year:2015-2024",
    CountsByField = (filter as text) as table =>
        let
            BaseQuery = [filter = filter, group_by = "primary_topic.field.id"],
            Query = BaseQuery,
            Response = Json.Document(Web.Contents("https://api.openalex.org", [RelativePath = "works", Query = Query, ApiKeyName = "api_key"])),
            ToTable = Table.FromRecords(Response[group_by], {"key_display_name", "count"}, MissingField.UseNull)
        in
            Table.RenameColumns(ToTable, {{"key_display_name", "Field"}}),
    Total = Table.RenameColumns(CountsByField(SpainAll), {{"count", "BaselinePapers"}}),
    Consumption = Table.RenameColumns(CountsByField(SpainAll & ",title_and_abstract.search:" & ConsumptionTerms), {{"count", "BaselineConsumption"}}),
    Production = Table.RenameColumns(CountsByField(SpainAll & ",title_and_abstract.search:" & ProductionTerms), {{"count", "BaselineProduction"}}),
    MergeC = Table.ExpandTableColumn(Table.NestedJoin(Total, {"Field"}, Consumption, {"Field"}, "C", JoinKind.LeftOuter), "C", {"BaselineConsumption"}),
    MergeP = Table.ExpandTableColumn(Table.NestedJoin(MergeC, {"Field"}, Production, {"Field"}, "P", JoinKind.LeftOuter), "P", {"BaselineProduction"}),
    FillZeros = Table.ReplaceValue(MergeP, null, 0, Replacer.ReplaceValue, {"BaselineConsumption", "BaselineProduction"}),
    AddConsumptionRate = Table.AddColumn(FillZeros, "BaselineConsumptionRate", each [BaselineConsumption] / [BaselinePapers], type number),
    AddProductionRate = Table.AddColumn(AddConsumptionRate, "BaselineProductionRate", each [BaselineProduction] / [BaselinePapers], type number),
    Types = Table.TransformColumnTypes(AddProductionRate, {
        {"Field", type text}, {"BaselinePapers", Int64.Type}, {"BaselineConsumption", Int64.Type}, {"BaselineProduction", Int64.Type}})
in
    Types
