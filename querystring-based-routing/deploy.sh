#!/usr/bin/env bash

set -e

if [ -z $PROJECT_NAME ]; then
    echo "Project name is not set"
    exit 1
fi

if [ -z $SERVICE_A_PORT ]; then
    echo "Service A Port is not set"
    exit 1
fi

if [ -z $SERVICE_B_IMAGE ]; then
    echo "Service B image is not set"
    exit 1
fi

if [ -z $SERVICE_B_PORT ]; then
    echo "Service B image is not set"
    exit 1
fi

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"

deploy_infra(){
    echo "Deploying Cloud Formation stack: \"${PROJECT_NAME}-infra\" containing ALB, ECS Tasks, and Services..."
    aws cloudformation deploy \
        --no-fail-on-empty-changeset \
        --stack-name "${PROJECT_NAME}-infra" \
        --template-file "${DIR}/cf-infra-stack.yaml" \
        --capabilities CAPABILITY_IAM \
        --parameter-overrides "ProjectName=${PROJECT_NAME}" 
}
deploy_serviceA(){
    echo "Deploying Cloud Formation stack: \"${PROJECT_NAME}-serviceA\" containing Service A configuration..."
    aws cloudformation deploy \
        --no-fail-on-empty-changeset \
        --stack-name "${PROJECT_NAME}-serviceA" \
        --template-file "${DIR}/cf-serviceA-stack.yaml" \
        --capabilities CAPABILITY_IAM \
        --parameter-overrides "ProjectName=${PROJECT_NAME}" "ServiceAImage=${SERVICE_A_IMAGE}" "ServiceAContainerPort=${SERVICE_A_PORT}"
}
deploy_serviceB(){
    echo "Deploying Cloud Formation stack: \"${PROJECT_NAME}-serviceB\" containing Service B configuration..."
    aws cloudformation deploy \
        --no-fail-on-empty-changeset \
        --stack-name "${PROJECT_NAME}-serviceB" \
        --template-file "${DIR}/cf-serviceB-stack.yaml" \
        --capabilities CAPABILITY_IAM \
        --parameter-overrides "ProjectName=${PROJECT_NAME}" "ServiceBImage=${SERVICE_B_IMAGE}" "ServiceBContainerPort=${SERVICE_B_PORT}"
}
deploy_stacks() {
    deploy_infra
    deploy_serviceA
}

delete_cfn_stack() {
    stack_name=$1
    echo "Deleting Cloud Formation stack: \"${stack_name}\"..."
    aws cloudformation delete-stack --stack-name $stack_name
    echo 'Waiting for the stack to be deleted, this may take a few minutes...'
    aws cloudformation wait stack-delete-complete --stack-name $stack_name
    echo 'Done'
}

delete_serviceA(){
    echo "Delete Service A resources......"
    delete_cfn_stack "${PROJECT_NAME}-serviceA"
}
delete_serviceB(){
    echo "Delete Service B resources......"
    delete_cfn_stack "${PROJECT_NAME}-serviceB"
}

delete_stacks() {
    delete_cfn_stack "${PROJECT_NAME}-serviceA"
    delete_cfn_stack "${PROJECT_NAME}-serviceB"
    delete_cfn_stack "${PROJECT_NAME}-infra"
    echo "all resources for primary account have been deleted"
}
action=${1:-"deploy"}

if [ "$action" == "delete" ]; then
    delete_stacks
    exit 0
fi

if [ "$action" == "delete-A" ]; then
    delete_serviceA
    exit 0
fi

if [ "$action" == "delete-B" ]; then
    delete_serviceB
    exit 0
fi

if [ "$action" == "deploy" ]; then
    deploy_stacks
    exit 0
fi

if [ "$action" == "deploy-A" ]; then
    deploy_serviceA
    exit 0
fi

if [ "$action" == "deploy-B" ]; then
    deploy_serviceB
    exit 0
fi