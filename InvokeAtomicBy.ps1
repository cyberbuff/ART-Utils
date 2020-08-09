<#
.SYNOPSIS
    Invoke Atomic Tests based on Groups, Softwares, Platforms and/or Tactics.
#>

class Relationship{
    [string]$Id
    [string]$SourceRef
    [string]$TargetRef
    [string]$Type
    [string]$RelType

    Relationship([PSCustomObject]$json){
        $this.Id = $json.id
        $this.SourceRef = $json.source_ref
        $this.TargetRef = $json.target_ref
        $this.Type = $json.type
        $this.RelType = $json.relationship_type
    }

    [Bool] IsTargetRefAttackPattern($SourceRef){ 
        return (($this.SourceRef -eq $SourceRef) -and ($this.TargetRef -match "attack-pattern--*"))
    }
}

class Software {
    [string]$Id
    [string]$Guid
    [string]$Name
    [string]$Aliases
    [string]$Platforms

    Software([PSCustomObject]$json){
        $this.Id = $json.external_references[0].external_id
        $this.Guid = $json.id
        $this.name = $json.name
        $this.Aliases = $json.x_mitre_aliases -join ", "
        $this.Platforms = $json.x_mitre_platforms -join ", "
    }

    [Bool] Contains($QueryTerm){
        $QueryTerm = "*{0}*" -f $QueryTerm
        return (($this.Id -like $QueryTerm) -or ($this.Name -like $QueryTerm) -or ($this.Aliases -like $QueryTerm))
    }
}
Update-TypeData -TypeName Software -DefaultDisplayPropertySet Id, Name, Aliases,Platforms -Force

class Tactic {
    [string]$Id
    [string]$Guid
    [string]$Name
    [string]$ShortName

    Tactic([PSCustomObject]$json){
        $this.Id = $json.external_references[0].external_id
        $this.Guid = $json.id
        $this.Name = $json.name
        $this.ShortName = $json.x_mitre_shortname
    }

    [Bool] Contains($QueryTerm){
        $QueryTerm = "*{0}*" -f $QueryTerm
        return (($this.Id -like $QueryTerm) -or ($this.Name -like $QueryTerm) -or ($this.ShortName -like $QueryTerm))
    }
}
Update-TypeData -TypeName Tactic -DefaultDisplayPropertySet Id, Name -Force


class ThreatGroup {
    [string]$Id
    [string]$Guid
    [string]$Name
    [string]$Aliases

    ThreatGroup([PSCustomObject]$json){
        $this.Id = $json.external_references[0].external_id
        $this.Guid = $json.id
        $this.Name = $json.name
        $this.Aliases = $json.Aliases -join ", "
    }

    [Bool] Contains($QueryTerm){
        $QueryTerm = "*{0}*" -f $QueryTerm
        return (($this.Id -like $QueryTerm) -or ($this.Name -like $QueryTerm) -or ($this.Aliases -like $QueryTerm))
    }
}

Update-TypeData -TypeName ThreatGroup -DefaultDisplayPropertySet Id,Name,Aliases -Force

class AttackTechnique {
    [string]$Id
    [string]$Guid
    [string]$Name
    [string]$Phases
    [string]$Platforms
    [bool]$Revoked

    AttackTechnique([PSCustomObject]$json){
        $this.Id = $json.external_references[0].external_id 
        $this.Name = $json.name
        $this.Guid = $json.id
        $this.Platforms = $json.x_mitre_platforms -join ", "
        $this.Phases = ($json.kill_chain_phases | % {$_.phase_name}) -join ", "
        $this.revoked = $json.revoked
    }

    [Bool] Contains($QueryTerm){
        $QueryTerm = "*{0}*" -f $QueryTerm
        return (($this.Id -like $QueryTerm) -or ($this.Name -like $QueryTerm) -or ($this.Platforms -like $QueryTerm))
    }
}

Update-TypeData -TypeName AttackTechnique -DefaultDisplayPropertySet Id,Name,Phases,Platforms -Force

function InvokeAtomicBy {
    [OutputType([PSCustomObject])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $false, Position = 0)]
        [String]$PathToAttackMatrix = $(if ($IsLinux -or $IsMacOS) { "~/Downloads/cti/enterprise-attack" } else { "C:\AtomicRedTeam\enterprise-attack\*\*.yaml" }),
        
        [Parameter(Mandatory = $false, Position =1)]
        [String]$List = $null,

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
        $TacticsDir = Join-Path $PathToAttackMatrix "x-mitre-tactic"
        $SoftwareDir = Join-Path $PathToAttackMatrix "malware"

        if($List){
            if($List -eq "Group"){
                Map-Objects $GroupDir "ThreatGroup" | Format-Table
            }

            if($List -eq "Tactic"){
                Map-Objects $TacticsDir "Tactic" | Format-Table
            }

            if($List -eq "Software"){
                Map-Objects $SoftwareDir "Software" | Format-Table
            }

        }
        else{
            $TechnqiuesFiles = Get-ChildItem -Path $TechniquesDir -Recurse | % {Join-Path $TechniquesDir $_.Name}

            if($Group){
                $GroupList = Map-Objects $GroupDir "ThreatGroup" | Where-Object { $_.Contains($Group) }

                foreach ($item in $GroupList){
                    Write-Host "Invoking tests for group: " $item.name
                    $TechnqiuesFiles = Map-Objects $RelationshipDir "Relationship" | Where-Object {$_.IsTargetRefAttackPattern($item.Guid)} | % { Join-Path $TechniquesDir ($_.TargetRef+".json") }
                }
            }

            if($Software){
                $GroupList = Map-Objects $SoftwareDir "Software" | Where-Object { $_.Contains($Software) }

                foreach ($item in $GroupList){
                    Write-Host "Invoking tests for Software: " $item.name
                    $TechnqiuesFiles = Map-Objects $RelationshipDir "Relationship" | Where-Object {$_.IsTargetRefAttackPattern($item.Guid)} | % { Join-Path $TechniquesDir ($_.TargetRef+".json") }
                }
            }

            if($Tactic){
                $Tactic = Map-Objects $TacticsDir "Tactic" | Where-Object {$_.Contains($Tactic)} | % {$_.ShortName}
                $Pattern = '"phase_name": "{0}"' -f $Tactic
                $TechnqiuesFiles = Filter-Files $TechnqiuesFiles $Pattern
            }

            if($TechnqiuesFiles -ne $null){
                $AttackObjects = Map-Objects $TechnqiuesFiles "AttackTechnique"
            }else{
                $AttackObjects = @()
            }

            if($Platform){
                $AttackObjects = $AttackObjects | Where {$_.x_mitre_platforms -contains $Platform -and (-not $_.revoked)}
            }

            $AttackObjects | Format-Table
            
        }
    }
}

Function Map-Objects($Dir, $ObjectType){
    return Get-ChildItem -Recurse -LiteralPath $Dir | % { New-Object -TypeName $ObjectType -ArgumentList $(Get-Content -Raw -Path $_ |  ConvertFrom-Json).objects[0] }
}

Function Filter-Files($Dir, $Pattern){
    return (Get-ChildItem -Recurse -LiteralPath $Dir | Select-String -Pattern $Pattern  | Select -Unique Path | % {$_.Path } ) 
}

Function Get-Absolute-Dir($ParentDir, $FileName){
    return Join-Path $ParentDir ("{0}.json" -f $FileName)
}