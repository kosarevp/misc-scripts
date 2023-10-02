using module '.\vbr-rest-reachability-check.psm1'

function DisableSSLVerification() {
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}    

function WaitForReachability($VBRHost, [int]$Wait=10) {
    $VBR = [VBRRESTAPI]::New($VBRHost)
    
    WriteLog -Message ('Waiting for VeeamRESTSvc @ ' + $VBR.Address + '...') -Severity Information
    while ($true) {

        if ($VBR.checkReachability()) {
            WriteLog -Message ('Got a response from VeeamRESTSvc @ ' + $VBR.Address + '...') -Severity Information
            break
        } else {
            Start-Sleep -Seconds $Wait
        }
    }
}

function ProcessRESTAPITasks() {
    DisableSSLVerification
    WaitForReachability('someVBRhost')
}
