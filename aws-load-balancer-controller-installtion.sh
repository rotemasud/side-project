#!/bin/bash

# Set variables
CLUSTER_NAME="side-project-cluster"
REGION="il-central-1"
IAM_POLICY_NAME="AWSLoadBalancerControllerIAMPolicy"
SERVICE_ACCOUNT_NAME="aws-load-balancer-controller"
NAMESPACE="kube-system"

# Create the IAM policy
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json
aws iam create-policy \
    --policy-name $IAM_POLICY_NAME \
    --policy-document file://iam_policy.json

# Create a service account for the controller
eksctl create iamserviceaccount \
  --cluster $CLUSTER_NAME \
  --namespace $NAMESPACE \
  --name $SERVICE_ACCOUNT_NAME \
  --attach-policy-arn arn:aws:iam::$(aws sts get-caller-identity --query "Account" --output text):policy/$IAM_POLICY_NAME \
  --approve

# Add the EKS cluster to your kubeconfig
aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME

# Add the eks-charts repository
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# Install the AWS Load Balancer Controller
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  --namespace $NAMESPACE \
  --set clusterName=$CLUSTER_NAME \
  --set serviceAccount.create=false \
  --set region=$REGION \
  --set vpcId=$(aws eks describe-cluster --name $CLUSTER_NAME --query "cluster.resourcesVpcConfig.vpcId" --output text) \
  --set serviceAccount.name=$SERVICE_ACCOUNT_NAME

# Verify the installation
kubectl get pods -n $NAMESPACE

echo "AWS Load Balancer Controller installation is complete!"

