resource "aws_sqs_queue" "karpenter_interruption" {
  name                       = "KarpenterInterruptionQueue-${local.cluster_name}"
  message_retention_seconds  = 300
  visibility_timeout_seconds = 30
}

resource "aws_cloudwatch_event_rule" "interruption_spot" {
  name        = "KarpenterInterruptionSpot-${local.cluster_name}"
  description = "EC2 Spot Interruption Events to SQS"
  event_pattern = jsonencode({
    source      : ["aws.ec2"],
    detail-type : ["EC2 Spot Instance Interruption Warning"]
  })
}

resource "aws_cloudwatch_event_target" "interruption_spot_target" {
  rule      = aws_cloudwatch_event_rule.interruption_spot.name
  target_id = "SendToSQS"
  arn       = aws_sqs_queue.karpenter_interruption.arn
}

resource "aws_cloudwatch_event_rule" "interruption_state_change" {
  name        = "KarpenterInstanceStateChange-${local.cluster_name}"
  description = "EC2 Instance State-change notifications"
  event_pattern = jsonencode({
    source      : ["aws.ec2"],
    detail-type : ["EC2 Instance State-change Notification"]
  })
}

resource "aws_cloudwatch_event_target" "interruption_state_change_target" {
  rule      = aws_cloudwatch_event_rule.interruption_state_change.name
  target_id = "SendToSQS"
  arn       = aws_sqs_queue.karpenter_interruption.arn
}

resource "aws_sqs_queue_policy" "allow_events" {
  queue_url = aws_sqs_queue.karpenter_interruption.id
  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Sid : "AllowEventsToSend",
        Effect : "Allow",
        Principal : { Service : "events.amazonaws.com" },
        Action : "sqs:SendMessage",
        Resource : aws_sqs_queue.karpenter_interruption.arn
      }
    ]
  })
}


