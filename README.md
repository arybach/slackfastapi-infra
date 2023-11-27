# Slackcutter Fastapi deployment

```
Requirements:

* terraform
* packer
* ansible
* kubectl
* yc cli
* helm

service_account_key_file, for example: "~/.ssh/yc_key.json"
yc_token (yandex cloud token)
cloud_id (payment account id from yandex console)
folder_id (project's folder id from yandex console)
+ additional parameters in terraform.tfvars (for example):
    zone                     = "ru-central1-a"
    app_count                = 1
    app_disk_image           = "fd80bm0rh4rkepi5ksdi" # ubuntu 22.04 (default)
    db_disk_image            = "fd80bm0rh4rkepi5ksdi" # ubuntu 22.04 (default)
    bucket_name              = "slackcutter" (should be unique and hopefully related to project name)
    k8s                      = "1.25" # kubernetes version (1.23-1.27 are currently supported by yandex
```

### deploy resource to yandex cloud - using this https://github.com/sport24ru/terraform-yandex-managed-kubernetes.git repo as a source (many cudos)
```
cd terraform
cd packer
packer build gitlab-packer.json

==> Builds finished. The artifacts of successful builds are:
--> yandex: A disk image was created: gitlab-image-1696773313 (id: fd8hpf4oehb30fg92bbs) with family name gitlab-image

cd ..
terraform init
terraform apply -var-file=terraform.tfvars

terraform output -json > ../ansible/terraform-outputs.json
cd ../ansible
ansible-playbook fetch-creds.yml

# check compatibility of k8s version with argo helm version and argo workflows 
# https://argoproj.github.io/argo-workflows/releases/#supported-versions
# enable yandex container registry (if not enabled) by running:
ansible-playbook setup-ecr.yml

# setup storage bucket, sa and secret keys for it
ansible-playbook bucket.yml

# output - save YC_ACCESS_KEY and YC_SECRET_KEY for later use
TASK [Display Access Key and Secret Key] ***************************************************************************************************************
ok: [localhost] => {
    "api_key_result.stdout_lines": [
        "access_key:",
        "  id: ajekj0478hul3hi0dtkf",
        "  service_account_id: aje9gq10irqrdh67jloj",
        "  created_at: \"2023-10-12T06:42:33.240644436Z\"",
        "  key_id: YCAJEhR6wwvdYJU25ZhP_dWVu",
        "secret: YCMjMVgIIdd3Hx7iPZFi285JVHJtP9jE5G_1H4F6"
    ]
}

# then deploy yandex helm chart for argocd:
ansible-playbook argo.yml -K

# check:
>> argo version
argo: v3.4.11

>> kubectl get pods -n argo
NAME                                                       READY   STATUS    RESTARTS   AGE
argo-cd-argocd-application-controller-0                    1/1     Running   0          1m
argo-cd-argocd-applicationset-controller-b775d4f79-2kmmq   1/1     Running   0          1m
argo-cd-argocd-dex-server-784db56879-bj8pp                 1/1     Running   0          1m
argo-cd-argocd-notifications-controller-7f59c6768d-p5tpz   1/1     Running   0          1m
argo-cd-argocd-redis-d786d58b8-7hd4c                       1/1     Running   0          1m
argo-cd-argocd-repo-server-7466896d8b-gtfpj                1/1     Running   0          1m
argo-cd-argocd-server-5c9fdb56f7-lq2r4                     1/1     Running   0          1m

# fetch argo password (for user admin):
kubectl -n argo get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# login to argo @ localhost:8080
``` 
### in case of any issues of configuring kubectl with ansible - bewlo are yc cli commands to get kubeconfig
``` 
[0] % yc managed-kubernetes cluster get-credentials --id cat5pm44c69jtdc5omhb --external

Context 'yc-slack-k8s' was added as default to kubeconfig '/home/groot/.kube/config'.
Check connection to cluster using 'kubectl cluster-info --kubeconfig /home/groot/.kube/config'.

Note, that authentication depends on 'yc' and its config profile 'default'.
To access clusters using the Kubernetes API, please use Kubernetes Service Account.
``` 
kubectl config use-context yc-slack-k8s

### deploy argo app
```
tar -xvzf slackfastapi-master.tar.gz

# to speed up gitlab commits i moved the trained models to yandex bucket (and added trained_models to .gitignore):
cd ../ansible
# update YC_SECRET_ACCESS_KEY and YC_SECRET_KEY_ID and run upload_models.yml
ansible-playbook upload_models.yml 

# commit slackfastapi-master to gitlab deployed on yandex vm with terraform
cd slackfastapi-master
1. login into gitlab @ http://<your-gitlab-ip> (see terraform output)
2. change password for root user
3. create new project (slackfastapi)

![Alt text](image.png)

4. set git config for root user: 
git config --global user.name "Ubuntu"
git config --global user.email "mats.tumblebuns@gmail.com"

5. push initial commit to gitlab (copy instructions from gitlab prompts):
git init --initial-branch=main
git remote add origin http://158.160.117.44/gitlab-instance-59a861b7/slackfastapi.git

# if need to change remote url:
# git remote set-url origin http://158.160.117.44/gitlab-instance-354fd35a/slackfastapi.git

# create access token glpat-tCe-Up4tBUM1yHvbzBNQ, then use its name + token
git remote set-url origin http://slackfast:glpat-tCe-Up4tBUM1yHvbzBNQ@158.160.117.44/gitlab-instance-354fd35a/slackfastapi.git

git add .
git commit -m "slackfastapi v1 commit"
git push -u origin main

argocd app create slackfastapi-app \
  --repo <your-git-repo-url> \
  --path <directory-containing-kube-manifests> \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace slack-fastapi