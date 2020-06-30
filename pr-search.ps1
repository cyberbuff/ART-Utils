Import-Module powershell-yaml

$Files = Get-ChildItem -Path "/Users/0x6c/AtomicRedTeam/atomics/*/*.yaml" 

$FilePath = "./test.csv"
if (Test-Path $FilePath){
    Remove-Item $FilePath
}
Add-Content -Path $FilePath  -Value '"AtomicTest","AtomicName","GetPreReqs","CheckPreReqs"'

foreach ($item in $Files) {
    $content = Get-Content -Raw $item
    try {
        [Hashtable] $ParsedYaml = ConvertFrom-Yaml -Yaml $content
    } catch {
        Write-Error $_
    }
    $atomics = $ParsedYaml['atomic_tests']
    foreach ($test in $atomics){
        $executor = $test['executor']
        $dep_exec = $test['dependency_executor_name']
        $name = $executor['name']
        $command = $executor['command']
        $platform = $test['supported_platforms']
        $dependencies = $test['dependencies']
        $isWindowsPlatform = $platform -contains "windows"

        function isPowershell {$input -eq "powershell"}
        function isBash {$input -match "b?a?sh"}
        function commandSearch {$input -match '`"(.*?)`"'}

        function Compare-Command($executor, $command) {
            if($executor -eq "powershell"){
                $old_command = $command -replace "`"", "`\`"`""
                $new_command = $command -replace "[```"]", "`\$&"
                return ($old_command -ne $new_command)
            }elseif($executor -match "b?a?sh"){
                # $old-command = $command.Replace("`n", " & ")
                # $new-command = $command -replace "[\\`"]", "`\$&"
                # $new-command = $new-command -replace "(?<!;)\n", "; "
                # $old-command -not $new-command
                return $false
            }
        }

        $technique = $ParsedYaml['attack_technique']
        $technique_name = $test['name']

        if($(Compare-Command $name $command)){    
            Add-Content -Path $FilePath  -Value "$technique , $technique_name, $False, $False"
            Write-Host $technique  $technique_name
        }
        
        :loop1 foreach ($dep in $dependencies){
            if($(Compare-Command $dep_exec $dep['get_prereq_command'])){
                Write-Host "*" $technique  $technique_name
                Add-Content -Path $FilePath  -Value "$technique , $technique_name, $True, $False"
            }
            if($(Compare-Command $dep_exec $dep['prereq_command'])){
                Write-Host "*" $technique  $technique_name
                Add-Content -Path $FilePath  -Value "$technique , $technique_name, $False, $True"
            }
        }
    

        # if(($name | isPowershell) -and ($command | commandSearch) -and $isWindowsPlatform){
        #     Write-Host $ParsedYaml['attack_technique'] $test['name']
        # }else{
        #     :loop1 foreach ($dep in $dependencies){
        #         $dep_command = $dep['get_prereq_command'] + $dep['prereq_command']
        #         if(($dep_exec | isPowershell) -and ($dep_command | commandSearch) -and $isWindowsPlatform){
        #             Write-Host "$" $ParsedYaml['attack_technique'] $test['name']
        #             break loop1
        #         }
        #     }
        # }
    }
}
