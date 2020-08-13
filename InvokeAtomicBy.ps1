<#
.SYNOPSIS
    Invoke Atomic Tests based on Groups, Softwares, Platforms and/or Tactics.
.DESCRIPTION
    Invoke Atomic Tests based on Groups, Softwares, Platforms and/or Tactics.  Optionally, you can specify if you want to list the details of the Atomic test(s) only.
.EXAMPLE Invoke Atomic Test for Credential Access tactics used by group admin@338.
    PS/> Invoke-AtomicTest-By -Group "admin@338" -Tactic "Credential Access"
.EXAMPLE List all tests based on conditions.
    PS/> Invoke-AtomicTest-By -Tactic "Discovery" -ShowDetailsBrief
.EXAMPLE List all tactics, groups, etc.
    PS/> Invoke-AtomicTest-By -List "Tactic"
.NOTES
    Instead of specifying the Group name, Group Aliases names can also be used to invoke atomic tests.
    If platform parameters are not passed, the tests would run for the current system's operating system.
    You will get a list of tests that are not run if the atomics are unavailable.
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
        $QueryTerm = Get-Query-Term $QueryTerm
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
        $QueryTerm = Get-Query-Term $QueryTerm
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
        $QueryTerm = Get-Query-Term $QueryTerm
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
        $this.Revoked = $json.revoked
    }

    [Bool] Contains($QueryTerm){
        $QueryTerm = Get-Query-Term $QueryTerm
        return (($this.Id -like $QueryTerm) -or ($this.Name -like $QueryTerm) -or ($this.Platforms -like $QueryTerm))
    }
}

Update-TypeData -TypeName AttackTechnique -DefaultDisplayPropertySet Id, Name, Phases, Platforms -Force

function Invoke-AtomicTest-By {
    [OutputType([PSCustomObject])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $false, Position = 0)]
        [String]$PathToAttackMatrix = $(if ($IsLinux -or $IsMacOS) { $Env:HOME + "/AtomicRedTeam/cti/enterprise-attack" } else { $env:HOMEDRIVE + "\AtomicRedTeam\cti\enterprise-attack" }),

        [Parameter(Mandatory = $false, Position = 1)]
        [String]$PathToInvokeAtomic = $(if ($IsLinux -or $IsMacOS) { "~/AtomicRedTeam/invoke-atomicredteam" } else { "C:\AtomicRedTeam\invoke-atomicredteam" }),

        [Parameter(Mandatory = $false, Position =2)]
        [String]$List = $null,

        [Parameter(Mandatory = $false, Position =3)]
        [String]$Platform = $null,

        [Parameter(Mandatory = $false, Position =4)]
        [String]$Group = $null,

        [Parameter(Mandatory = $false, Position =5)]
        [String]$Tactic = $null,

        [Parameter(Mandatory = $false, Position =6)]
        [String]$Software = $null,

        [Parameter(Mandatory = $false, Position =5)]
        [Switch]$ShowDetailsBrief = $null
    )

    end {
        $GroupDir = Join-Path $PathToAttackMatrix "intrusion-set"
        $TechniquesDir = Join-Path $PathToAttackMatrix "attack-pattern"
        $RelationshipDir = Join-Path $PathToAttackMatrix "relationship"
        $TacticsDir = Join-Path $PathToAttackMatrix "x-mitre-tactic"
        $SoftwareDir = Join-Path $PathToAttackMatrix "malware"

        if(-not (Test-Path $PathToAttackMatrix)){
            Import-Module ./Install-CTI.ps1 -Force
            Install-CTIFolder -Force
        }

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

            $AttackObjects = Map-Objects $TechnqiuesFiles "AttackTechnique"

            if($Tactic){
                $Tactic = Map-Objects $TacticsDir "Tactic" | Where-Object {$_.Contains($Tactic)} | % {$_.ShortName}
                $AttackObjects = $AttackObjects | Where-Object {$_.Phases -like $(Get-Query-Term $Tactic)}
            }

            #If no platforms are provided, the tests would run for current system platform.

            if(-not $Platform){
                if ($IsLinux){
                    $Platform = "linux"
                }elseif($IsMacOS){
                    $Platform = "macos"
                }else{
                    $Platform = "windows"
                }
            }

            $AttackObjects = $AttackObjects | Where-Object {($_.Platforms -like $(Get-Query-Term $Platform)) -and (-not $_.Revoked)}
            # -and ($this.Version -ge 2)

            if($ShowDetailsBrief){
                $AttackObjects | Format-Table
            }else{
                $TestsNotFound = @()
                foreach ($Attck in $AttackObjects){
                    Import-Module (Join-Path $PathToInvokeAtomic "Invoke-AtomicRedTeam.psd1") -Force
                    $File = "{0}/{0}.yaml" -f $Attck.Id
                    if(Test-Path (Join-Path  (Split-Path $PathToInvokeAtomic -Parent) "atomics" $File)){
                        Invoke-AtomicTest $Attck.Id
                    }else{
                        $TestsNotFound += $Attck
                    }
                }

                if($TestsNotFound){
                    #TODO: Find a way to filter out the techniques whose subtechniques have run.
                    Write-Host "The following tests are not executed because there are no atomics for those tests or the technique's subtechniques have run."
                    $TestsNotFound | Format-Table
                }
            }

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

Function Get-Query-Term($Term){
    return "*{0}*" -f $Term
}
