param(
[string]$rancher_server_ip = "172.22.101.101", 
[string]$admin_password = "admin", 
[string]$cluster_name = "quickstart"
)

if (-not ([System.Management.Automation.PSTypeName]'ServerCertificateValidationCallback').Type)
{
$certCallback = @"
    using System;
    using System.Net;
    using System.Net.Security;
    using System.Security.Cryptography.X509Certificates;
    public class ServerCertificateValidationCallback
    {
        public static void Ignore()
        {
            if(ServicePointManager.ServerCertificateValidationCallback ==null)
            {
                ServicePointManager.ServerCertificateValidationCallback += 
                    delegate
                    (
                        Object obj, 
                        X509Certificate certificate, 
                        X509Chain chain, 
                        SslPolicyErrors errors
                    )
                    {
                        return true;
                    };
            }
        }
    }
"@
    Add-Type $certCallback
 }
[ServerCertificateValidationCallback]::Ignore()

$loginresponse=Invoke-RestMethod -Uri "https://$rancher_server_ip/v3-public/localProviders/local?action=login" -ContentType "application/json" -Headers @{"Accept"= "application/json"} -Body "{""username"":""admin"",""password"":""$admin_password""}" -Method Post
$token=$loginresponse.token

$cluster_info=Invoke-RestMethod -Headers @{"Authorization"= "Bearer $token"; "Accept"= "application/json"} "https://$rancher_server_ip/v3/clusters?name=$cluster_name"
$cluster_id=$cluster_info.data.id


$clusterregistration=Invoke-RestMethod -Headers @{"Authorization"= "Bearer $token"; "Accept"= "application/json"} "https://$rancher_server_ip/v3/clusterregistrationtoken?clusterId=$cluster_id"

$nodeCommand=$clusterregistration.data[0].windowsNodeCommand

Invoke-Expression -Command $nodeCommand