# Deployment on AWS using Terraform

This repository deploys a infrastructure using Terraform on AWS with the following setup.

 - One load balancer.
 - Two initial instances with a small web server.
 - Two security groups:
	 - One to make accessible the content from the load balancer.
	 - One to make accessible the instances to the load balancer.

## Prerrequisites

 - AWS account.
 - Terraform installed.
 - Setup the global variables AWS_SECRET_ACCESS_KEY and  AWS_ACCESS_KEY_ID

## Terraform Variables
This Terraform file allows to modify two variables

 - server_port: The port the server will use for HTTP requests (8080 by default)
 - instance_number: This is used for the initial deployment (2 by default) can be modified to scale-in or scale-out. AWS will create or destroy instances in order to match this value.

## Instances

I decided to use a small sized instance with a little http server, this was choosen to keep the file as simple as possible.

With an http server testing is easier, by doing a curl action to the load balancer.

## Security

For security all HTTP are routed through the load balancer to the instances in the ASG.

The autoescaler could deploy on all the available zones from aws, this will make the infraestructore more robust, as if one region falls there should be instances deployed in other regions.

## Load Balancer

It has a health check, needed to keep track on how it's performing. Listening to port 80 which is open for curl petitions and available for all the zones. 

## Autoscaler

Here is where the user can decide how many instances are needed, they all connect to the load balancer previously defined. 

The value is 2 by default, but can be easily modified by modifying the variable "instance_number" or when calling terraform and modifying it from command line. 


## Example how to use it

On the path where the *.tf is located run terraform plan first to see the modifications that will be made and after it terraform apply.

To change the number of instances, use: terraform plan -var instances_number="number of instances" This will make a scale-up or scale-down if needed.