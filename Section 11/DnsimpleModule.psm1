
class DnsimpleClientV2 {
    hidden [string]$accessToken
    hidden [int]$account

    DnsimpleClientV2([string]$at, [int]$acc) {
        $this.accessToken = $at
        $this.account = $acc
    }

    [ZoneRecord[]] GetZoneRecords([string] $zone) {
        return [ZoneRecord[]](Invoke-RestMethod -Method GET `
            -Uri "https://api.dnsimple.com/v2/$($this.account)/zones/$zone/records" `
            -Headers @{'Authorization'="Bearer $($this.AccessToken)"} `
            -ContentType 'application/json' `
        | Select-Object -ExpandProperty data)
    }
}

class ZoneRecord {
        [int] $id 
        [string] $zone_id 
        [string] $parent_id 
        [string] $name 
        [string] $content 
        [int] $ttl 
        [int] $priority 
        [string] $type 
        [string[]] $regions 
        [bool] $system_record 
        [datetime] $created_at 
        [datetime] $updated_at
}