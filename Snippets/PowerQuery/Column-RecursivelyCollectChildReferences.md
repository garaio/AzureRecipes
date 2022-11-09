Given a table with the parent column "PartsListId" and its articles (an item in the parts list is an article with the reference column "ArticleId"). You want to know the entire tree in which a particular article is used. To do this, you need to recursively analyze the entire table.

Create a custom function (recommendation: in a separate query):

```ts
let
    GetReferencedArticles = (t as table, articles as list) as list =>

    let
        article_rows = List.Transform(articles, each (
            let
                self = { _ },
                children = (let a = _ in Table.SelectRows(t, each [PartsListId] = a))[ArticleId],
                result = if List.Count(children) = 0 then self else List.Combine({self, GetReferencedArticles(t, children)})
            in result
        )),
        combined = List.Distinct(List.Combine(article_rows))
    in combined
in
    GetReferencedArticles
```

In the table query you can then integrate this function by adding a new colum:

```ts
let
    Source = Datenbank,
    #"Added Lookup" = Table.AddColumn(Source, "ArticleAlsoUsedInPartsList", each GetReferencedArticles(Source, { [ArticleId] })),
    #"Added References" = Table.AddColumn(#"Added Lookup", "References", each Text.Combine(List.Transform([ArticleAlsoUsedInPartsList], each Text.From(_)), ", "))
in
    #"Added References"
```
