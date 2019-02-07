tf_aws_elasticsearch
===========

Terraform module for deploying and managing [Amazon Elasticsearch Service](https://aws.amazon.com/documentation/elasticsearch-service/).

This module has two options for creating an Elasticsearch domain:
  1) Create an Elasticsearch domain with a public endpoint. Access policy is then based on the intersection of the following two criteria
     * source IP address
     * client IAM role

     See [this Stack Overflow post](http://stackoverflow.com/questions/32978026/proper-access-policy-for-amazon-elastic-search-cluster) for further discussion of access policies for Elasticsearch.
  2) Create an Elasticsearch domain and join it to a VPC. Access policy is then based on he intersection of the following two criteria:
     * security groups applied to Elasticsearch domain
     * client IAM role

If `vpc_options` option is set, Elasticsearch domain is created within a VPC. If not, Elasticsearch domain is created with a public endpoint

NOTE: **You can either launch your domain within a VPC or use a public endpoint, but you can't do both.** Considering this, adding or removing `vpc_options` will force **DESTRUCTION** of the old Elasticsearch domain and **CREATION** of a new one. More INFO - [VPC support](http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-vpc.html)

Several options affect the resilience and scalability of your Elasticsearch domain.  For a production deployment:

- set `instance_count` to an even number (default: `6`) greater than or equal to the `dedicated_master_threshold` (default: `10`)
- choose an `instance_type` that is not in the T2 family
- set `es_zone_awareness` to `true`.

This will result in a cluster with three dedicated master nodes, balanced across two availability zones.


For a production deployment it may also make sense to use EBS volumes rather that instance storage; to do so, set `ebs_volume_size` greater than 0 and optionally specify a value for `ebs_volume_type` (right now the only supported values are `gp2` and `magnetic`).

----------------------
#### Required
None (but `domain_name` and `management_public_ip_addresses` are strongly recommended).

#### Optional
- `domain_name` - unique identifier for the domain.
- `domain_prefix` - A string to be prefixed to the domain, if `use_prefix` is true. Default is `tf-`. _e.g._ `domain_name = foo` will result in a domain called `tf-foo`.
- `use_prefix` - A boolean flag indicating whether or not to use the domain_prefix. Default is `true`.
- `es_version` - Elasticsearch version.
- `instance_type` - Elasticsearch instance type to use for data nodes (and dedicated master nodes unless otherwise specified).
- `instance_count` - Number of instances in the cluster.
- `dedicated_master_threshold` - Number of instances above which dedicated master nodes will be used. Default is `10`
- `dedicated_master_type` - Elasticsearch instance type to use for dedicated master nodes.
- `management_iam_roles` - List of ARNs of IAM roles to be granted full access to the domain.
- `management_public_ip_addresses` - List of IP addresses or CIDR blocks from which to permit full access to the domain.(Used only in Elasticsearch domains with public endpoints)
- `es_zone_awareness` - Enable or disable zone awareness (balancing instances across multiple availability zones).  Note that setting this parameter to `true` and then requesting an odd number of nodes will result in an invalid cluster configuration.
- `ebs_volume_size` - Size in GB of EBS volume to attach to each node and use for data storage.  If this parameter is set to 0 (the default), nodes will use instance storage.
- `ebs_volume_type` - Storage class for EBS volumes.  Just use `gp2`.
- `snapshot_start_hour` - Hour of the day (in UTC) at which to begin daily snapshots.
- `tags` - Additional tags to apply to created resources
- `vpc_options` - VPC related options. Adding or removing this configuration forces a new resource
    - `security_group_ids` - List of VPC Security Group IDs to be applied to the Elasticsearch domain endpoints.
    - `subnet_ids` - List of VPC Subnet IDs for the Elasticsearch domain endpoints to be created in.
- `log_publishing_options` - Options for publishing slow logs to CloudWatch Logs.
    - `log_type` - (Required) A type of Elasticsearch log. Valid values: INDEX_SLOW_LOGS, SEARCH_SLOW_LOGS, ES_APPLICATION_LOGS
    - `cloudwatch_log_group_arn` - (Required) ARN of the Cloudwatch log group to which log needs to be published.
    - `enabled` - (Optional, Default: true) Specifies whether given log publishing option is enabled or not.

Usage
-----
Create Elasticsearch domain with public endpoint

```hcl

module "es" {
  source                         = "github.com/terraform-community-modules/tf_aws_elasticsearch?ref=0.0.1"
  domain_name                    = "my-elasticsearch-domain"
  management_public_ip_addresses = ["34.203.XXX.YYY"]
  instance_count                 = 16
  instance_type                  = "m4.2xlarge.elasticsearch"
  dedicated_master_type          = "m4.large.elasticsearch"
  es_zone_awareness              = true
  ebs_volume_size                = 100
  ...
}

```
Create Elasticsearch domain within a VPC

```hcl

module "es" {
  source                         = "github.com/terraform-community-modules/tf_aws_elasticsearch?ref=0.0.1"
  domain_name                    = "my-elasticsearch-domain"
  vpc_options                    = {
    security_group_ids = ["sg-XXXXXXXX"]
    subnet_ids         = ["subnet-YYYYYYYY"]
  }
  instance_count                 = 1
  instance_type                  = "t2.medium.elasticsearch"
  dedicated_master_type          = "t2.medium.elasticsearch"
  es_zone_awareness              = false
  ebs_volume_size                = 35
  ...
}


```

Create small (4-node) Elasticsearch domain in a VPC with dedicated master nodes

```hcl

module "es" {
  source                         = "github.com/terraform-community-modules/tf_aws_elasticsearch?ref=0.6.0"
  domain_name                    = "my-elasticsearch-domain"
  vpc_options                    = {
    security_group_ids = ["sg-XXXXXXXX"]
    subnet_ids         = ["subnet-YYYYYYYY"]
  }
  instance_count                 = 4
  instance_type                  = "m4.2xlarge.elasticsearch"
  dedicated_master_threshold     = 4
  dedicated_master_type          = "m4.large.elasticsearch"
  es_zone_awareness              = true
  ebs_volume_size                = 100
  ...
}


```

Outputs
=======
- `arn` - ARN of the created Elasticsearch domain.
- `domain_id` - Unique identifier for the domain.
- `endpoint` - Domain-specific endpoint used to submit index, search, and data upload requests.  Kibana is available at `https://${endpoint}/_plugin/kibana/`.

Authors
=======

[Steve Huff](https://github.com/hakamadare)
[Alexander Gramovich](https://github.com/ggramal)

Changelog
=========
0.1.0 - Add VPC support

0.0.2 - Bugfix (#1) which prevented module from executing correctly with variable defaults.

0.0.1 - Initial release.

License
=======

This software is released under the MIT License (see `LICENSE.md`).
