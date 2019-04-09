z.ps
====

This little tool lets you jump directly to your frequently used directories in PowerShell.

![Screenshot](https://user-images.githubusercontent.com/704336/55840577-280add00-5b2c-11e9-9c0e-8b4e8189fe13.png)


Installation
------------

 1. Start PowerShell

 2. `mkdir ~\Documents\WindowsPowerShell\Modules`
(skip this step if the directory already exists or if you want to install the module somewhere else in your `$Env:PSModulePath`)

 3. `cd ~\Documents\WindowsPowerShell\Modules`

 4. `git clone https://github.com/JannesMeyer/z.ps.git z`

 5. Include these lines in your `Profile.ps1` (usually located in `~\Documents\WindowsPowerShell`)

		Import-Module z
		Set-Alias z Search-NavigationHistory

		function Prompt {
			Update-NavigationHistory $pwd.Path
		}


Instead of step 4 you can also create a link:

	cmd /c mklink /d z [Path to z.ps]


Usage
-----

Just cd around for a while to let the tool learn your directories.

Then you can use it as follows.

	z asd   # (where 'asd' is part of your desired location's path name)

You can also see a list of all matches before going there.

	z -l asd

Furthermore, you can change the sort algorithm to prioritize recent locations, for example. (The default priorization is a combination of frequency and recency.)

	z -l -s recent asd

The full output of `Get-Help z` looks like this:

	z [[-Patterns] <string>] [-List] [-SortOrder <string> {Default | Recent | Frequent}]  [<CommonParameters>]


License
-------

WTFPL

This program is free software. It comes without any warranty, to the extent permitted by applicable law. You can redistribute it and/or modify it under the terms of the Do What The Fuck You Want To Public License, Version 2, as published by Sam Hocevar. See http://sam.zoy.org/wtfpl/COPYING for more details.


Planned
-------

Make module installation easier using http://psget.net/ or https://www.powershellgallery.com/
