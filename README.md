HabitApp CI/CD Project
Project Overview
Architecture
GitHub → Jenkins → Maven → Unit Tests → SonarQube → Quality Gate → Docker → Amazon ECR → Helm values update → GitHub → Argo CD → Amazon EKS → HabitApp

Technologies
Java 21
Maven
Jenkins
SonarQube
Docker
Amazon ECR
Helm
Amazon EKS
Argo CD
Repository Structure
Maven Build and Unit Testing
SonarQube and Quality Gate
Docker
Amazon ECR
Helm
Kubernetes
Jenkins CI Pipeline
Argo CD GitOps Deployment
Security
Rolling Deployment
Rollback
Monitoring and Logging
Application URL
Application URL
The HabitApp application is deployed on Amazon EKS and exposed through an AWS LoadBalancer service.

Application URL:

http://aa71da9d723e44f53ba4eca59810aa0d-1425773486.ap-south-2.elb.amazonaws.com/

API Endpoint:

http://aa71da9d723e44f53ba4eca59810aa0d-1425773486.ap-south-2.elb.amazonaws.com/api/habits

Verification:

Application is accessible through the AWS LoadBalancer.
Root endpoint returns HTTP 200.
/api/habits returns the HabitApp API response.
Application runs with two Kubernetes replicas.
Argo CD manages the Kubernetes deployment using GitOps.
