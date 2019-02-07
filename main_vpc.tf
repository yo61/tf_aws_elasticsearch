/*Add a new set of data.aws_iam_policy_document, aws_elasticsearch_domain, aws_elasticsearch_domain_policy. Because currently terraform/aws_elasticsearch_domain 
does not handle properly null/empty "vpc_options" */

/*Need to use interpolation for output variables until issue #15605 is solved */

locals {
  es_arn       = "${length(var.vpc_options["subnet_ids"]) > 0 ? element(concat(aws_elasticsearch_domain.es_vpc.*.arn,list("")),0) : element(concat(aws_elasticsearch_domain.es.*.arn,list("")),0)}"
  es_endpoint  = "${length(var.vpc_options["subnet_ids"]) > 0 ? element(concat(aws_elasticsearch_domain.es_vpc.*.endpoint,list("")),0) : element(concat(aws_elasticsearch_domain.es.*.endpoint,list("")),0)}"
  es_domain_id = "${length(var.vpc_options["subnet_ids"]) > 0 ? element(concat(aws_elasticsearch_domain.es_vpc.*.domain_id,list("")),0) : element(concat(aws_elasticsearch_domain.es.*.domain_id,list("")),0)}"
}

data "aws_iam_policy_document" "es_vpc_management_access" {
  count = "${length(var.vpc_options["subnet_ids"]) > 0 ? 1 : 0}"

  statement {
    actions = [
      "es:*",
    ]

    resources = [
      "${aws_elasticsearch_domain.es_vpc.arn}",
      "${aws_elasticsearch_domain.es_vpc.arn}/*",
    ]

    principals {
      type = "AWS"

      identifiers = ["${distinct(compact(var.management_iam_roles))}"]
    }
  }
}

resource "aws_elasticsearch_domain" "es_vpc" {
  count                 = "${length(var.vpc_options["subnet_ids"]) > 0 ? 1 : 0}"
  domain_name           = "${local.domain_name}"
  elasticsearch_version = "${var.es_version}"

  encrypt_at_rest = {
    enabled    = "${var.encrypt_at_rest}"
    kms_key_id = "${var.kms_key_id}"
  }

  cluster_config {
    instance_type            = "${var.instance_type}"
    instance_count           = "${var.instance_count}"
    dedicated_master_enabled = "${var.instance_count >= var.dedicated_master_threshold ? true : false}"
    dedicated_master_count   = "${var.instance_count >= var.dedicated_master_threshold ? 3 : 0}"
    dedicated_master_type    = "${var.instance_count >= var.dedicated_master_threshold ? (var.dedicated_master_type != "false" ? var.dedicated_master_type : var.instance_type) : ""}"
    zone_awareness_enabled   = "${var.es_zone_awareness}"
  }

  log_publishing_options = ["${var.log_publishing_options}"]

  vpc_options = ["${var.vpc_options}"]

  ebs_options {
    ebs_enabled = "${var.ebs_volume_size > 0 ? true : false}"
    volume_size = "${var.ebs_volume_size}"
    volume_type = "${var.ebs_volume_type}"
  }

  snapshot_options {
    automated_snapshot_start_hour = "${var.snapshot_start_hour}"
  }

  tags = "${merge(var.tags, map(
    "Domain", "${var.domain_name}"
  ))}"
}

resource "aws_elasticsearch_domain_policy" "es_vpc_management_access" {
  count           = "${length(var.vpc_options["subnet_ids"]) > 0 ? 1 : 0}"
  domain_name     = "${local.domain_name}"
  access_policies = "${data.aws_iam_policy_document.es_vpc_management_access.json}"
}
