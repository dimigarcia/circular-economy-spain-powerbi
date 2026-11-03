let
    Filter = "authorships.institutions.country_code:ES,publication_year:2015-2024,title_and_abstract.search:"
        & TopicSearch
        & " AND " & ConsumptionTerms,
    Source = fnOpenAlex("works", Filter, "id"),
    ToTable = Table.FromRecords(Source, {"id"}, MissingField.UseNull),
    CleanId = Table.TransformColumns(ToTable, {{"id", each Text.AfterDelimiter(_, "/", {0, RelativePosition.FromEnd}), type text}}),
    Flag = Table.AddColumn(Table.Distinct(CleanId), "MentionsConsumption", each true, type logical)
in
    Flag
