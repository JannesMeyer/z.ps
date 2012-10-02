@{
	ModuleVersion = '1.0'
	Author = 'Jannes Meyer'
	Description = 'Jump to your favorite directories'
	Copyright  =  'Public domain'

	ModuleToProcess = 'z.psm1'
	FunctionsToExport = @('Update-NavigationHistory', 'Search-NavigationHistory', 'Optimize-NavigationHistory')
}