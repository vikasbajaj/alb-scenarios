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

if [ -z $SERVICE_C_IMAGE ]; then
    echo "Service C image is not set"
    exit 1
fi

if [ -z $SERVICE_C_PORT ]; then
    echo "Service C image is not set"
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
deploy_stack-1(){
    echo "Deploying Cloud Formation stack: \"${PROJECT_NAME}-serviceA\" containing Service A and C configuration..."
    aws cloudformation deploy \
        --no-fail-on-empty-changeset \
        --stack-name "${PROJECT_NAME}-stack-1" \
        --template-file "${DIR}/cf-service-stack-1.yaml" \
        --capabilities CAPABILITY_IAM \
        --parameter-overrides "ProjectName=${PROJECT_NAME}" \
        "ServiceAImage=${SERVICE_A_IMAGE}" "ServiceAContainerPort=${SERVICE_A_PORT}" \
        "ServiceCImage=${SERVICE_C_IMAGE}" "ServiceCContainerPort=${SERVICE_C_PORT}"
}
deploy_stack-2(){
    echo "Deploying Cloud Formation stack: \"${PROJECT_NAME}-serviceB\" containing Service B configuration..."
    aws cloudformation deploy \
        --no-fail-on-empty-changeset \
        --stack-name "${PROJECT_NAME}-stack-2" \
        --template-file "${DIR}/cf-service-stack-2.yaml" \
        --capabilities CAPABILITY_IAM \
        --parameter-overrides "ProjectName=${PROJECT_NAME}" "ServiceBImage=${SERVICE_B_IMAGE}" "ServiceBContainerPort=${SERVICE_B_PORT}"
}
deploy_stacks() {
    deploy_infra
    deploy_stack-1
    deploy_stack-2
}

delete_cfn_stack() {
    stack_name=$1
    echo "Deleting Cloud Formation stack: \"${stack_name}\"..."
    aws cloudformation delete-stack --stack-name $stack_name
    echo 'Waiting for the stack to be deleted, this may take a few minutes...'
    aws cloudformation wait stack-delete-complete --stack-name $stack_name
    echo 'Done'
}

delete_stack-1(){
    echo "Delete Service A resources......"
    delete_cfn_stack "${PROJECT_NAME}-stack-1"
}
delete_stack-2(){
    echo "Delete Service B resources......"
    delete_cfn_stack "${PROJECT_NAME}-stack-2"
}

delete_stacks() {
    delete_cfn_stack "${PROJECT_NAME}-stack-1"
    delete_cfn_stack "${PROJECT_NAME}-stack-2"
    delete_cfn_stack "${PROJECT_NAME}-infra"
    echo "all resources for primary account have been deleted"
}

action=${1:-"deploy"}
if [ "$action" == "delete" ]; then
    delete_stacks
    exit 0
fi

if [ "$action" == "delete-1" ]; then
    delete_stack-1
    exit 0
fi

if [ "$action" == "delete-2" ]; then
    delete_stack-2
    exit 0
fi

if [ "$action" == "deploy" ]; then
    deploy_stacks
    exit 0
fi

if [ "$action" == "deploy-1" ]; then
    deploy_stack-1
    exit 0
fi

if [ "$action" == "deploy-2" ]; then
    deploy_stack-2
    exit 0
fi