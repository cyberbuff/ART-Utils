<#
.SYNOPSIS
    Filters specified Atomic test(s)
#>
function Filter-Atomic {
    [OutputType([PSCustomObject])]
    [CmdletBinding()]
    param
    (

        [Parameter(Mandatory = $false, Position = 0)]
        [String]$PathToAtomicsFolder = $(if ($IsLinux -or $IsMacOS) { "~/AtomicRedTeam/atomics/*/*.yaml" } else { "C:\AtomicRedTeam\atomics\*\*.yaml" }),

        [Parameter(Mandatory = $false, Position = 1)]
        [String]$Keyword = $null,
        
        [Parameter(Mandatory = $false, Position = 2)]
        [String]$Executor = $null,

        [Parameter(Mandatory = $false, Position =3)]
        [String]$Platform = $null,

        [Parameter(Mandatory = $false, Position =4)]
        [Switch]$RequireCleanup = $null,

        [Parameter(Mandatory = $false, Position =5)]
        [Switch]$RequiresElevation = $null,

        [Parameter(Mandatory = $false, Position =6)]
        [Switch]$RequiresDependencies = $null

    )

    end {

        Write-Host $PSBoundParameters
        $FilePath = "./test.csv"
        
        if(Test-Path $FilePath){
            Remove-Item $FilePath
        }
        
        Add-Content -Path $FilePath -Value 'Technique, TestNumber, TechniqueName, TestName, Executor, Platform, RequiresElevation, RequireCleanup, RequiresDependencies'

        $Files = Get-ChildItem -Path $PathToAtomicsFolder

        foreach ($item in $Files) {
            $content = Get-Content -Raw $item
            try {
                [Hashtable] $ParsedYaml = ConvertFrom-Yaml -Yaml $content
            } catch {
                Write-Error $_
            }

            $technique = $ParsedYaml['attack_technique']
            $technique_name = $ParsedYaml['display_name']
            $atomics = $ParsedYaml['atomic_tests']
            $index = 0
            foreach ($test in $atomics){
                $exec_object = $test['executor']
                # $dep_exec = $test['dependency_executor_name']
                # $exec_command = $exec_object['command']
                
                $atomic_dict = @{}
                $atomic_dict["Keyword"] = $technique_name + $test['name']
                $atomic_dict["Executor"] = $exec_object['name']
                $atomic_dict["Platform"] = $test['supported_platforms']
                $atomic_dict["RequiresElevation"] = ($exec_object['elevation_required'] -eq $true)
                $atomic_dict["RequireCleanup"] = ($exec_object['cleanup_command'] -ne $null)
                $atomic_dict["RequiresDependencies"] = ([regex]::escape($test["dependencies"]) -ne $null)
                
                $condition = $true

                foreach ($kv in $PSBoundParameters.GetEnumerator()){
                    if($kv.Key -eq "Executor"){
                        $condition = $condition -and ($atomic_dict[$kv.Key] -contains $kv.Value)
                    }elseif($kv.Value -is [String]){
                        $condition = $condition -and ($atomic_dict[$kv.Key] -imatch $kv.Value)
                    }elseif($kv.Value -is [Switch]){
                        $condition = $condition -and ($atomic_dict[$kv.Key])
                    }elseif($kv.value -is [Array]){
                        $condition = $condition -and ($(Compare-Object $atomic_dict[$kv.Key] $kv.Value -IncludeEqual -ExcludeDifferent).Count -eq $kv.Value.Count)
                    }
                }

                if($condition){
                    $test_name = $test['name'] -replace "," , ""
                    Add-Content -Path $FilePath -Value "$technique, $index, $($technique_name), $test_name ,$($atomic_dict["Executor"]),$($atomic_dict["Platform"]),$($atomic_dict["RequiresElevation"]),$($atomic_dict["RequireCleanup"]),$($atomic_dict["RequiresDependencies"])"
                }
                
                $index += 1
            }
        }
    }
}