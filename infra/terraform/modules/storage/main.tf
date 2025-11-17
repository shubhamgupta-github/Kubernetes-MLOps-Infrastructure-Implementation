resource "null_resource" "install_minio" {
    provisioner "local-exec" {
    command = "powershell.exe -ExecutionPolicy Bypass -File ${path.module}\\install-minio.ps1 -ChartPath ${path.root}\\charts\\minio"

    }
}
