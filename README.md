# cloudformation-docker-provisioning

## TLDR: 
Create a CloudFormation stack, install docker on it, and copies the config 
into your local directory.

## Why?

AWS CloudFormation provides a declarative template-based way to declare 
your infrastructure within code. This project provides a setup together with docker
in one single script `provision.sh`.

## Prerequisites

This project assumes you have your AWS setup done (e.g. using `~/.aws` or aws-vault), 
so that you are have the rights to launch an EC2 instance. 
Depending on your CloudFormation template, you might need more access rights.
Warning: Starting a machine can imply costs.  

This assumes that you have `docker`, `docker-machine`, `python`, and `aws` installed.

## Getting started

Usage:
    
    src/provision.sh <STACK_NAME> <CLOUDFORMATION_TEMPLATE>
    
Example:
    
    src/provision.sh example-stack examples/templates/CloudFormation.template
    
`<STACK_NAME>` refers to your desired CloudFormation stack name. 
`<CLOUDFORMATION_TEMPLATE>` is the path to your CloudFormation template.

To source the docker environment variables in your shell, run: 
    
    eval $(src/env.sh <STACK_NAME>)

Now you have your remote docker host setup and can run all sorts of 
docker (or docker-compose) commands like: 
    
    docker run -i -t -p 80:80 ubuntu /bin/bash
