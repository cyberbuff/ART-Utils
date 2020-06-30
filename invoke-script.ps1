$PathToInvokeAtomicFolder = "/Users/0x6c/AtomicRedTeam/invoke-atomicredteam/*.psd1"
$errFile = "/tmp/art-err.txt"
$outFile = "/tmp/art-out.txt"

Import-Module $PathToInvokeAtomicFolder

$Tests = Import-CSV "./test.csv"

$FilePath = "./cleanup.csv"

if (Test-Path $FilePath){
    Remove-Item $FilePath
}

Add-Content -Path $FilePath -Value '"AtomicTest","AtomicName","Output","Error"'

foreach ($test in $Tests) {
    if($test.GetPreReqs -eq $test.CheckPreReqs){
        $res = Invoke-AtomicTest $test.AtomicTest -TestNames $test.AtomicName -Cleanup
        $errorContent = Get-Content $errFile
        $outputContent = Get-Content $outFile
        Add-Content -Path $FilePath -Value "$($test.AtomicTest), $($test.AtomicName), $outputContent, $errorContent"
        Write-Host $test.AtomicTest $res
        Remove-Item $errFile, $outFile
    }
}
