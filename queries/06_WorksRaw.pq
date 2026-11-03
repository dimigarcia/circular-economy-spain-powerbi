let
    Source = fnOpenAlex(
        "works",
        BaseFilter,
        "id,doi,title,publication_date,type,cited_by_count,open_access,primary_topic,primary_location,authorships,sustainable_development_goals"
    ),
    ToTable = Table.FromRecords(
        Source,
        {"id", "doi", "title", "publication_date", "type", "cited_by_count", "open_access", "primary_topic", "primary_location", "authorships", "sustainable_development_goals"},
        MissingField.UseNull
    ),
    // Shorten the OpenAlex URL ids (https://openalex.org/W123 -> W123)
    CleanId = Table.TransformColumns(ToTable, {{"id", each Text.AfterDelimiter(_, "/", {0, RelativePosition.FromEnd}), type text}}),
    RemoveDuplicates = Table.Distinct(CleanId, {"id"})
in
    RemoveDuplicates
