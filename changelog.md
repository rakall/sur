# Change Log

Updated change log
## [v.1.0.09] - 2021-03-31
## Changed
- A variable "zones" is added to define in which available AZs virtual machines in this scale set should be created in and delete some warnings.
- Backend Load Balancer Session persistence is based on Client IP and protocol 
- Changelog included
- Custom data is updated using python3


## [v1.0.08] - 2020-08-25
## Changed
- enable_ip_forwarding = false
- domain_name_label = local.nva_name

## [v1.0.07] - 2020-07-29
## Changed
- enable_ip_forwarding = false
- domain_name_label = "${local.nva_name}name"

## [v1.0.06] - 2020-06-15
## Changed
- enable_ip_forwarding = true
- domain_name_label = local.nva_name

## [v1.0.05] - 2020-30-03
## Changed
- Retrocompatibility with old domain name labels
