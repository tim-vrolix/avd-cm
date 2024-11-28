# Bicep-Component-Avd
# Avd Component Solution

## INTRODUCTION

This project will set up the avd component on a subscription scope.

## OVERVIEW

The following resources can be deployed:

- Session Hosts: Virtual machines for AVD session hosts, including registration and domain join details.
- Workspace: An AVD workspace with a display name, description, and resource group association.
- Resource Groups: Multiple resource groups for organizing related AVD resources.
- File Share: A storage account and file share setup for AVD profiles, with networking and private endpoint configurations.
- Host Pools: Configurations for AVD host pools, including load balancing, application groups, and session host settings.
- Scaling Plans: Automated scaling plans for the host pools based on predefined schedules and usage patterns.

## Modules being used
### compute
| Name | Version |
| ---- | ------- |
| availability-set | 1.0.0 |
| domain-join | 1.0.0 |
| microsoft-monitoring-agent | 1.1.0 |
| virtual-machine | 1.1.1 |
### desktop-virtualization
| Name | Version |
| ---- | ------- |
| application | 1.0.0 |
| application-group | 1.0.0 |
| application-group-role-assignment | 1.0.1 |
| avd-dsc-extension | 1.0.1 |
| host-pool | 1.0.0 |
| scaling-plan | 1.1.1 |
| scaling-plan-role-assignment | 1.0.0 |
| scaling-plan-role-definition | 1.0.0 |
| workspace | 1.1.0 |
### insights
| Name | Version |
| ---- | ------- |
| avd-workspace-diagnostic-settings | 1.1.0 |
| host-pool-diagnostic-settings | 1.1.0 |
### network
| Name | Version |
| ---- | ------- |
| network-interface | 1.1.0 |
| private-dns-zone-group | 1.0.0 |
| private-endpoint | 1.1.0 |
### storage
| Name | Version |
| ---- | ------- |
| storage-account | 1.0.0 |
| storage-account-file-share | 1.0.1 |

