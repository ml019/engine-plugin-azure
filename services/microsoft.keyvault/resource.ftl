[#ftl]

[@addResourceProfile
  service=AZURE_KEYVAULT_SERVICE
  resource=AZURE_KEYVAULT_RESOURCE_TYPE
  profile=
    {
      "apiVersion" : "2018-02-14",
      "type" : "Microsoft.KeyVault/vaults",
      "conditions" : [ "globally_unique" ],
      "outputMappings":   {
        REFERENCE_ATTRIBUTE_TYPE : {
          "Property" : "id"
        },
        NAME_ATTRIBUTE_TYPE : {
          "Property" : "name"
        }
      }
    }
/]

[@addResourceProfile
  service=AZURE_KEYVAULT_SERVICE
  resource=AZURE_KEYVAULT_SECRET_RESOURCE_TYPE
  profile=
    {
      "apiVersion" : "2018-02-14",
      "type" : "Microsoft.KeyVault/vaults/secrets",
      "outputMappings" : {
        REFERENCE_ATTRIBUTE_TYPE : {
          "Property" : "id"
        },
        NAME_ATTRIBUTE_TYPE : {
          "Property" : "name"
        }
      }
    }
/]

[@addResourceProfile
    service=AZURE_KEYVAULT_SERVICE
    resource=AZURE_KEYVAULT_ACCESS_POLICY_RESOURCE_TYPE
    profile=
      {
        "apiVersion" : "2018-02-14",
        "type" : "Microsoft.KeyVault/vaults/accessPolicies",
        "outputMappings" : {
          REFERENCE_ATTRIBUTE_TYPE : {
            "Property" : "id"
          }
        }
      }
/]

[#function getKeyVaultSku family name]
  [#-- SKU for a KeyVault resides within the Properties object,
  not at the top level object depth as exists in the ARM schema. --]
  [#return
    {
      "family" : family,
      "name" : name
    }
  ]
[/#function]

[#-- AccessPolicy can be defined as either a property on the KeyVault resource,
or as a sub-resource. Both utilise this function, however this naming
convention ("object" suffix) is used to easily distinguish the two. --]
[#function getKeyVaultAccessPolicyObject
  tenantId
  objectId
  permissions
  applicationId=""]

  [#return
    {
      "tenantId" : tenantId,
      "objectId" : objectId,
      "permissions" : permissions
    } + 
    attributeIfContent("applicationId", applicationId)
  ]

[/#function]

[#function getKeyVaultAccessPolicyPermissions
  keys=[]
  secrets=[]
  certificates=[]
  storage=[]]
  [#return
    {} +
    attributeIfContent("keys", keys) +
    attributeIfContent("secrets", secrets) +
    attributeIfContent("certificates", certificates) +
    attributeIfContent("storage", storage)
  ]
[/#function]

[#function getKeyVaultProperties
  tenantId
  sku
  accessPolicies=[]
  uri=""
  enabledForDeployment=false
  enabledForDiskEncryption=false
  enabledForTemplateDeployment=false
  enableSoftDelete=false
  createMode=false
  enablePurgeProtection=false
  networkAcls={}]

  [#return
    {
      "tenantId" : tenantId,
      "sku" : sku,
      "accessPolicies" : accessPolicies
    } +
    attributeIfContent("vaultUri", uri) +
    attributeIfTrue("enabledForDeployment", enabledForDeployment, enabledForDeployment) +
    attributeIfTrue("enabledForDiskEncryption", enabledForDiskEncryption, enabledForDiskEncryption) +
    attributeIfTrue("enabledForTemplateDeployment", enabledForTemplateDeployment, enabledForTemplateDeployment) +
    attributeIfTrue("enableSoftDelete", enableSoftDelete, enableSoftDelete) +
    attributeIfContent("createMode", createMode) +
    attributeIfTrue("enablePurgeProtection", enablePurgeProtection, enablePurgeProtection) +
    attributeIfContent("networkAcls", networkAcls)
  ]

[/#function]

[#function getKeyVaultSecretAttributes
  notBeforeDate
  expiryDate
  enabled=false]

  [#return
    {} +
    attributeIfTrue("enabled", enabled, enabled) +
    attributeIfContent("nbf", notBeforeDate) +
    attributeIfContent("exp", expiryDate)
  ]
[/#function]

[#function getKeyVaultSecretProperties
  value=""
  contentType=""
  attributes={}]

  [#return
    {} +
    attributeIfContent("value", value) +
    attributeIfContent("contentType", contentType) +
    attributeIfContent("attributes", attributes)
  ]

[/#function]

[#macro createKeyVault
  id
  name
  location
  properties
  tags={}
  resources=[]
  dependsOn=[]]

  [@armResource
    id=id
    name=name
    profile=AZURE_KEYVAULT_RESOURCE_TYPE
    location=location
    properties=properties
    tags=tags
    resources=resources
    dependsOn=dependsOn
  /]

[/#macro]

[#-- To ensure Vaults can be created with no accessPolicies, can have accessPolicies added
at a later time, and remain idempotent, naming an AccessPolicy "add" will merge in the policy
reference: https://tinyurl.com/y42ot42k --]
[#macro createKeyVaultAccessPolicy id name vaultName properties dependsOn=[]]

  [@armResource
    id=id
    name=name
    parentNames=[vaultName]
    profile=AZURE_KEYVAULT_ACCESS_POLICY_RESOURCE_TYPE
    properties=properties
    dependsOn=dependsOn
  /]

[/#macro]

[#macro createKeyVaultSecret
  id
  name
  tags={}
  properties={}]

  [@armResource
    id=id
    name=name
    profile=AZURE_KEYVAULT_SECRET_RESOURCE_TYPE
    tags=tags
    properties=properties
  /]
[/#macro]

[#function getKeyVaultParameter vaultId secretName]
  [#return
    {
      "reference": {
        "keyVault": {
          "id": getExistingReference(vaultId)
        },
        "secretName": secretName
      }
    }
  ]
[/#function]