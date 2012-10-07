Installation
============

 1. Start PowerShell

 2. `mkdir ~\Documents\WindowsPowerShell\Modules`
(skip this step if the directory already exists)

 3. `cd ~\Documents\WindowsPowerShell\Modules`

 4. Download z.ps

    `git clone https://github.com/JannesMeyer/z.ps.git z`

 5. Include this in your `~\Documents\WindowsPowerShell\profile.ps1` (or create a new one if the file doesn't exist yet)

		Import-Module z
		Set-Alias z Search-NavigationHistory
		function Prompt {
			Update-NavigationHistory $pwd.Path
		}


License
=======

WTFPL

This program is free software. It comes without any warranty, to the extent permitted by applicable law. You can redistribute it and/or modify it under the terms of the Do What The Fuck You Want To Public License, Version 2, as published by Sam Hocevar. See http://sam.zoy.org/wtfpl/COPYING for more details.


Planned
=======

Make module installation easier using http://psget.net/