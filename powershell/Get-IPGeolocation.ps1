param (
	[Parameter(Mandatory=$true)]
	[string]$ip
)

function GetIPGeolocation_ipinfo() {

    param($ipaddress)

    $resource = "https://ipinfo.io/$ipaddress/geo"
    try {
        # $geoip = curl -fsSL https://ipinfo.io/$TargetIP/geo | ConvertFrom-Json
        $geoip = Invoke-RestMethod -Method Get -URI $resource
    } catch {
        Write-Verbose -Message "Catched an error"
        $PSCmdlet.ThrowTerminatingError($PSitem)
    }

    # $geoip | Get-Member
    $hash = @{
        IP = $geoip.ip
        Country = $geoip.country
        Region = $geoip.region
        City = $geoip.city
        TimeZone = $geoip.timezone
        ZipCode = $geoip.postal
        Loc = $geoip.loc
        }

    $result = New-Object PSObject -Property $hash

    return $result
}

function GetIPGeolocation() {

    param($ipaddress)

    $resource = "http://ip-api.com/json/$ipaddress"
    try {
        $geoip = Invoke-RestMethod -Method Get -URI $resource
    } catch {
        Write-Verbose -Message "Catched an error"
        $PSCmdlet.ThrowTerminatingError($PSitem)
    }

    # $geoip | Get-Member
    $hash = @{
        IP = $geoip.query
        CountryCode = $geoip.countryCode
        Country = $geoip.country
        Region = $geoip.region
        RegionName = $geoip.regionName
        AS = $geoip.as
        ISP = $geoip.isp
        ORG = $geoip.org
        City = $geoip.city
        ZipCode = $geoip.zip
        TimeZone = $geoip.timezone
        Latitude = $geoip.lat
        Longitude = $geoip.lon
        }

    $result = New-Object PSObject -Property $hash

    return $result
}

function GetIPGeolocation_ipstack() {

    param($ipaddress)

    $resource = "http://api.ipstack.com/$ipaddress"

    $access_key = Read-Host 'Access key for ipstack? '
    $body = @{
        "access_key" = "$access_key"
        }

    $geoip = Invoke-RestMethod -Method Get -URI $resource -Body $body

    # $geoip | Get-Member
    $hash = @{
        IP = $geoip.ip
        ContinentCode = $geoip.continent_code
        ContinentName = $geoip.continent_name
        CountryCode = $geoip.country_code
        CountryName = $geoip.country_name
        RegionCode = $geoip.region_code
        RegionName = $geoip.region_name
        City = $geoip.city
        ZipCode = $geoip.zip
        Latitude = $geoip.latitude
        Longitude = $geoip.longitude
        }

    $result = New-Object PSObject -Property $hash

    return $result
}

GetIPGeolocation $ip