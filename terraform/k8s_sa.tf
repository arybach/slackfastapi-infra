resource "yandex_iam_service_account" "k8s-sa" {
  name = "k8s-backend"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s-admin" {
  folder_id = var.folder_id
  role      = "k8s.admin"
  member    = "serviceAccount:${yandex_iam_service_account.k8s-sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s-api-admin" {
  folder_id = var.folder_id
  role      = "k8s.cluster-api.cluster-admin"
  member    = "serviceAccount:${yandex_iam_service_account.k8s-sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "iam-sa-admin" {
  folder_id = var.folder_id
  role      = "iam.serviceAccounts.admin"
  member    = "serviceAccount:${yandex_iam_service_account.k8s-sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "iam-ecr-puller" {
  folder_id = var.folder_id
  role      = "container-registry.images.puller"
  member    = "serviceAccount:${yandex_iam_service_account.k8s-sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "iam-alb-editor" {
  folder_id = var.folder_id
  role      = "alb.editor"
  member    = "serviceAccount:${yandex_iam_service_account.k8s-sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "iam-vpc-publicAdmin" {
  folder_id = var.folder_id
  role      = "vpc.publicAdmin"
  member    = "serviceAccount:${yandex_iam_service_account.k8s-sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "iam-vpc-sgAdmin" {
  folder_id = var.folder_id
  role      = "vpc.securityGroups.admin"
  member    = "serviceAccount:${yandex_iam_service_account.k8s-sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "iam-dns-editor" {
  folder_id = var.folder_id
  role      = "dns.editor"
  member    = "serviceAccount:${yandex_iam_service_account.k8s-sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "iam-storage-admin" {
  folder_id = var.folder_id
  role      = "storage.admin"
  member    = "serviceAccount:${yandex_iam_service_account.k8s-sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "iam-certs-downloader" {
  folder_id = var.folder_id
  role      = "certificate-manager.certificates.downloader"
  member    = "serviceAccount:${yandex_iam_service_account.k8s-sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "iam-lb-admin" {
  folder_id = var.folder_id
  role      = "load-balancer.admin"
  member    = "serviceAccount:${yandex_iam_service_account.k8s-sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "iam-alb-admin" {
  folder_id = var.folder_id
  role      = "alb.admin"
  member    = "serviceAccount:${yandex_iam_service_account.k8s-sa.id}"
}

resource "yandex_iam_service_account_key" "k8s_sa_key" {
  service_account_id = yandex_iam_service_account.k8s-sa.id
  description        = "Key for k8s service account"
  format             = "PEM_FILE"
}

resource "local_file" "k8s_sa_key_file" {
  content  = yandex_iam_service_account_key.k8s_sa_key.private_key
  filename = "/home/groot/.ssh/k8s-sa-key.pem"
}

# Folder-level roles:
# admin
# iam.admin
# iam.serviceAccounts.admin
# k8s.admin
# k8s.cluster-api.cluster-admin
# storage.admin
# load-balancer.admin
