# Terraform template to configure AWS for the Trustle Connector.
#
# This creates AWS policies and a user for the connector, along with access
# keys for the connector user.
#
# Copyright 2021 Trustle, Inc.
# Licensed under the Apache License, Version 2.0


#
# Variables
#

variable "region" {
  description = "AWS region"
  default     = "us-east-2"
}

variable "trustle-connector-user" {
  description = "AWS username for trustle connector"
  default     = "trustle-connector"
}

variable "trustle-connector-read-policy" {
  description = "AWS policy for trustle connector reads"
  default     = "trustle-connector-read"
}

# Remove this policy for read-only use
variable "trustle-connector-write-policy" {
  description = "AWS policy for trustle connector writes"
  default     = "trustle-connector-write"
}

variable "trustle-connector-writable-groups" {
  description = "AWS groups trustle write policy is allowed access to"
  # All AWS groups
  default     = "*"
}


#
# Outputs
#

output "region" {
  value = var.region
}

output "trustle-connector-user" {
  value     = aws_iam_user.trustle-connector.name
}

# Remove these to manually create access keys in the AWS console
output "trustle-connector-access-key" {
  value     = aws_iam_access_key.trustle-connector-access-key.id
  sensitive = true
}

output "trustle-connector-secret-key" {
  value     = aws_iam_access_key.trustle-connector-access-key.secret
  sensitive = true
}


#
# General
#

provider "aws" {
  region = var.region
}


#
# Connector policies
#

resource "aws_iam_policy" "trustle-connector-read-policy" {
  name = var.trustle-connector-read-policy

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "iam:GetRole",
          "iam:GetPolicyVersion",
          "iam:GetPolicy",
          "iam:ListGroupPolicies",
          "iam:ListUserPolicies",
          "iam:GetGroup",
          "iam:ListPolicyVersions",
          "iam:GetUserPolicy",
          "iam:ListGroupsForUser",
          "iam:ListAttachedRolePolicies",
          "iam:ListAttachedUserPolicies",
          "iam:ListAttachedGroupPolicies",
          "iam:GetGroupPolicy",
          "iam:GetUser",
          "iam:ListRolePolicies",
          "iam:GetRolePolicy"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "iam:ListPolicies",
          "iam:ListRoles",
          "iam:ListUsers",
          "iam:ListGroups",
          "iam:GetAccountAuthorizationDetails"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "iam:GenerateCredentialReport",
          "iam:GetCredentialReport",
          "iam:GenerateServiceLastAccessedDetails",
          "iam:GetServiceLastAccessedDetails",
          "iam:GetServiceLastAccessedDetailsWithEntities"
        ],
        "Resource": "*"
      }
    ]
  })
}

resource "aws_iam_policy" "trustle-connector-write-policy" {
  name = var.trustle-connector-write-policy

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "iam:AddUserToGroup",
          "iam:RemoveUserFromGroup",
          "iam:AttachUserPolicy",
          "iam:DetachUserPolicy"
        ],
        "Resource": var.trustle-connector-writable-groups
      }
    ]
  })
}


#
# Connector user
#

resource "aws_iam_user" "trustle-connector" {
  name = var.trustle-connector-user
}

resource "aws_iam_user_policy_attachment" "trustle-connector-read-policy-attachment" {
  user       = aws_iam_user.trustle-connector.name
  policy_arn = aws_iam_policy.trustle-connector-read-policy.arn
}

# Remove this policy attachment for read-only use
resource "aws_iam_user_policy_attachment" "trustle-connector-write-policy-attachment" {
  user       = aws_iam_user.trustle-connector.name
  policy_arn = aws_iam_policy.trustle-connector-write-policy.arn
}


#
# Access keys
#

# Remove this to manually create AWS access keys in the AWS console
resource "aws_iam_access_key" "trustle-connector-access-key" {
  user = aws_iam_user.trustle-connector.name
}
