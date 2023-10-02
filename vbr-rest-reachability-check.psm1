#Requires -Version 5.1

class VBRRESTAPI {

    [string]$Address
    [int]$Port = 9419
    [string]$Uri
    [bool]$isReachable
    [string]$isReachableTimestamp
    [string]$AccessToken
    [string]$RefreshToken

    VBRRESTAPI([string]$Address) {
        $this.Address = $Address
        $this.genUri()
        $this.checkReachability()
    }

    VBRRESTAPI([string]$Address, [int]$Port) {
        $this.Address = $Address
        $this.Port = $Port
        $this.genUri()
        $this.checkReachability()
    }

    [void]genUri() {
        $this.Uri = ('https://' + $this.Address + ':' + $this.Port + '/api')
    }

    [bool]checkReachability() {
        $headers = @{
            'Content-Type' = 'application/json'
            'x-api-version' = '1.0-rev1'
        }
        
        try {
            $response = Invoke-WebRequest -Uri ($this.Uri + '/v1/serverTime') -Method Get -Headers $headers -TimeoutSec 2
            if ($response.StatusCode -eq 200) {
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
        $headers = @{
            'Content-Type' = 'application/json'
            'x-api-version' = '1.0-rev1'
        }
        $body = @{
            'grant_type' = 'password'
            'username' = $Username
            'password' = $Password
        } | ConvertTo-Json

        $response = Invoke-RestMethod -Uri ($this.Uri + '/oauth2/token') -Method Post -Headers $headers -Body $body
        $this.AccessToken = $response.access_token
        $this.RefreshToken = $response.refresh_token
    }

    [void]logOut() {
        $headers = @{
            'x-api-version' = '1.0-rev1'
            'Authorization' = 'bearer ' + $this.AccessToken
        }
        Invoke-RestMethod -Uri ($this.Uri + '/oauth2/logout') -Method Post -Headers $headers
    }
}
