<#
.SYNOPSIS
    Filters specified Atomic test(s)
#>
function Filter-Atomic-API {
    [OutputType([PSCustomObject])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $false, Position = 0)]
        [String]$PathToAttackMatrix = $(if ($IsLinux -or $IsMacOS) { "~/Downloads/cti/enterprise-attack" } else { "C:\AtomicRedTeam\enterprise-attack\*\*.yaml" }),

        [Parameter(Mandatory = $false, Position = 1)]
        [String]$Keyword = $null,
        
        [Parameter(Mandatory = $false, Position =2)]
        [String]$Platform = $null,

        [Parameter(Mandatory = $false, Position =3)]
        [String]$Group = $null,

        [Parameter(Mandatory = $false, Position =4)]
        [String]$Tactic = $null,

        [Parameter(Mandatory = $false, Position =4)]
        [String]$Software = $null
    )

    end {
        $GroupDir = Join-Path $PathToAttackMatrix "intrusion-set"
        $TechniquesDir = Join-Path $PathToAttackMatrix "attack-pattern"
        $RelationshipDir = Join-Path $PathToAttackMatrix "relationship"
        
        $TechnqiuesFiles = Get-ChildItem $TechniquesDir -Recurse | % {Join-Path $TechniquesDir $_.Name}

        if($Group){
            $Files = Filter-Files $GroupDir $Group
            
            $AllTechniques = @()

            foreach ($item in $Files){
                $obj = Split-Path -Path $item.path -LeafBase -Resolve

                $json = Get-Content -Raw -Path $item.path | ConvertFrom-Json
                Write-Host "Invoking tests for group: " $json.objects[0].name

                $Pattern = '"source_ref": "{0}"' -f $obj
                $Attacks = Filter-Files $RelationshipDir $Pattern
                $AllTechniques += (Get-AttackPatterns $Attacks $TechniquesDir)
            }
            $TechnqiuesFiles = Compare-Object -ReferenceObject $TechnqiuesFiles -DifferenceObject $AllTechniques -IncludeEqual -ExcludeDifferent | % {$_.InputObject}
        }

        if($Tactic){
            $Pattern = '"phase_name": "{0}"' -f $Tactic
            $TechnqiuesFiles = Filter-Files $TechnqiuesFiles $Pattern
        }


        $TechnqiuesFiles | % {Write-Host $(GetTechniquesFromAttackPattern $_)}

    }
}

Function Filter-Files($Dir, $Pattern){
    return (Get-ChildItem -Recurse -LiteralPath $Dir | Select-String -Pattern $Pattern  | Select -Unique Path)
}

Function GetTechniquesFromAttackPattern($AttackPatternFiles){
    $objects = $AttackPatternFiles | % {$(Get-Content -Raw -Path $_ |  ConvertFrom-Json).objects[0]}    
    return $objects
}

Function Get-AttackPatterns($Files, $BaseDir){
    $AttackPatterns = @()
    foreach ($item1 in $Files){
        $rel = $(Get-Content -Raw -Path $item1.path | ConvertFrom-Json).objects[0]
        if($rel.target_ref -match "attack-pattern--*"){
            $AttackPatterns +=  (Join-Path $BaseDir ($rel.target_ref + ".json"))
        }
    }
    return $AttackPatterns
}