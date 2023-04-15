$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$GooseFolder = $env:QUARK
$BinDir = if ($GooseFolder) {
  "$GooseFolder"
} else {
  "$Home\.goose"
}

$Target = 'windows'
$GooseZip = "$BinDir\goose_$Target.zip"
$GooseExe = "$BinDir\goose.exe"

# GitHub requires TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$GooseUri = "https://github.com/goose-language/goose/releases/latest/download/goose_${Target}.zip"
$releases = "https://api.github.com/repos/goose-language/goose/releases"

Write-Host -NoNewline "* Searching a release..."
$tag = (Invoke-WebRequest $releases | ConvertFrom-Json)[0].tag_name
Write-Output " found '$tag'"

Write-Output "* Installing Goose $tag to $BinDir (this may take a few seconds)"


if (!(Test-Path $BinDir)) {
  New-Item $BinDir -ItemType Directory | Out-Null
}
Write-Host -NoNewline "* Downloading the latest Goose release archive... "
Invoke-WebRequest $GooseUri -OutFile $GooseZip -UseBasicParsing
Write-Host -ForegroundColor Green "done"

Write-Host -NoNewline "* Deflating archive... "
if (Get-Command Expand-Archive -ErrorAction SilentlyContinue) {
  Expand-Archive $GooseZip -Destination $BinDir -Force
} else {
  if (Test-Path $GooseExe) {
    Remove-Item $GooseExe
  }
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  [IO.Compression.ZipFile]::ExtractToDirectory($GooseZip, $BinDir)
}
Write-Host -ForegroundColor Green "done"

Write-Host -NoNewline "* Cleaning $BinDir directory... "
Remove-Item $GooseZip
Write-Host -ForegroundColor Green "done"
Write-Host ""

$User = [EnvironmentVariableTarget]::User
$Path = [Environment]::GetEnvironmentVariable('Path', $User)
if (!(";$Path;".ToLower() -like "*;$BinDir;*".ToLower())) {
  [Environment]::SetEnvironmentVariable('Path', "$Path;$BinDir", $User)
  $Env:Path += ";$BinDir"
  [Environment]::SetEnvironmentVariable('QUARK', "$BinDir", $User)
}

Write-Output "Goose was installed successfully to $GooseExe"
Write-Output "Run 'goose --help' to get started"