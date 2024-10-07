## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| addon\_resource\_group\_name | The name of the addon vnet resource group | `string` | `""` | no |
| addon\_vent\_link | The name of the addon vnet | `bool` | `false` | no |
| addon\_virtual\_network\_id | The name of the addon vnet link vnet id | `string` | `""` | no |
| admin\_objects\_ids | IDs of the objects that can do all operations on all keys, secrets and certificates. | `list(string)` | `[]` | no |
| certificate\_contacts | Contact information to send notifications triggered by certificate lifetime events | <pre>list(object({<br>    email = string<br>    name  = optional(string)<br>    phone = optional(string)<br>  }))</pre> | `[]` | no |
| diagnostic\_setting\_enable | n/a | `bool` | `false` | no |
| diff\_sub | Flag to tell whether dns zone is in different sub or not. | `bool` | `false` | no |
| enable\_private\_endpoint | Manages a Private Endpoint to Azure database for MySQL | `bool` | `true` | no |
| enable\_rbac\_authorization | (Optional) Boolean flag to specify whether Azure Key Vault uses Role Based Access Control (RBAC) for authorization of data actions. | `bool` | `true` | no |
| enabled | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| enabled\_for\_deployment | Boolean flag to specify whether Azure Virtual Machines are permitted to retrieve certificates stored as secrets from the key vault. | `bool` | `false` | no |
| enabled\_for\_disk\_encryption | Boolean flag to specify whether Azure Disk Encryption is permitted to retrieve secrets from the vault and unwrap keys. Defaults to false | `bool` | `true` | no |
| enabled\_for\_template\_deployment | Boolean flag to specify whether Azure Resource Manager is permitted to retrieve secrets from the key vault. | `bool` | `false` | no |
| environment | Environment (e.g. `prod`, `dev`, `staging`). | `string` | `""` | no |
| eventhub\_authorization\_rule\_id | Specifies the ID of an Event Hub Namespace Authorization Rule used to send Diagnostics Data. | `string` | `null` | no |
| eventhub\_name | Specifies the name of the Event Hub where Diagnostics Data should be sent. | `string` | `null` | no |
| existing\_private\_dns\_zone | Name of the existing private DNS zone | `string` | `null` | no |
| existing\_private\_dns\_zone\_resource\_group\_name | The name of the existing resource group | `string` | `""` | no |
| extra\_tags | Variable to pass extra tags. | `map(string)` | `null` | no |
| kv\_logs | n/a | <pre>object({<br>    enabled        = bool<br>    category       = optional(list(string))<br>    category_group = optional(list(string))<br>  })</pre> | <pre>{<br>  "category_group": [<br>    "AllLogs"<br>  ],<br>  "enabled": true<br>}</pre> | no |
| label\_order | Label order, e.g. sequence of application name and environment `name`,`environment`,'attribute' [`webserver`,`qa`,`devops`,`public`,] . | `list(any)` | `[]` | no |
| location | Location where resource group will be created. | `string` | `null` | no |
| log\_analytics\_destination\_type | Possible values are AzureDiagnostics and Dedicated, default to AzureDiagnostics. When set to Dedicated, logs sent to a Log Analytics workspace will go into resource specific tables, instead of the legacy AzureDiagnostics table. | `string` | `"AzureDiagnostics"` | no |
| log\_analytics\_workspace\_id | n/a | `string` | `null` | no |
| managed\_hardware\_security\_module\_enabled | Create a KeyVault Managed HSM resource if enabled. Changing this forces a new resource to be created. | `bool` | `false` | no |
| managedby | ManagedBy, eg ''. | `string` | `""` | no |
| metric\_enabled | Is this Diagnostic Metric enabled? Defaults to true. | `bool` | `true` | no |
| multi\_sub\_vnet\_link | Flag to control creation of vnet link for dns zone in different subscription | `bool` | `false` | no |
| name | Name  (e.g. `app` or `cluster`). | `string` | `""` | no |
| network\_acls | Object with attributes: `bypass`, `default_action`, `ip_rules`, `virtual_network_subnet_ids`. Set to `null` to disable. See https://www.terraform.io/docs/providers/azurerm/r/key_vault.html#bypass for more information. | <pre>object({<br>    bypass                     = optional(string, "None"),<br>    default_action             = optional(string, "Deny"),<br>    ip_rules                   = optional(list(string)),<br>    virtual_network_subnet_ids = optional(list(string)),<br>  })</pre> | `{}` | no |
| public\_network\_access\_enabled | (Optional) Whether public network access is allowed for this Key Vault. Defaults to true | `bool` | `true` | no |
| purge\_protection\_enabled | Is Purge Protection enabled for this Key Vault? Defaults to false | `bool` | `true` | no |
| reader\_objects\_ids | IDs of the objects that can read all keys, secrets and certificates. | `list(string)` | `[]` | no |
| repository | Terraform current module repo | `string` | `""` | no |
| resource\_group\_name | A container that holds related resources for an Azure solution | `string` | `""` | no |
| sku\_name | The Name of the SKU used for this Key Vault. Possible values are standard and premium | `string` | `"standard"` | no |
| sku\_name\_hsm | The Name of the SKU used for this Key Vault hsm. | `string` | `"Standard_B1"` | no |
| soft\_delete\_retention\_days | The number of days that items should be retained for once soft-deleted. The valid value can be between 7 and 90 days | `number` | `90` | no |
| storage\_account\_id | The ID of the Storage Account where logs should be sent. | `string` | `null` | no |
| subnet\_id | The resource ID of the subnet | `string` | `""` | no |
| virtual\_network\_id | The name of the virtual network | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | n/a |
| vault\_uri | n/a |
