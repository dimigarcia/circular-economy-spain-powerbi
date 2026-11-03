(entity as text, filter as text, select as text) as list =>
let
    BaseQuery = [filter = filter, select = select, per_page = "200"],
    Query = BaseQuery,
    GetPage = (cursor as text) as record =>
        Json.Document(
            Web.Contents("https://api.openalex.org", [RelativePath = entity, Query = Query & [cursor = cursor], ApiKeyName = "api_key"])
        ),
    Pages = List.Generate(
        () => GetPage("*"),
        each List.Count([results]) > 0,
        each if [meta][next_cursor] = null then [results = {}, meta = []] else GetPage([meta][next_cursor])
    ),
    Results = List.Combine(List.Transform(Pages, each [results]))
in
    Results
