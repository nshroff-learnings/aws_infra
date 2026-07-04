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

  public = {
    subnet_keys = ["public-01", "public-02"]
    ingress_rules = [
      {
        rule_no    = 100
        action     = "allow"
        protocol   = "tcp"
        cidr_block = "0.0.0.0/0"
        from_port  = 443
        to_port    = 443
      },
      {
        rule_no    = 110
        action     = "allow"
        protocol   = "tcp"
        cidr_block = "0.0.0.0/0"
        from_port  = 1024
        to_port    = 65535
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
