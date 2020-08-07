if($isLinux -or $isMacOS){
    $PathToInvokeAtomicFolder = "~/AtomicRedTeam/invoke-atomicredteam/*.psd1"
    $errFile = "/tmp/art-err.txt"
    $outFile = "/tmp/art-out.txt"
}else{
    $PathToInvokeAtomicFolder = "C:\AtomicRedTeam\invoke-atomicredteam\Invoke-AtomicRedTeam.psd1"
    $errFile = "$env:Temp/art-err.txt"
    $outFile = "$env:Temp/art-out.txt"
    $PSDefaultParameterValues = @{"Invoke-AtomicTest:PathToAtomicsFolder"="C:\AtomicRedTeam\atomics"}
}


$PathToInvokeExecCmdFile = Join-Path -Path (Split-Path -Path $PathToInvokeAtomicFolder -Parent) -ChildPath "Private/Invoke-ExecuteCommand.ps1"

$char1 = '$res = Invoke-Process -filename $execExe -Arguments $arguments -TimeoutSeconds $TimeoutSeconds'
$char2 = '$res = Invoke-Process -filename $execExe -Arguments $arguments -TimeoutSeconds $TimeoutSeconds -stderrFile "art-err.txt" -stdoutFile "art-out.txt"'
# (Get-Content -Path $PathToInvokeExecCmdFile -Raw) -match [regex]::escape($char1)
((Get-Content -Path $PathToInvokeExecCmdFile -Raw) -replace [regex]::escape($char1),$char2) | Set-Content -Path $PathToInvokeExecCmdFile

Import-Module $PathToInvokeAtomicFolder -Force

$Tests = Import-CSV "./test.csv"

$FilePath = "./cleanup.csv"

if (Test-Path $FilePath){
    Remove-Item $FilePath
}

Add-Content -Path $FilePath -Value '"AtomicTest","AtomicName","Output","Error"'

foreach ($test in $Tests) {
    New-Item $errFile, $outFile | Out-Null
    Invoke-AtomicTest $test.Technique -TestNumbers $test.TestNumber
    $errorContent = Get-Content $errFile
    $outputContent = Get-Content $outFile
    if($outputContent -or $errorContent){
        Add-Content -Path $FilePath -Value "$($test.Technique), $($test.TestNumber), $outputContent, $errorContent"
    }
    Remove-Item $errFile, $outFile
}

((Get-Content -Path $PathToInvokeExecCmdFile -Raw) -replace [regex]::escape($char2),$char1) | Set-Content -Path $PathToInvokeExecCmdFile
