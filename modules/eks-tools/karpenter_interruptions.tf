resource "aws_sqs_queue" "karpenter_interruption" {
  count                      = var.karpenter_enabled ? 1 : 0
  name                       = "KarpenterInterruptionQueue-${var.cluster_name}"
  message_retention_seconds  = 300
  visibility_timeout_seconds = 30
}

resource "aws_cloudwatch_event_rule" "interruption_spot" {
  count       = var.karpenter_enabled ? 1 : 0
  name        = "KarpenterInterruptionSpot-${var.cluster_name}"
  description = "EC2 Spot Interruption Events to SQS"
  event_pattern = jsonencode({
    source      : ["aws.ec2"],
    detail-type : ["EC2 Spot Instance Interruption Warning"]
  })
}

resource "aws_cloudwatch_event_target" "interruption_spot_target" {
  count     = var.karpenter_enabled ? 1 : 0
  rule      = aws_cloudwatch_event_rule.interruption_spot[0].name
  target_id = "SendToSQS"
  arn       = aws_sqs_queue.karpenter_interruption[0].arn
}

resource "aws_cloudwatch_event_rule" "interruption_state_change" {
  count       = var.karpenter_enabled ? 1 : 0
  name        = "KarpenterInstanceStateChange-${var.cluster_name}"
  description = "EC2 Instance State-change notifications"
  event_pattern = jsonencode({
    source      : ["aws.ec2"],
    detail-type : ["EC2 Instance State-change Notification"]
  })
}

resource "aws_cloudwatch_event_target" "interruption_state_change_target" {
  count     = var.karpenter_enabled ? 1 : 0
  rule      = aws_cloudwatch_event_rule.interruption_state_change[0].name
  target_id = "SendToSQS"
  arn       = aws_sqs_queue.karpenter_interruption[0].arn
}

resource "aws_sqs_queue_policy" "allow_events" {
  count    = var.karpenter_enabled ? 1 : 0
  queue_url = aws_sqs_queue.karpenter_interruption[0].id
  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Sid : "AllowEventsToSend",
        Effect : "Allow",
        Principal : { Service : "events.amazonaws.com" },
        Action : "sqs:SendMessage",
        Resource : aws_sqs_queue.karpenter_interruption[0].arn
      }
    ]
  })
}


