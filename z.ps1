<#
Port of z.sh to PowerShell
#>

$dbfile = "$env:UserProfile\NavigationDatabase.csv"

function Update-NavigationHistory() {
	Param($Path)

    # TODO: Check if we own the file

	$navdb = Import-CSV "$env:UserProfile\NavigationDatabase.csv"
	#$navdb | ? { $_.Path -eq $Path }


	# Get a temporary file
	#[System.IO.Path]::GetTempFileName()
	#[IO.Path]::GetTempFileName()
}

function Calculate-Frecent() {
    Param($Frequency, $LastAccess)

    #$now = (Get-Date).ToFileTimeUtc()
    $now = [int][double]::Parse((Get-Date (Get-Date).ToUniversalTime() -UFormat %s))
    $dt = $now - $LastAccess

    if ($dt -lt 3600) {
        return $Frequency * 4
    } elseif ($dt -lt 86400) {
        return $Frequency * 2
    } elseif ($dt -lt 604800) {
        return $Frequency / 2
    } else {
        return $Frequency / 4
    }
}

function Match-Patterns() {
    Param([string]$string, [Array][string]$patterns)
    
    foreach ($pattern in $patterns) {
        if ($string -notmatch $pattern) {
            return $false
        }
    }
    return $true
}

function Search-NavigationHistory() {
	#[CmdletBinding(DefaultParameterSetName="Path")]
	Param(
		[parameter(ValueFromRemainingArguments=$true, ValueFromPipeline=$true, Position=0)]
		[string]
		$Patterns,

		[Switch]
		$List,

		[ValidateSet("Default", "LastAccess", "Frequency")]
		[string]
		$SortOrder="Frequency"
	)

	if ([string]::IsNullOrEmpty($Patterns)) {
        # No search terms given, list everything
		$List = $true
        $PatternList = @()
	} else {
        # Convert search terms to Array
        $PatternList = $Patterns.Split()
    }

	# Load database
    try {
        # TODO: Check if we own the file. Lol why?
	    $navdb = Import-CSV $dbfile
        $navdb | Add-Member -MemberType NoteProperty -Name 'Rank' -Value 0
    } catch [System.IO.FileNotFoundException] {
        # TODO: Exception?
        # Database file doesn't exist yet
        Write-Host $_.Exception.Message
        return
    }

    # Create a non-fixed Array
    $candidates = New-Object System.Collections.ArrayList
    # Iterate over every entry in the file
    foreach ($item in $navdb) {
        # Ignore this item, if the path doesn't exist
        if (-not (Test-Path $item.Path)) {
            continue # TODO: Delete item (when updating)
        }

        # Populate rank
        $item.Rank = switch($SortOrder) {
            "Frequency"  { [double]$item.Frequency }
            "LastAccess" { [double]$item.LastAccess }
            default      { Calculate-Frecent [double]$item.Frequency [double]$item.LastAccess }
        }
        # Must match all patterns
        if (Match-Patterns $item.Path $PatternList) {
            $candidates.Add($item) | Out-Null
        }
    }
    #$hashtable.GetEnumerator() | sort Value -Descending | select -First 1
    #$candidates | Measure-Object -Maximum Rank
    #$candidates | Select-Object -Property Path, Rank | Sort-Object -Descending Rank | Out-GridView
    if ($List) {
        $candidates | Sort-Object -Descending Rank | Format-Table -Property Path, Rank
    } else {
        $result = $candidates | Sort-Object -Descending Rank | Select-Object -First 1
        Set-Location $result.Path
    }
}
Set-Alias z Search-NavigationHistory


z ja -s Frequency -l