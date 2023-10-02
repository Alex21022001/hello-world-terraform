provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      hello-world = "lambda-api-gateway"
    }
  }
}

###########Bucket
resource "random_pet" "s3_bucket_name" {
  prefix = "lambda-bucket"
  length = 4
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = random_pet.s3_bucket_name.id
}

resource "aws_s3_object" "lambda_hello_world" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key    = "hello-world.zip"
  source = "${path.module}/target/function.zip"

  etag = filemd5("${path.module}${var.function_zip_path}")
}


#Lambda
resource "aws_lambda_function" "hello_world" {
  function_name = "hello-world"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.lambda_hello_world.key

  runtime = "java17"
  handler = "io.quarkus.amazon.lambda.runtime.QuarkusStreamHandler::handleRequest"

  source_code_hash = base64sha256("${path.module}${var.function_zip_path}")

  role = aws_iam_role.lambda_role.arn
}

resource "aws_cloudwatch_log_group" "hello_world" {
  name = "/aws/lambda/${aws_lambda_function.hello_world.function_name}"

  retention_in_days = 30
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Sid       = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.name
}

#Api Gateway
resource "aws_apigatewayv2_api" "api_gateway_hello_world" {
  name          = "hello-world-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "lambda" {
  api_id = aws_apigatewayv2_api.api_gateway_hello_world.id

  name        = "dev"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_cw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
    }
    )
  }
}

resource "aws_apigatewayv2_integration" "hello_world_lambda_int" {
  api_id = aws_apigatewayv2_api.api_gateway_hello_world.id

  integration_uri    = aws_lambda_function.hello_world.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "api_hello_route" {
  api_id = aws_apigatewayv2_api.api_gateway_hello_world.id

  route_key = "GET /hello"
  target    = "integrations/${aws_apigatewayv2_integration.hello_world_lambda_int.id}"
}

resource "aws_cloudwatch_log_group" "api_cw" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.api_gateway_hello_world.name}"

  retention_in_days = 30
}

resource "aws_lambda_permission" "api_lambda_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello_world.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.api_gateway_hello_world.execution_arn}/*/*"
}
