module "cluster" {
  source       = "./modules/cluster"
  cluster_name = var.cluster_name
}

module "storage" {
  source       = "./modules/storage"
}