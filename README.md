# spring-boot-with-aws-eks-and-terraform
Example SpringBoot application deployed with Terraform and Kubernetes to EKS

This project contains four different examples to help you learn how to tie Java, Docker, Kubernetes, and Terraform together.
The first two examples are generic deploy EKS with a default image, examples 3 and 4 demonstrate how to deploy EKS and a custom image.

I think the biggest realization that needs to be had when working with all of these related technologies is that there is
essentially two different deployments occurring. The first deployment is that Terraform is going to reach out to Aws and
create the EKS cluster (Kubernetes) as described in the IoC. Once the EKS cluster (Kubernetes) exists, Terraform will then deploy the Docker 
image/container to the EKS cluster (Kubernetes). Stated a different way, it is not possible to deploy the Docker image/container
until the infrastructure exists to receive the deployment.

General order of operation
* dev develops the application and all IoC
* builds code as a Docker image/container
* pushes Docker image/container to container repository
* runs IoC
* IoC creates EKS cluster (Kubernetes)
* IoC deploys Docker image/container to EKS cluster

Let's get started ...

## Example 1

Example 1 is based on this [post](https://spacelift.io/blog/terraform-kubernetes-deployment#2-deploy-a-sample-application-to-kubernetes-with-terraform),
and while it contains a fair amount of good information, I was not able to get the example deployed
and running as described. I was able to get the EKS cluster deployed, but it was not accessible once deployed.

*In my example in this repo, I have fixed this so that it will execute as described.*

I found this [YouTube](https://youtu.be/LZssMfdJSeM?si=pQwDJbKR-7LqpJyK) really helpful when debugging the initial tutorial,
and it did get me past the deployment error, but the application was still unreachable.

## Example 2

Following the above attempt, I tried based on this similar [post](https://spacelift.io/blog/terraform-eks). While
not as verbose as the initial write-up this one uses a pre-built module (`terraform-aws-modules/eks/aws`) to connect to EKS.
This greatly simplifies what is required to get an EKS cluster up and running (I had a suspicion this was where my 
issue was when running the first tutorial; some form of misconfiguration in EKS) and using this post, I was able to successfully 
get an EKS cluster and app deployed. 

## Example 3

Example 3 is simply Example 1 but instead of deploying the pre-built nginx container with manually configured EKS, 
it is deploying the custom Spring Boot app that is part of this repository.

## Example 4

Example 4 is simply Example 2 but instead of deploying the pre-built nginx container using the EKS module, it is deploying
the custom Spring Boot app that is part of this repository.


## Pre-requisites: All Examples

* Make sure you are already signed in to AWS using the cli
    * `aws sso login`
    * or if using profiles
    * `aws sso login --profile brr-np-admin`
    * then due to terraform being kind of funny with sso use the ssocreds helper
    * `ssocreds`
    * or if using profiles
    * `ssocreds -p brr-np-admin`
    * This will copy the appropriate credentials to the older style login which terraform currently requires

## [Example 1](https://spacelift.io/blog/terraform-kubernetes-deployment#2-deploy-a-sample-application-to-kubernetes-with-terraform)
As stated above, I did have issues getting example 1 working correctly. In summary, example 1 is a full manual configuration
for using EKS. To get the example working do the following ...

* Copy the code from the linked tutorial (if the page is down, a PDF is available under the documentation folder)
  * OR
* Use the pre-written main tf `main-example-1-working.tf.bak`
  * Copy everything in this file to the `main.tf` file
  * Modifications included that are different from the linked tutorial
    * Updated resource names to be match this example
    * Using terraform data to get availability regions rather than hand coding them
  * What is ACTUALLY different from the example to get it working?
    * had to add `resource "aws_route_table" "private" {`
    * had to add `resource "aws_route_table_association" "private" {`
    * Without adding these resources the application was locked in the private subnet with no internet access and could not be added to the cluster.
      * Note: If you want to try manual image deployment to EKS only copy the values above "End EKS Configuration." Everything
      * below that pertains to image deployment
* `terraform init`
* `terraform validate`
* `terraform plan`
* `terraform apply -auto-approve`
* Use the `eks_connect` output value to connect your cluster to your local `kubectl`
  * i.e. copy `aws --profile brr-np-admin eks --region us-east-2 update-kubeconfig --name my-eks-cluster-example-1-zgokK91O"` to the terminal and run
* `kubectl config current-context`
* verify everything is up
  * `kubectl get nodes`
  * `kubectl get pods`
  * or if using a namespace (which we are in this example)
  * `kubectl get pods -n terraform-k8s` - because the app is deployed to a custom namespace
* port forward the deployed application so it is reachable from your local system
  * `kubectl --namespace=terraform-k8s port-forward nginx-6bb949f5fb-THISVALUEISALWAYSUNIQUE 3000:80`
* Open a browser and navigate to `localhost:3000`
* `ctrl-c` to stop port forwarding
* `terraform destroy -auto-approve`
  * cleans up and removes infrastructure so you are not charged

## [Example 2](https://spacelift.io/blog/terraform-eks)

* Copy the code from the linked tutorial (if its down pdf is available under the documentation folder)
    * OR
* Use the pre-written main tf `main-example-2-working.tf.bak`
    * Copy everything in this file to the `main.tf` file
    * What is different from example 1?
      * This uses a pre-built eks module to simplify the process
        * Note: If you want to try manual image deployment to EKS only copy the values above "End EKS Configuration". Everything
        * below that pertains to image deployment
* `terraform init`
* `terraform validate`
* `terraform plan`
* `terraform apply -auto-approve`
* Use the `eks_connect` output value to connect your cluster to your local `kubectl`
  * i.e. copy `aws --profile brr-np-admin eks --region us-east-2 update-kubeconfig --name my-eks-cluster-example-1-zgokK91O"` to the terminal and run
* `kubectl config current-context`
* verify everything is up
  * `kubectl get nodes`
  * `kubectl get pods`
  * or if using a namespace (which we are in this example)
  * `kubectl get pods -n terraform-k8s` - because the app is deployed to a custom namespace
* port forward the deployed application so it is reachable from your local system
  * `kubectl --namespace=terraform-k8s port-forward nginx-6bb949f5fb-THISVALUEISALWAYSUNIQUE 3000:80`
* Open a browser and navigate to `localhost:3000`
* `ctrl-c` to stop port forwarding
* `terraform destroy -auto-approve`
  * cleans up and removes infrastructure so you are not charged
  * There are some issues destroying when using the pre-built eks module. For notes on this see [problems](#problems-destroying-example-24).

# Running the custom spring app in this repository

## Pre-requisites: Example 3 & 4:

* When wanting to use a local image, you need to configure a local docker repo. This can be done with the following ...
  * `docker run -d -p 5001:5000 --restart=always --name registry registry:2`
  * https://stackoverflow.com/questions/57167104/how-to-use-local-docker-image-in-kubernetes-via-kubectl
  * I HAD ISSUE WITH THIS. I WAS ABLE TO GET THE REGISTRY UP AND RUNNING AND PUSH TO IT, BUT I COULDN'T GET KUBERNETES TO 
  * PULL CORRECTLY FROM IT SO I WENT WITH SETTING UP AN ACTUAL DOCKER ACCOUNT (See below).
* Build the docker image
  * `docker image build -t spring-boot-with-aws-eks-and-terraform:1.0 .`
* Tag the docker image
  * `docker tag spring-boot-with-aws-eks-and-terraform:1.0 localhost:5001/spring-boot-with-aws-eks-and-terraform:1.0`
  * tagging should use the build image name for parameter 1 and the repo name for parameter 2
  * the repo name MUST be prepended with the `localhost:5001/`
* Push the docker image to the local repo
  * `docker push localhost:5001/spring-boot-with-aws-eks-and-terraform:1.0`
  * If you're having errors, check this
    * https://stackoverflow.com/questions/48038969/an-image-does-not-exist-locally-with-the-tag-while-pushing-image-to-local-regis
* If you want to test run just the docker image you can use the following command
  * `docker run -p 8080:8080 spring-boot-with-aws-eks-and-terraform:1.0 `

### OR (preferred)

* Set up a personal docker account and push to it
  * `docker buildx build --platform linux/amd64 -t spring-boot-with-aws-eks-and-terraform .`
    * This took a minute to figure out that when building on newer Macs it is built for ARM by default and then will 
    * not run when deployed to a linux platform. Thus, when building the image we need to specify the platform to build for.
  * `docker tag spring-boot-with-aws-eks-and-terraform rhineb/spring-boot-with-aws-eks-and-terraform:latest`
  * `docker push rhineb/spring-boot-with-aws-eks-and-terraform:latest`
  * YOU WILL NOT BE ABLE TO TEST THIS IMAGE LOCALLY IF YOU ARE ON A M-SERIES MAC AS THE IMAGE IS BUILT FOR A DIFFERENT ARCHITECTURE


## Example 3 / Example 1

* Use the pre-written main tf `main-example-3-working.tf.bak`
  * Copy everything in this file to the `main.tf` file
  * This is the same as example 1, but it is deploying the custom spring boot app from this repo
    * Note: If you want to try manual image deployment to EKS only copy the values above "End EKS Configuration". Everything
    * below that pertains to image deployment
* `terraform init`
* `terraform validate`
* `terraform plan`
* `terraform apply -auto-approve`
* Use the `eks_connect` output value to connect your cluster to your local `kubectl`
  * i.e. copy `aws --profile brr-np-admin eks --region us-east-2 update-kubeconfig --name my-eks-cluster-example-4-zgokK91O"` to the terminal and run
* `kubectl config current-context`
* verify everything is up
  * `kubectl get nodes`
  * `kubectl get pods`
  * or if using a namespace (which we are in this example)
  * `kubectl get pods -n terraform-k8s` - because the app is deployed to a custom namespace
* port forward the deployed application so it is reachable from your local system
  * `kubectl --namespace=terraform-k8s port-forward spring-boot-with-aws-eks-and-terraform-7bdfb6c454-THISVALUEISALWAYSUNIQUE 3000:8080`
* Open postman and create a GET request to `http://localhost:3000/api/hello/YOUR-NAME/YOUR-AGE`
  * See that you receive a 200 response with the message `Hello, ben! You are 41 years old.`
* `ctrl-c` to stop port forwarding
* `terraform destroy -auto-approve`
  * cleans up and removes infrastructure so you are not charged
  * it is common to have time-outs while destroying, and you will need to re-run the destroy command to complete cleanup

Note: This example does not have the same destroy issue as Example 4 as it is not using the Terraform EKS module.

## Example 4 / Example 2

* Use the pre-written main tf `main-example-4-working.tf.bak`
  * Copy everything in this file to the `main.tf` file
  * This is the same as example 1, but it is deploying the custom spring boot app from this repo
    * Note: If you want to try manual image deployment to EKS only copy the values above "End EKS Configuration". Everything
    * below that pertains to image deployment
* `terraform init`
* `terraform validate`
* `terraform plan`
* `terraform apply -auto-approve`
* Use the `eks_connect` output value to connect your cluster to your local `kubectl`
  * i.e. copy `aws --profile brr-np-admin eks --region us-east-2 update-kubeconfig --name my-eks-cluster-example-4-zgokK91O"` to the terminal and run
* `kubectl config current-context`
* verify everything is up
  * `kubectl get nodes`
  * `kubectl get pods`
  * or if using a namespace (which we are in this example)
  * `kubectl get pods -n terraform-k8s` - because the app is deployed to a custom namespace
* port forward the deployed application so it is reachable from your local system
  * `kubectl --namespace=terraform-k8s port-forward spring-boot-with-aws-eks-and-terraform-7bdfb6c454-THISVALUEISALWAYSUNIQUE 3000:8080`
* Open postman and create a GET request to `http://localhost:3000/api/hello/YOUR-NAME/YOUR-AGE`
  * See that you receive a 200 response with the message `Hello, ben! You are 41 years old.`
* `ctrl-c` to stop port forwarding
* `terraform destroy -auto-approve`
  * cleans up and removes infrastructure so you are not charged
  * There are some issues destroying when using the pre-built eks module. For notes on this see [problems](#problems-destroying-example-24).

Note: If you are having issues with it getting the image, make sure there are no accidental SPACES in the image name

## Problems `destroying` Example 2/4

I had a terrible time getting this example to destroy correctly. Something about using the terraform provided
EKS module causes it to hold the internet gateway ips and it won't remove them. To remediate this issue I added
the following ...

```terraform
module "eks" {
  depends_on = [aws_route_table_association.public]
```

This tells Terraform that the module depends on this resource and that it needs to wait until actions on this resource
have been completed.

## Add EKS instance to local kubectl

This is required to be able to perform any sort of management from your local machine. The command required for this 
will be returned as an `output` from each of the examples in this repo titled `eks_connect`. Copy that value and execute ...

This adds your EKS cluster config to your local machines ~/.kube/config so you can connect to the cluster from your machine.

The command should look similar to the following ...

### Default AWS profile

If you are using the default profile or do not have aws profiles configured, the command will look similar to this 

`aws eks --region us-east-2 update-kubeconfig --name my-eks-cluster`

### Custom AWS profile

If you are using profiles then the command will look more like this 

`aws --profile brr-np-admin eks --region us-east-2 update-kubeconfig --name my-eks-cluster-example-2`

## Check the current Kubernetes context

Check to make sure you’re connected to your AWS EKS cluster

`kubectl config current-context`

## View Kubernetes namespaces

If you are having issues finding the deployed application check which namespace it was deployed to. In this example
the "apps/images" are being deployed to the `terraform-k8s` namespace.

`kubectl get namespaces`

## Verify resources have been deployed

Run Kubectl commands to ensure resources have been deployed

`kubectl get pods`

### Get all pods in a namespaces

`kubectl get pods -n terraform-k8s`

### Get all pods in all namespaces

`kubectl get pods --all-namespaces`

## Automatic port forwarding as part of Terraform

[Port Forwarding](https://www.google.com/search?client=safari&rls=en&q=how+to+kubectl+port+forward+as+part+of+terraform&ie=UTF-8&oe=UTF-8)
- [](https://spacelift.io/blog/kubectl-port-forward)
- [Port Forward from specific namespace](https://www.google.com/search?client=safari&rls=en&q=kubectl+port+forward+different+namespace&ie=UTF-8&oe=UTF-8)

`kubectl --namespace=development port-forward pod/my-app 80:8080`

or you can add the following to your terraform scripts

WARNING!!! THE FOLLOWING CAN BE ADDED, BUT I HAD LOTS OF ISSUES WITH THIS AND MOST OF THE TIME TERRAFORM WILL NOT DESTROY
IF THESE RESOURCES ARE ADDED. IT FAILS TO SEE THE KUBECTL SERVICE AND DOES NOT KILL IT THUS THE CONNECTION IS HELD OPEN
AND THE TERRAFORM DESTROY WILL FAIL.

```terraform
     resource "null_resource" "port_forward" {
       provisioner "local-exec" {
         command = <<EOF
           kubectl port-forward service/my-service 8080:80 &
           echo "Port forwarding established"
         EOF
         environment = {
           KUBECONFIG = "/path/to/your/kubeconfig"  # Optional, if not using default
         }
       }
     }
```

*VERY IMPORTANT NOTE!!!*

YOU absolutely MUST ALSO ADD THE FOLLOWING ...

```terraform
     resource "null_resource" "stop_port_forward" {
       depends_on = [null_resource.port_forward]
       provisioner "local-exec" {
         command = "killall kubectl" # Or more specific process killing
       }
     }
```

If you do not add the following it will not be possible to `destroy` resources as expected as the port forward will hold
the connection open so YOU MUST add a way to kill the port forward.

*ALSO, CRUCIAL NOTE!!!*

I have not had success with the above, it will start as expected, but then it won't shutdown and I have to do a lot 
of additional work to kill the cluster and redeploy.


# Reference
* https://www.reddit.com/r/Terraform/comments/12zcest/unable_to_access_aws_eks_cluter_after_creating/
* https://medium.com/@rvisingh1221/create-an-eks-cluster-using-terraform-329b9dde068f
    * This example MIGHT be good but uses modules and s3 - it is more complex so I dont want to
      look at this one until the simple one works
* https://stackoverflow.com/questions/74963149/get-http-localhost-api-v1-namespaces-dial-tcp-127-0-0-180-con
  * Not sure if I actually ended up needing this
* https://www.google.com/search?client=safari&rls=en&q=can+you+access+application+deployed+to+eks+without+port+forwarding&ie=UTF-8&oe=UTF-8
* https://developer.hashicorp.com/terraform/tutorials/kubernetes/eks - i think there are some good references here
* https://www.youtube.com/watch?v=3mdCiFu52XA
* https://stackoverflow.com/questions/57167104/how-to-use-local-docker-image-in-kubernetes-via-kubectl
* https://www.google.com/search?client=safari&rls=en&q=kubectl+cant+see+local+docker+repository&ie=UTF-8&oe=UTF-8
* https://stackoverflow.com/questions/72206041/error-creating-eks-node-group-with-terraform
* https://www.google.com/search?client=safari&rls=en&q=terraform+kubernetes_deployment+example+with+image+pull&ie=UTF-8&oe=UTF-8
* https://www.google.com/search?client=safari&rls=en&q=remove+kubectl+image+deployment&ie=UTF-8&oe=UTF-8
* https://www.google.com/search?client=safari&rls=en&q=killall+kubectl&ie=UTF-8&oe=UTF-8
* https://stackoverflow.com/questions/45027830/cant-delete-aws-internet-gateway
* https://github.com/hashicorp/terraform/issues/1628
* https://github.com/hashicorp-education/learn-terraform-provision-eks-cluster/blob/main/main.tf
* https://developer.hashicorp.com/terraform/tutorials/kubernetes/eks

## Port Forwarding
* https://www.reddit.com/r/Terraform/comments/nj06y5/need_to_do_kubectl_portforward_in_the_middle_of/

## Amazon instance sizes
* https://aws.amazon.com/ec2/instance-types/t3/


## Use a local image
https://stackoverflow.com/questions/58654118/pulling-local-repository-docker-image-from-kubernetes

had a lot of problems with this

## Push image to docker hub
https://stackoverflow.com/questions/41984399/docker-push-error-denied-requested-access-to-the-resource-is-denied

docker tag local-image:tagname new-repo:tagname
docker push new-repo:tagname

## Debugging
https://sysdig.com/blog/debug-kubernetes-crashloopbackoff/

## Docker build image for different system architectures
https://stackoverflow.com/questions/75089403/docker-exec-usr-local-openjdk-11-bin-java-exec-format-error
https://www.google.com/search?client=safari&rls=en&q=how+to+build+docker+linux+image+on+m+series+mac&ie=UTF-8&oe=UTF-8

## Delete pods
https://www.google.com/search?client=safari&rls=en&q=kubectl+delete+pod&ie=UTF-8&oe=UTF-8


