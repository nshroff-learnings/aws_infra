# Networking

This root module creates the foundational network layer:

- VPC, private subnets, optional public subnets, route tables, and optional Internet Gateway through the shared `vpc` module.
- Network ACLs and NACL rules directly in this root module.

Run Terraform from this directory with:

```powershell
terraform -chdir=infra/networking init `
  -backend-config="bucket=<state-bucket>" `
  -backend-config="region=<state-region>"

terraform -chdir=infra/networking workspace select dev

terraform -chdir=infra/networking plan `
  -var-file=../../variables/dev/common.tfvars `
  -var-file=../../variables/dev/networking.tfvars
```

## Important Properties

| Property | Purpose |
| --- | --- |
| `vpc_cidr` | CIDR range for the VPC. Choose a range that does not overlap with other VPCs, on-prem networks, or peered networks. |
| `private_subnet_cidrs` | CIDRs for private subnets. EKS nodes should normally run here. |
| `public_subnet_cidrs` | CIDRs for public subnets. Use only when public load balancers or ingress components need public subnet placement. |
| `availability_zones` | AZs used for subnet placement. Provide at least as many AZs as the largest subnet CIDR list. |
| `map_public_ip_on_launch` | Whether resources launched in public subnets receive public IPs. Defaults should stay false unless explicitly needed. |
| `network_acls` | Map of NACLs, subnet associations, ingress rules, and egress rules. |

## Subnet Keys

The shared VPC module keys subnet outputs like this:

```text
private-01
private-02
public-01
public-02
```

Use those keys in `network_acls[*].subnet_keys`.

## Sample Values

```hcl
vpc_cidr = "10.10.0.0/16"

availability_zones = ["us-east-1a", "us-east-1b"]

private_subnet_cidrs = [
  "10.10.1.0/24",
  "10.10.2.0/24"
]

public_subnet_cidrs = [
  "10.10.101.0/24",
  "10.10.102.0/24"
]

map_public_ip_on_launch = false

network_acls = {
  private = {
    subnet_keys = ["private-01", "private-02"]

    ingress_rules = [
      {
        rule_no    = 100
        action     = "allow"
        protocol   = "-1"
        cidr_block = "10.10.0.0/16"
        from_port  = 0
        to_port    = 0
      }
    ]

    egress_rules = [
      {
        rule_no    = 100
        action     = "allow"
        protocol   = "-1"
        cidr_block = "0.0.0.0/0"
        from_port  = 0
        to_port    = 0
      }
    ]
  }
}
```

## Outputs Used By Other Layers

- `vpc_id`
- `private_subnet_ids`
- `public_subnet_ids`
- `private_route_table_id`
- `public_route_table_id`
- `network_acl_ids`

`infra/compute` needs private subnet IDs before EKS can be planned.
