### Deployment instructions

### Prerequisites: 
* yc-cli
* kubectl
* ansible
* terraform
* git
* docker, docker-compose
* python3.10
* ssh key
```
git clone http://github.com/arybach/slackfastapi
cd slackfastapi/terraform
terraform init
terraform apply -var-file=terraform.tfvars -auto-approve
terraform output -json > ../ansible/terraform_outputs.json
cd ../ansible
ansible-playbook fetch-creds.yml
# for digital ocean:
cd slackfastapi/terraform/digitalocean
terraform init
terraform apply -var-file=terraform.tfvars -auto-approve
terraform output -json > ../../ansible/terraform_outputs.json
# then follow instructions (check for root password in e-mail, ssh into a vm, ufw allow 5050/tcp
ufw allow OpenSSH, edit gitlab.rb, run gitlab-ctl reconfigure, etc.)
https://www.digitalocean.com/community/tutorials/how-to-use-the-gitlab-enterprise-edition-1-click-install-on-digitalocean
cd ../../ansible
ansible-playbook fetch-creds-do.yml
```
### update DNS records in yandex CLI
![Alt text](image.png)

### when images are built - to quickly deploy code to k8s
```
cd ../slackfastapi-master
kubectl create namespace slack-fastapi
kubectl apply -f deploy/kube
```
### otherwise: create managed Gitlab instance via yandex UI
![Alt text](image-1.png)
![Alt text](image-2.png)

### login using reset link sent to the email provided at Gitlab instance creation
### then create group and new project
![Alt text](image-3.png)

### Then under Settings -> CI/CD -> expand variables and add env vars (for testing they are also set in .env file, so can be skipped):
```
SLACK_FASTAPI_DB_USER="slack_fastapi"     # Same as POSTGRES_USER in docker-compose.yml
SLACK_FASTAPI_DB_PASSWORD="slack_fastapi" # Same as POSTGRES_PASSWORD in docker-compose.yml

# AWS credentials are REQUIRED for videos to be saved!
AWS_ACCESS_KEY_ID=""
AWS_SECRET_ACCESS_KEY=""
```
![Alt text](image-7.png)

### Create new project for the group (ADD ssh key via Gitlab UI) + add ssh key to it
![Alt text](image-4.png)

### Under project -> Settings -> CICD ->  Runners -> create new project runner:
```
# it will produce command like this:
gitlab-runner register  --url https://solarwinds123.ru  --token glrt-Zy5TDfqo3MWGGFYyp3d4

# modify gitlab-runner-values.yml with the url and token from above, then run:
cd ../ansible
ansible-playbook deploy-runner.yml

# check runner's pod logs in gitlab namespace to make sure it's ok and run:
kubectl auth can-i create deployments --as=system:serviceaccount:gitlab:default -n slack-fastapi
# should return - yes
```
![Alt text](image-6.png)
### under project -> Settings -> CI/CD -> Runners click on the newly registered runner to edit:
### add tags: docker-runner, kubernetes-runner, deploy-runner (these are added by default in gitlab-runner-values.yml)
```
# under project -> Operate -> Kubernetes Clusters -> Connect a Cluster -> start typing the name of the agent you want to create -> then click on create agent, when it appears as an option -> Register

export GITLAB_AGENT_TOKEN=glagent-wCNFLfqhb8tUmxCKmNZGsBsPJmAYaNsD33rCbsPy7y4hyHDbwQ
# then under ansible dir run:
ansible-playbook deploy-agent.yml
```
![Alt text](image-10.png)

### add env var KUBE_CONTEXT=slackfastapi/slackfastapi:slackfastapi (group_name/subgroup_name/project_name:agent_name)
![Alt text](image-11.png)

### before pushing to gitlab - under Settings -> Access Tokens -> create new Project Access Token - called 'container_registry' with read/write rights to container registry, repository and api, then create kubectl secret:
```
kubectl create secret docker-registry registrykey \
  --docker-server=solarwinds123.ru:5050 \
  --docker-username=container_registry \
  --docker-password=glpat-Bb5yLxk8txy5ArkG-jZG \
  -n slack-fastapi

# SET protected variables:
CI_REGISTRY=solarwinds123.ru:5050
CI_REGISTRY_USER=container_registry
CI_REGISTRY_PASSWORD=glpat-Bb5yLxk8txy5ArkG-jZG
```
### then push slackfastapi-master to gitlab
```
cd ../slackfastapi-master
git init --initial-branch=main # if needed
git remote set-url origin https://solarwinds123.ru/slackfastapi/slackfastapi.git
# check
git remote -v
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/tumblebuns
# change remote url to use ssh:
git remote set-url origin git@solarwinds123.ru:slackfastapi/slackfastapi.git
git push -u origin main
```

### additional settings should be set in .env file (as .gitlab-ci.yml expects this file to exist)
```
# General FastAPI settings
SLACK_FASTAPI_RELOAD="True"
SLACK_FASTAPI_PORT="8000"
SLACK_FASTAPI_ENVIRONMENT="dev"

# Database settings (modify with your database credentials)
SLACK_FASTAPI_DB_HOST="slack_fastapi-db"  # Use the service name of the database in docker-compose.yml
SLACK_FASTAPI_DB_PORT="5432"              # Same as in docker-compose.yml
SLACK_FASTAPI_DB_NAME="slack_fastapi"     # Same as POSTGRES_DB in docker-compose.yml

# Additional settings (if any) based on your application's `settings.py`, for example:
# SLACK_FASTAPI_API_KEY="your_api_key_value"
```

### before deploying monitoring to enable alerts create apikey with sendgrid.com and create a secret:
```
kubectl create namespace prometheus
kubectl create secret generic smtp-secret --from-literal=smtp_password='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' -n prometheus
```
### deploy monitoring

```
cd ../ansible
ansible-playbook deploy-monitoring.yml

# to fetch credentials:
% kubectl get secrets -n prometheus

NAME                                                                TYPE                 DATA   AGE
alertmanager-kube-prom-stack-kube-prome-alertmanager                Opaque               1      4h53m
alertmanager-kube-prom-stack-kube-prome-alertmanager-generated      Opaque               1      4h53m
alertmanager-kube-prom-stack-kube-prome-alertmanager-tls-assets-0   Opaque               0      4h53m
alertmanager-kube-prom-stack-kube-prome-alertmanager-web-config     Opaque               1      4h53m
kube-prom-stack-grafana                                             Opaque               3      4h53m
kube-prom-stack-kube-prome-admission                                Opaque               3      4h53m
kube-prom-stack-kube-prome-prometheus                               Opaque               0      4h53m
prometheus-kube-prom-stack-kube-prome-prometheus                    Opaque               1      4h53m
prometheus-kube-prom-stack-kube-prome-prometheus-tls-assets-0       Opaque               1      4h53m
prometheus-kube-prom-stack-kube-prome-prometheus-web-config         Opaque               1      4h53m
sh.helm.release.v1.kube-prom-stack.v1                               helm.sh/release.v1   1      4h53m

# password for grafana
% kubectl get secret kube-prom-stack-grafana -n prometheus -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

### deploy traefik ingress controller
```
cd ../ansible
ansible-playbook deploy-traefik.yml

# fetch external ip:
% kubectl get svc -n traefik
NAME              TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)                      AGE
traefik-ingress   LoadBalancer   10.245.25.142   139.59.217.202   80:31132/TCP,443:30207/TCP   39m

# then modify DNS records for *.solarwinds123.ru to point to it, solarwinds123.ru should still point to gitlab's external ip
``` 
