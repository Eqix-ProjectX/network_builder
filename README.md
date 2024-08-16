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
vnf_asn        = "65120"
int            = "7"
int_desc       = "to-mg"
bw             = 500000
username       = "username"
metro_code     = "SG"
sec_metro_code = "OS"
neighbor_desc  = "to-metal_gateway"
```  


>[!note]
>Declare your credential as environment variables before you run.  
>`export EQUINIX_API_CLIENTID=someEquinixAPIClientID`  
>`export EQUINIX_API_CLIENTSECRET=someEquinixAPIClientSecret`  
