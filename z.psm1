#
# PowerShell port of z.sh
#

$dbfile = "$env:UserProfile\navdb.csv"

# Execution time:
# Measure-Command { Update-NavigationHistory $pwd.Path }

function Calculate-FrecencyValue() {
	Param([Int64]$Frequency, [Int64]$LastAccess)

	$now = [DateTime]::UtcNow
	$last = [DateTime]::FromFileTimeUtc($LastAccess)
	$factor = switch($last) {
		{$_.AddHours(1) -gt $now} { 4; break }
		{$_.AddDays(1) -gt $now}  { 2; break }
		{$_.AddDays(7) -gt $now}  { 1/2; break }
		default                   { 1/4 }
	}
	return $factor * $Frequency
}

function MatchAll-Patterns() {
	Param([String]$string, [Array][String]$patterns)
	
	foreach ($pattern in $patterns) {
		if ($string -notmatch $pattern) {
			return $false
		}
	}
	return $true
}

function Update-NavigationHistory() {
	#[CmdletBinding()]
	Param(
		[parameter(Mandatory=$true)]
		[String]
		$Path
	)

	# Abort if we got $HOME
	if ($Path -eq $HOME) {
		return
	}

	# Import database
	try {
		[Array]$navdb = @(Import-Csv $dbfile -Encoding 'Unicode')
	} catch [System.IO.FileNotFoundException] {
		[Array]$navdb = @()
	}
	
	# Look for an existing record and update it accordingly
	$found = $false
	foreach ($item in $navdb) {
		# Filter out all directories that don't exist
		<# Test-Path is a little slow
		if (!(Test-Path $item.Path)) {
			# TODO: Delete item
			continue
		}#>

		# Update Frequency and LastAccess time
		if ($item.Path -eq $Path) {
			$found = $true
			++[Int64]$item.Frequency
			$item.LastAccess = [DateTime]::Now.ToFileTimeUtc()
		}
	}
	# Nothing found
	if (!$found) {
		# Create new object
		$navdb += [PSCustomObject]@{
			Path = $Path
			Frequency = 1
			LastAccess = [DateTime]::Now.ToFileTimeUtc()
		}
		# TODO: Append only one item instead of rewriting the whole file?
	}

	# TODO: Age the complete database if the compound score is above 1000
	#$navdb | Measure-Object -Sum Frequency
	#if ($navdb.Count -gt 1000) {}

	# Save database
	try {
		$navdb | Export-Csv -Path $dbfile -NoTypeInformation -Encoding 'Unicode'
	} catch {
		Write-Output $_.Exception.Message
	}
}

function Search-NavigationHistory() {
	Param(
		[parameter(ValueFromRemainingArguments=$true, ValueFromPipeline=$true, Position=0)]
		[String]
		$Patterns,

		[Switch]
		$List,

		[ValidateSet('Default', 'Recent', 'Frequent')]
		[String]
		$SortOrder='Default'
	)

	if ([String]::IsNullOrEmpty($Patterns)) {
		# No search terms given, list everything
		$List = $true
		[Array]$PatternList = @()
	} else {
		# Convert search terms to Array
		[Array]$PatternList = $Patterns.Split()
	}

	# Import database
	try {
		[Array]$navdb = Import-Csv $dbfile -Encoding 'Unicode'
		$navdb | Add-Member -MemberType NoteProperty -Name 'Rank' -Value 0
	} catch [System.IO.FileNotFoundException] {
		Write-Output $_.Exception.Message
	}

	# Create a non-fixed-size Array
	$candidates = New-Object System.Collections.ArrayList
	# Iterate over every entry in the file
	foreach ($item in $navdb) {
		# Ignore this item, if the path doesn't exist
		if (!(Test-Path $item.Path)) {
			continue
		}
		# Enhance item with Rank
		$item.Frequency = [Int64]($item.Frequency)
		$item.LastAccess = [Int64]($item.LastAccess)
		$item.Rank = switch($SortOrder) {
			'Frequent' { $item.Frequency }
			'Recent'   { $item.LastAccess }
			default    { Calculate-FrecencyValue $item.Frequency $item.LastAccess }
		}
		# Match
		if (MatchAll-Patterns $item.Path $PatternList) {
			$candidates.Add($item) | Out-Null
		}
	}
	# Nothing found
	if (!$candidates) {
		return 'No matches found'
	}

	if ($List) {
		# Display the first 20 results
		$candidates | Sort-Object -Descending Rank | Select-Object Path, Rank -First 20
	} else {
		# Change directory
		$winner = $candidates | Sort-Object -Descending Rank | Select-Object -First 1
		Set-Location $winner.Path
	}
}

Export-ModuleMember -Function Update-NavigationHistory, Search-NavigationHistory