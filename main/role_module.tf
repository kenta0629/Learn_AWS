module "describe_regions_for_ec2" {
    source = "./iam_role"
    name = "describe_regions_for_ec2"
    identifier = "ec2.amazonaws.com"
    policy = data.aws_iam_policy_document.assume_role.json
}