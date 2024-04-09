data "aws_caller_identity" "current" {}

data "aws_ecr_authorization_token" "current" {}

locals {
  source_path = "example"
  source_tag  = sha1(join("", [for f in sort(fileset(path.module, "${local.source_path}/*")) : filesha1(f)]))
}

# see https://registry.terraform.io/modules/terraform-aws-modules/lambda/aws/latest/submodules/docker-build
# see https://github.com/terraform-aws-modules/terraform-aws-lambda
module "example_docker_image" {
  source  = "terraform-aws-modules/lambda/aws//modules/docker-build"
  version = "7.2.5"

  create_ecr_repo = true
  ecr_repo        = var.name_prefix

  use_image_tag = true
  image_tag     = local.source_tag
  source_path   = local.source_path
}

# see https://registry.terraform.io/modules/terraform-aws-modules/lambda/aws
# see https://github.com/terraform-aws-modules/terraform-aws-lambda
module "example_lambda_function" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "7.2.5"

  function_name  = var.name_prefix
  create_package = false
  publish        = true

  image_uri    = module.example_docker_image.image_uri
  package_type = "Image"

  allowed_triggers = {
    AllowExecutionFromAPIGateway = {
      service    = "apigateway"
      source_arn = "${module.api_gateway.apigatewayv2_api_execution_arn}/*/*"
    }
  }
}
