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
		$Terms,

		[Switch]
		$List,

		[ValidateSet("Default", "LastAccess", "Frequency")]
		[string]
		$SortOrder="Default"
	)

    <#if (!(Test-Path $dbfile)) {
        # No database exists yet
        # TODO: Exception
        Write-Error "Database file doesn't exist yet"
        return
    } else {
        # TODO: Check if we own the file
    }#>

	if ([string]::IsNullOrEmpty($Terms)) {
        # No search terms given, list everything
		$List = $true
        $TermList = @()
	} else {
        # Convert search terms to Array
        $TermList = $Terms.Split()
    }

    # DEBUG:
    #Write-Host ""
	#Write-Host "Search terms:" $TermList
	#Write-Host "List:" $List
	#Write-Host "SortOrder:" $SortOrder
    #Write-Host ""

	# Load database
    try {
	    $navdb = Import-CSV $dbfile
        $navdb | Add-Member -MemberType NoteProperty -Name 'Rank' -Value 0
    } catch [System.IO.FileNotFoundException] {
        # No database exists yet
        Write-Host $_.Exception.Message
        return
    }

    #$candidates = @()
    # Create a non-fixed Array
    $candidates = New-Object System.Collections.ArrayList

    foreach ($item in $navdb) {
        # Just ignore the entry if the path doesn't exist
        if (-not (Test-Path $item.Path)) {
            # TODO: Delete item (only when adding)
            continue
        }

        # Populate rank hash tables
        $item.Rank = switch($SortOrder) {
            "Frequency"  { [double]$item.Frequency }
            "LastAccess" { [double]$item.LastAccess }
            default      { Calculate-Frecent [double]$item.Frequency [double]$item.LastAccess }
        }
        #$candidates += $item
        
        
        # Path must match all of the terms,
        # so remove if it doesn't match one of them
        if (Match-Patterns $item.Path $TermList) {
            $candidates.Add($item)
        }
        #foreach ($term in $TermList) {
        #    if ($item.Path -notmatch $term) {
        #        #get-member -InputObject $candidates
        #        $candidates.RemoveAt($candidates.Count - 1)
        #        #$last = $candidates.Length - 2
        #        #$candidates = $candidates[0..$last]
        #        break
        #    }
        #}
    }
    #$candidates | Measure-Object -Maximum Rank
    
    #$candidates | Select-Object -Property Path, Rank | Sort-Object -Descending Rank | Out-GridView
    $candidates | Sort-Object -Descending Rank | Format-Table -Property Path, Rank
    #$wcase2 = $wcase.GetEnumerator() | sort Value -Descending | select -First 1
    #$nocase2 = $nocase.GetEnumerator() | sort Value -Descending | select -First 1

    #if ($wcase2) {
    #    "Case-sensitive match:"
    #    $wcase2
    #} elseif ($nocase2) {
    #    "Case-insensitive match:"
    #    $nocase2
    #}
}
Set-Alias z Search-NavigationHistory


z ja -SortOrder Frequency