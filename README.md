# network-builder
module sets to buildup for network connectivity to Cisco IOS-XE device.

## :watermelon: Instruction

This will pupulate the parameter of the networking setup for your IOS-XE device with the help of devnet provider. In the **terraform.tfvars** in the root module you may want to specify below as a variable.

- `usernamme` specify username for ssh
- `metro_code` specify metro code
- `sec_metro_code` specify secondary vd's metro code
- `int` specify the interface to be terminated for mg
- `int_desc` specify the interface description
- `bw` specify the bandwidth of the interface
- `vnf_asn` specicfy the asn of your vnf


*hostname*, *id*, and *public_ip* for vnf will be shown per output upon completion of run.

It acts nothing more than above at the time writing the code today.   There will be more to come.

**terraform.tfvars** (sample)
```terraform
core_count         = 2
metro_code         = "SG"
notifications      = ["name@equinix.com"]
package_code       = "network-essentials"
sec_metro_code     = "OS"
type_code          = "C8000V"
account_number     = "svc_account"
sec_account_number = "svc_account"
ver                = "17.06.01a"
username           = "username"
key_name           = "pubkey"
acl_template_id    = "uuid"
```  


>[!note]
>Declare your credential as environment variables before you run.  
>`export EQUINIX_API_CLIENTID=someEquinixAPIClientID`  
>`export EQUINIX_API_CLIENTSECRET=someEquinixAPIClientSecret`  
