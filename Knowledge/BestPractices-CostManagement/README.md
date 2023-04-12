# Summary

This page describes the methods available to better control Azure costs and avoid unpleasant surprises related to resource consumption that has increased beyond expectations. It rely on the [Monitoring Best-Practices](/Knowledge/BestPractices-AzureSolutions-Monitoring/README.md) when it is about alerting.

# Overview

While some Azure resources or levels of Azure resources are free, most are not. They are billed on a monthly basis after they are consumed. Azure resources are billed either on a capacity basis, regardless of usage (per-capacity model), or on a usage basis, where capacity is scaled accordingly (per-usage model). Both models are billed after they have been consumed, at the end of a calendar month.

It is worth mentioning that most free Azure resources may not have the same resiliency mechanism and may tragically reduce your solution level (SLA).

# Cost Control Mechanisms

Azure supplies a variety of utilities and tools to enhance the planning, monitoring and understanding of resources costs.

## Azure Price Calculator

## Budgets and alerts

## Cost Analysis

# Recommendations

- When designing a solution, the cost dimension should always be considered when choosing services and technologies.
- In most cases, IaaS services are more expensive than PaaS services. Therefore, not only for cost reasons, PaaS services should be preferred over IaaS services.
- Once a solution has been designed, before its first deployment, estimate the costs using the price calculator.
- Each subscription should have a defined budget (e.g. based on above pricing calculator estimation) and at least one alert, triggered when the 80% of the budget has been reached.
- After every billing-period, review the subscriptions resources and costs to:
  - Check for cost anomalies that do not follow a trend;
  - Ensure proper scaling of Azure resources to avoid paying for unused capacity;
  - Adjust the associated budget and its alerts based on the past month and any adjustment made.

## 
