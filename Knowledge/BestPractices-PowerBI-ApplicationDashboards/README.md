# Application Dashboards with Power BI
Power BI is a simple but powerful solution to aggregate all data available and generated in the context of an application. The goal is mainly to connect following type of data to generate insights that empower the continous development of an application:
* Development activities (as the main cause of changes in usage)
* Operational data such as executions of relevant processes, relevant exceptions and alerts or costs
* Usage data which typically are relevant actions and events through the customer journey

## Contents Best Practices
_content added later_

## Implementation Best Practices
### General recommendations
* Create hierarchies on columns as much as reasonable and use [drill up/down functionality in visuals](https://docs.microsoft.com/en-us/power-bi/create-reports/desktop-inline-hierarchy-labels)
* Extract environment specific values in connections or other parts of the query to parameters. This allows the usage of the same Power BI Report for multiple environments by just changing parameter values (directly accessible in visualization)

### Aligning timestamps
* Create a general date-table which is associated with every relevant timestamp column in other tables
  * [Mark this table as date table](https://docs.microsoft.com/en-us/power-bi/transform-model/desktop-date-tables) to support the automatic functionalities of Power BI
  * Define filters based on this general table
  * Define readable formatted date values as additional columns in date table and use them for the axis values in visualizations. To ensure proper sorting, you may add the date value column to the Tooltip field which then enables sorting by this column
* You may use this snippet to define the date table: [Snippets/PowerQuery/Table-GenerateDateTable](../Snippets/PowerQuery/Table-GenerateDateTable.txt)

### Data ingestion
* Implement ingestion processes if query becomes too complex. This especially applies if you consume data from API's which include complex authentication, aggregation with multiple requests or paging.
* A simple solution may include Azure Tables and Data Factory Pipelines for integration processes. Example [Snippets/ARM/data-factory-usage-details-ingestion](../ARM/PowerQuery/data-factory-usage-details-ingestion)

### Integration
* Use service principals and API keys for connections which can be shared in Organisation scope (avoid personal logins)
* Share to appropriate workspace in Power BI online (https://powerbi.com)
* Setup automatic actualization (typically nightly)
* Integrate in Teams as tab and promote it

## Pitfalls to avoid
### Alerting
Power BI is not made for this purpose. Use Azure Alerts based on Monitor or KQL queries on Logs for detection of problematic situations and notification.

Raised alerts can be shown as events in Power BI Application Dashboard.

### Detailed Technical Analytics
Consider usage of [Azure Monitor Workbooks](https://docs.microsoft.com/en-us/azure/azure-monitor/platform/workbooks-overview). Microsoft has [replaced the so-called "Content Packs" for Power BI with this Service](https://dirteam.com/sander/2019/11/14/getting-started-with-azure-monitor-workbooks-for-azure-active-directory).

### Live Analytics
With Power BI Pro, the scheduled actualization of the datamodel can be configured to a maximum of 8 runs per day. Consider the creation of an [Azure Dashboard](https://docs.microsoft.com/en-us/azure/azure-portal/azure-portal-dashboards) consisting of Azure Monitor visualisations for this purpose.