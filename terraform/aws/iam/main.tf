variable "prefix" {}

# Define IAM role to create external volumes on AWS
resource "aws_iam_instance_profile" "agent_profile" {
  name = "${var.prefix}-agent_profile"
  roles = ["${aws_iam_role.agent_role.name}"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy" "agent_policy" {
    name = "${var.prefix}-agent_policy"
    role = "${aws_iam_role.agent_role.id}"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "ec2:CreateTags",
                "ec2:DescribeInstances",
                "ec2:CreateVolume",
                "ec2:DeleteVolume",
                "ec2:AttachVolume",
                "ec2:DetachVolume",
                "ec2:DescribeVolumes",
                "ec2:DescribeVolumeStatus",
                "ec2:DescribeVolumeAttribute",
                "ec2:CreateSnapshot",
                "ec2:CopySnapshot",
                "ec2:DeleteSnapshot",
                "ec2:DescribeSnapshots",
                "ec2:DescribeSnapshotAttribute"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}
EOF
}

resource "aws_iam_role" "agent_role" {
    name = "${var.prefix}-agent_role"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

output "agent_profile" {
  value = "${aws_iam_instance_profile.agent_profile.name}"
}
