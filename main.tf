variable "azure_client_id" {
description = "Client ID for the Service Principal."
}
variable "azure_client_secret" {
description = "Client Secret for the Service Principal."
}
provider "azurerm" {
subscription_id = "38a48eb9-12be-4a21-91d8-d92ce3ad56a4"
client_id = "${var.azure_client_id}"
client_secret = "${var.azure_client_secret}"
tenant_id = "776ff747-970b-4a0b-96b6-9e248a307707"
}

