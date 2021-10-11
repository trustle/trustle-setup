# AWS Trustle Connector

This Terraform template will create policies and a user in AWS for the
Trustle Connector.

## Example

This Terraform template is an example. It will need to be customized for your
specific environment and requirements.

For example, if the Trustle Connector will be read-only, syncing users and
groups from AWS but not updating them, then the
`trustle-connector-write-policy` is not needed.

Additionally, access and secret keys can be manually obtained from the AWS
console instead of automatically with this template, in which case the template
needs to be edited to skip this step.

## Configuration

Several configuration variables are supported - such as the name of the Trustle
Connector user, or what groups are accessible to the (optional) write policy.

The template performs the following actions in AWS:

+ Creates an AWS policy for imports from AWS. Default: `trustle-connector-read`.
+ Creates an AWS policy for writes to AWS. Default: `trustle-connector-write`.
  This policy can be removed from the template for read-only access by Trustle.
+ Creates an AWS user for the Trustle Connector. Default: `trustle-connector`.
+ Attaches the created policies to the created user.
+ Creates access and secret keys for the created user. This part of the template
  can be removed to manually create AWS access keys in the AWS console.

**Important: The Terraform template uses the `aws_iam_access_key` resource to
create an AWS access key and secret key for the Trustle Connector user. These
credentials are stored in the Terraform state file.** To avoid any potential
exposure of these sensitive credentials, remove the outputs and resource from
the Terraform template.

## Usage

Before applying this template please insure it has been modified for your usage.

```
$ terraform init

$ terraform apply

$ terraform output trustle-connector-access-key

$ terraform output trustle-connector-secret-key

```

The access and secret keys are provided to Trustle when configuring an Automated
AWS resource management system within the Trustle management UI. If manual
creation of AWS access keys are preferred, obtain those directly from the AWS
console.
