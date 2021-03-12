# PowerQuery M or DAX artefacts
General resources:
* [PowerQuery M Reference](https://docs.microsoft.com/en-us/powerquery-m/)
* [Data Analysis Expressions (DAX) Reference](https://docs.microsoft.com/en-us/dax/)

<!-- Note: Edit tables with https://www.tablesgenerator.com/markdown_tables -->

## Contents

| Reference | Problem / Solution | Related | Link |
|---|---|---|---|
| Table | Use a central date-table to properly correlate data and allow time-based drill-down functionality and filtering | - | [Table-GenerateDateTable](./Table-GenerateDateTable.txt) |
| Function | Get Auth Token from a AAD App Registration (Service Principal) to call AAD-authenticated REST API's. This is for example used to load data from Log Analytics Workspace | - | [Function-GetLogAnalyticsApiToken](./Function-GetLogAnalyticsApiToken.txt) |
| Column | Extend a table with Lookup data from same or different table | - | [Column-LookupInTable](./Column-LookupInTable.txt) |
| Column | Create a column with calulated values from other cells of same row | - | [Column-DiffToOtherRowsValues](./Column-DiffToOtherRowsValues.txt) |
| Query | For queries such as for LogAnalytics data, the structure of the returned data may vary. Generally this leads to problems on subsequent transformations which reference columns that may not always exist. This snippet shows the introduction of an "select" operation as the first transformation-step, which guarantees that the required set of columns always exists. Tip: Generally use rather [`Table.SelectColumns`](https://docs.microsoft.com/en-us/powerquery-m/table-selectcolumns) than [`Table.RemoveColumns`](https://docs.microsoft.com/en-us/powerquery-m/table-removecolumns). | - | [Query-HandleDynamicSetOfColumns](./Query-HandleDynamicSetOfColumns.txt) |
| Query | Complex text transformation of a column, including Camel / Pascal case to space conversion, replacements and capitalization of words | - | [Query-ComplexTextTransformations](./Query-ComplexTextTransformations) |
| DAX | Add a calculated column in a data table which returns the last 5 calender weeks or a default bin (named e.g. 'older') which allows a well-arranged visualisation in e.g. Matrix chart | - | [DAX-GetBinsOfRecentWeeks](./DAX-GetBinsOfRecentWeeks.txt) |
