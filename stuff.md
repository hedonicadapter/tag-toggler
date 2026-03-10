## Start-and-stoppable resources on Azure at the time of writing

vm
Start-AzVM / Stop-AzVM

aks
Stop-AzAksCluster / Start-AzAksCluster

devtest labs
Invoke-AzResourceAction

Resource Category,Required Az Module,Primary Stop Cmdlet,Primary Start Cmdlet
Compute,Az.Compute,Stop-AzVM,Start-AzVM
Scale Sets,Az.Compute,Stop-AzVmss,Start-AzVmss
Kubernetes,Az.Aks,Stop-AzAksCluster,Start-AzAksCluster
SQL MI,Az.Sql,Stop-AzSqlInstance,Start-AzSqlInstance
Synapse (Standalone),Az.Sql,Suspend-AzSqlDatabase,Resume-AzSqlDatabase
Synapse (Workspace),Az.Synapse,Suspend-AzSynapseSqlPool,Resume-AzSynapseSqlPool
Analysis Services,Az.AnalysisServices,Suspend-AzAnalysisServicesServer,Resume-AzAnalysisServicesServer
ACI,Az.ContainerInstance,Stop-AzContainerGroup,Start-AzContainerGroup
Container Apps,Az.App,Stop-AzContainerApp,Start-AzContainerApp
Data Factory,Az.DataFactory,Stop-AzDataFactoryV2IntegrationRuntime,Start-AzDataFactoryV2IntegrationRuntime
App Gateway v2,Az.Network,Stop-AzApplicationGateway,Start-AzApplicationGateway
Data Explorer,Az.Kusto,Stop-AzKustoCluster,Start-AzKustoCluster
Stream Analytics,Az.StreamAnalytics,Stop-AzStreamAnalyticsJob,Start-AzStreamAnalyticsJob
