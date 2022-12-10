# Overview


![](./AlertingStrategy-Overview.drawio.svg)

These are some key principles:
* Oriented to consumers of alerts: How needs which information in which form?
* Notification and escalation based on RBAC and appropriate tools (such as ticketing system and backlog management system) instead of using specific user accounts (based on email address or phone number): The alert notifications shall be independend from persons and allow simplified management
* Standardisation: 

# Knowledge

How alerts are defined and processed in general (source MSDN, see link in resources below):
![](./https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/media/alerts-overview/alerts.png)

## Alert Rule Types

![](./AlertingStrategy-AlertRuleTypes.drawio.svg)

## Activity Log Alerts

## Service Health Alerts

## Resource Health Alerts

## Smart Detection Alerts

## Availability Test Alerts
These are basically just regular metric alerts, but created with and referencing a specific Availability Test, which is a great built-in feature of Application Insights.

## Custom Alerts (log- or metric-based)

## Security Alerts (or Alerts generated from Recommendations)

Security Alerts from Defender are generated only in paid plans (available for some Resource Types). If so, they are raised as specific type viewable only in Defender (i.e. not as Monitor Alerts). It is possible to [export security data consisting of recommendations and alerts continuously to a Log Analytics Workspace](https://learn.microsoft.com/en-us/azure/defender-for-cloud/continuous-export?tabs=azure-policy#exporting-to-a-log-analytics-workspace). Based on that, it is possible to raise Monitoring Alerts for new alert or recommendations entries (custom log-based alert rule). Beside the consistent view and handling achieved doing that, it may be especially helpful to ensure the responsible developer / application provider gets notified.

To be considered: This solution can only be set up on the level of the subscription, only once and not via ARM/Bicep as of current knowledge. When having multiple application components or even multiple environment deployments in the same subscription, this would require a clean structuring and deployment concept (which is not further evaluated in this template).

When setting up the continous export in the Azure Portal, Alert Rules for both alerts and recommendations can be generated directly:

![](./Defender-CreateAzureMonitorLogAlerts.png)

# Application Guidelines
The following checklist (or task list) can be used to define guidelines for review and handover of applications.

1. Roles assigned on the subscription
1. Standard alert rules deployed
1. Availability tests defined (appropriate to measure SLA definitions)
1. Custom Alerts and steps to remedy documented in operations manual (or in another part of the application documentation)

## Deployment Concept (Recommendation)

![](./AlertingStrategy-Deployment.drawio.svg)

# Resources
* [MSDN Overview of Azure Alerts](https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/alerts-overview)
* [MSDN Built-in Roles with its GUIDs usable to link Action Groups](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles)