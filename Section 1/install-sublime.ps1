$ArchiveFile = 'Sublime Text Build 203126 x64.zip'
Invoke-WebRequest -Uri 'https://download.sublimetext.com/Sublime%20Text%20Build%203126%20x64.zip' `
	-OutFile $ArchiveFile
$TargetDir = "$env:LOCALAPPDATA\Programs\Sublime Text 3"
mkdir $TargetDir
Expand-Archive -Path $ArchiveFile -DestinationPath $TargetDir
[Environment]::SetEnvironmentVariable("PATH", "$env:Path;$TargetDir", "User")
Remove-Item -Path $ArchiveFile