## _Hosting a Dynamic Web App on AWS using Terraform Modules_

### Overview

This technical document outlines the infrastructure setup for hosting a containerized web application on AWS using Terraform modules. The infrastructure consists of a Virtual Private Cloud (VPC), Elastic Container Service (ECS), Application Load Balancer (ALB), and Amazon Elastic Container Registry (ECR).

### Architecture Components

### _1. VPC Module_

The VPC module creates a secure networking environment with the following components:

`2 public subnets for the ALB`

`2 private subnets for ECS tasks`

`Internet Gateway for public subnet access`

`NAT Gateways for private subnet outbound traffic`

`Route tables for both public and private subnets`

```
module "vpc" {

  source = "./modules/vpc"
  vpc_cidr           = "10.0.0.0/16"
  environment        = "dev"
  availability_zones = ["us-east-1a", "us-east-1b"]
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets    = ["10.0.3.0/24", "10.0.4.0/24"]

}
```

### _2. ECR Module_

The ECR module manages the container registry:

Repository for storing Docker images
Lifecycle policies for image management
Repository policies for access control.


```
module "ecr" {
  source = "./modules/ecr"
  repository_name = "webapp"
  environment     = "dev"
  image_tag_mutability = "MUTABLE"

}
```



### _3. ECS Module_

The ECS module orchestrates container deployment:

Fargate cluster for serverless container management

Task definitions specifying container configurations

Service definitions for maintaining desired task count

Security groups for task networking.


```hcl
 module "ecs" {
  source = "./modules/ecs"
  cluster_name    = "webapp-cluster"
  environment     = "dev"
  container_name  = "webapp"
  container_port  = 3000
  desired_count   = 2
  cpu            = 256
  memory         = 512
  
  ## Integration with other modules
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnet_ids
  alb_target_group_arn = module.alb.target_group_arn

}
```

### _4. ALB Module_
The ALB module handles traffic distribution:

Application Load Balancer in public subnets
Target group for ECS tasks
Security groups for load balancer access
HTTPS listener with SSL certificate.

```
module "alb" {
  source = "./modules/alb"
  
  name           = "webapp-alb"
  environment    = "dev"
  vpc_id         = module.vpc.vpc_id
  public_subnets = module.vpc.public_subnet_ids
  
  health_check_path = "/health"
  health_check_port = 3000
}
```
### _Container Configuration_

#### Dockerfile
![](./img/6.%20dockerfile.png)

The image above contain the content of the dockerfile.

### To Build image;
`docker build -t webapp:latest .`

### Tag for ECR
`docker tag webapp:latest ${ECR_REPOSITORY_URL}:latest`

### Push to ECR
`aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${ECR_REPOSITORY_URL}
docker push ${ECR_REPOSITORY_URL}:latest`

![](./img/2.%20ecr-repository-created.png)

docker push to ecr repository;
![](./img/3.docker-push-webapp.png)


### _Security Considerations_

### Network Security

VPC with public and private subnets

ALB in public subnets, ECS tasks in private subnets

Security groups limiting access:

ALB: Inbound HTTP/HTTPS from internet

ECS Tasks: Inbound only from ALB on application port

### IAM Roles and Policies

#### 1. ECS Task Execution Role:
* ECR image pull permissions

* CloudWatch logs write permissions


#### 2. ECS Task Role:

* Application-specific AWS service access
* Custom service integrations

### Monitoring and Logging
#### CloudWatch Configuration

* Container logs forwarded to CloudWatch Logs
* Metrics for ECS service and task monitoring
* ALB access logs for traffic analysis

### _Docker Build_
![](./img/1.docker-build.png)

The critical aspect of the project is to dockerize the image and this was achieved with `docker build -t tosyeno-webapp`.

### _Deployment phase_
![](./img/4.%20terraform-init-successful.png)

The deployment phase begins with terraform command `terraform init` to initialize a terraform working directory, follow by `terraform plan` and `terraform apply`.

### _Conclusion_

This infrastructure setup provides a scalable, secure, and maintainable environment for hosting containerized web applications. The use of Terraform modules ensures consistent infrastructure deployment and makes it easy to manage multiple environments.

