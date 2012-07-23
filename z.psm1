#
# Port of z.sh to PowerShell
#


$dbfile = "$env:UserProfile\NavigationDatabase.csv"

function Update-NavigationHistory() {
	Param(
        [parameter(Mandatory=$true, ValueFromRemainingArguments=$true, ValueFromPipeline=$true)]
		[string]
        $Path
    )

    # Load database
    try {
        # TODO: Check if we own the file
	    $navdb = Import-CSV $dbfile
    } catch [System.IO.FileNotFoundException] {
        # Database file doesn't exist yet
        #$_.Exception.Message

    }


	# Get a temporary file
	#[System.IO.Path]::GetTempFileName()
	#[IO.Path]::GetTempFileName()
}

function Calculate-Frecent() {
    Param([double]$Frequency, [int64]$LastAccess)

    #$now = (Get-Date).ToFileTimeUtc()
    $now = [int32][double]::Parse((Get-Date (Get-Date).ToUniversalTime() -UFormat %s))
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
        return $_.Exception.Message
    }

    # Create a non-fixed Array
    $candidates = New-Object System.Collections.ArrayList
    # Iterate over every entry in the file
    foreach ($item in $navdb) {
        # Ignore this item, if the path doesn't exist
        if (-not (Test-Path $item.Path)) {
            continue # TODO: Delete item (when updating)
        }
        # Enhance item with Rank
        [double]$item.Rank = switch($SortOrder) {
            "Frequency"  { $item.Frequency }
            "LastAccess" { $item.LastAccess }
            default      { Calculate-Frecent $item.Frequency $item.LastAccess }
        }
        # Must match all patterns
        if (Match-Patterns $item.Path $PatternList) {
            $candidates.Add($item) | Out-Null
        }
    }
    if (!$candidates) {
        return "No matches found"
    }
    # Display/Go to the result
    if ($List) {
        $candidates | Sort-Object -Descending Rank | Format-Table -Property Path, Rank
        #$candidates | Select-Object -Property Path, Rank | Sort-Object -Descending Rank | Out-GridView
    } else {
        $result = $candidates | Sort-Object -Descending Rank | Select-Object -First 1
        Set-Location $result.Path
    }
}
Set-Alias z Search-NavigationHistory


#z ja -s Frequency -l

# Existing entry
#Update-NavigationHistory "C:\Users\Jannes\web\citytagger"

# New Entry
Update-NavigationHistory "C:\Users\Jannes\jngl-py"

Export-ModuleMember -Function Update-NavigationHistory, Search-NavigationHistory