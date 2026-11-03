let
    Source = WorksRaw,
    Rows = Table.AddColumn(Source, "R", each [
        TopicID = try Text.AfterDelimiter([primary_topic][id], "/", {0, RelativePosition.FromEnd}) otherwise "none",
        Topic = try [primary_topic][display_name] otherwise "Unclassified",
        Subfield = try [primary_topic][subfield][display_name] otherwise "Unclassified",
        Field = try [primary_topic][field][display_name] otherwise "Unclassified",
        Domain = try [primary_topic][domain][display_name] otherwise "Unclassified"
    ]),
    Expand = Table.ExpandRecordColumn(Table.SelectColumns(Rows, {"R"}), "R", {"TopicID", "Topic", "Subfield", "Field", "Domain"}),
    Distinct = Table.Distinct(Expand, {"TopicID"}),
    Types = Table.TransformColumnTypes(Distinct, {{"TopicID", type text}, {"Topic", type text}, {"Subfield", type text}, {"Field", type text}, {"Domain", type text}})
in
    Types
