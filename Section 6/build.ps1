
if (-not(get-command 'nuget' -ErrorAction 'silentlycontinue')) {
    scoop install nuget
}

$head,$null = dir -path 'C:\Program Files (x86)\' `
    -filter 'msbuild.exe' -Recurse `
    | select -expandproperty Fullname

$env:Path += ";$(split-path $head)"

$head,$null = = dir 'C:\Program Files (x86)\' -filter 'mstest.exe' `
    -Recurse | select -expandproperty fullname

$env:Path += ";$(split-path $head)"

pushd '.\contorso-with-tests\C#\'

nuget restore
if (-not($?)) {
    popd
    Exit 1
}

msbuild
if (-not($?)) {
    popd
    Exit 1
}

mstest /testcontainer:contosouniversity.tests\bin\debug\contosouniversity.tests.dll
if (-not($?)) {
    popd
    Exit 1
}

msbuild .\ContosoUniversity\ContosoUniversity.csproj /p:Configuration=Release /t:WebPublish /p:WebPublishMethod=FileSystem /p:DeleteExistingFiles=True /p:PublishUrl=..\_published
if (-not($?)) {
    popd
    Exit 1
}

Write-output "Build completed"
popd