#Requires -Version 5.1

class EMRESTAPI {
    [string]$Address
    [int]$Port = 9398
    [string]$Uri
    [bool]$isReachable
    [string]$isReachableTimestamp
    [string]$AuthToken
    [string]$XRestSvcSessionId
    [string]$SessionId

    EMRESTAPI([string]$Address) {
        $this.Address = $Address
        $this.genUri()
        $this.checkReachability()
    }

    EMRESTAPI([string]$Address, [int]$Port) {
        $this.Address = $Address
        $this.Port = $Port
        $this.genUri()
        $this.checkReachability()
    }

    [void]genUri() {
        $this.Uri = ('https://' + $this.Address + ':' + $this.Port + '/api/')
    }

    [bool]checkReachability() {
        try {
            $r = Invoke-WebRequest -Uri ($this.Uri) -Method Get -TimeoutSec 5
            if ($r.StatusCode -eq 200) {
                $reachable = $true
            } else {
                $reachable = $false
            }
        } catch {
            $reachable = $false
        }

        $timestamp = Get-Date -Format yyyy-MM-ddTHH:mm:ss.ffffK
        $this.isReachable = $reachable
        $this.isReachableTimestamp = $timestamp

        return $reachable
    }

    [void]auth([string]$Username, [string]$Password) {
        $pair = [string]::Format("{0}:{1}", $Username, $Password)
        $this.AuthToken = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($pair))

        $headers = @{
            'Authorization' = 'Basic ' + $this.AuthToken
            'Content-Type' = 'application/json'
        }

        $r = Invoke-WebRequest -Uri ($this.Uri + 'sessionMngr/?v=latest') -Method Post -Headers $headers
        $this.XRestSvcSessionId = $r.Headers.'X-RestSvcSessionId'
        $this.SessionId = ($r.Content | ConvertFrom-Json).SessionId
    }

    [void]logOut() {
        $headers = @{
            'X-RestSvcSessionId' = $this.XRestSvcSessionId
            'Content-Type' = 'application/json'
        }
        Invoke-RestMethod -Uri ($this.Uri + 'logonSessions/' + $this.SessionId) -Method Delete -Headers $headers
    }

    [void]addBackupServer([string]$Address, [int]$Port, [string]$Username, [string]$Password, [string]$Description) {
        $headers = @{
            'X-RestSvcSessionId' = $this.XRestSvcSessionId
            'Content-Type' = 'application/json'
        }

        $body = @{
            'Description' = $Description
            'DnsNameOrIpAddress' = $Address
            'Port' = $Port
            'Username' = $Username
            'Password' = $Password
        } | ConvertTo-Json

        Invoke-RestMethod -Uri ($this.Uri + 'backupServers?action=create') -Method Post -Headers $headers -Body $body
    }
}

# DisableSSLVerification
# $VBRHost = 'veeam-vbr10.veeam.demo'
# $EM = [EMRESTAPI]::new($VBRHost)
# $EM.auth('veeamlab\administrator', 'P@ssw0rd')
# $EM.addBackupServer($VBRHost, '9392', 'veeamlab\administrator', 'P@ssw0rd', '')
# $EM.logOut()
