# network-builder
module sets to buildup for network connectivity to Cisco IOS-XE device.

## :watermelon: Instruction

This will pupulate the parameter of the networking setup for your IOS-XE device with the help of devnet provider. In the **terraform.tfvars** in the root module you may want to specify below as a variable.

- `usernamme` specify username for ssh
- `metro_code` specify metro code
- `sec_metro_code` specify secondary vd's metro code
- `int` specify the interface to be terminated for mg
- `int_desc_pri` specify the interface description for primary
- `int_desc_sec` specify the interface description for secondary
- `bw` specify the bandwidth of the interface
- `vnf_asn` specicfy the asn of your vnf
- `neighbor_desc_pri` specify the description of bgp peer
- `neighbor_desc_sec` specify the description of bgp peer
- `pri_vc` specify the VC name
- `sec_vc` specify the VC name
- `emails` email


*hostname*, *id*, and *public_ip* for vnf will be shown per output upon completion of run.

It acts nothing more than above at the time writing the code today.   There will be more to come.

**terraform.tfvars** (sample)
```terraform
vnf_asn           = "65***"
int               = "7"
int_desc_pri      = "to-mg-pri"
int_desc_sec      = "to-mg-sec"
bw                = 500000
username          = "username"
metro_code        = "SG"
sec_metro_code    = "SG"
neighbor_desc_pri = "to-metal_gateway-pri"
neighbor_desc_sec = "to-metal_gatway-sec"
pri_vc            = "pri"
sec_vc            = "sec"
emails            = ["sample@equinix.com"]
```  


>[!note]
>Declare your credential as environment variables before you run.  
>`export EQUINIX_API_CLIENTID=someEquinixAPIClientID`  
>`export EQUINIX_API_CLIENTSECRET=someEquinixAPIClientSecret`  
