Invoke-AtomicTest-By uses MITRE's CTI to fetch all the attack technqiues from MITRE ATT&CK framework and invoke corresponding techniques from RedCanary's Atomic Red Team. 

If your Jupyter Notebook supports Powershell, use InvokeAtomicBy.ipynb. 
If you want to install Jupyter Notebook for Powershell, checkout 
https://github.com/dotnet/interactive/blob/master/docs/NotebooksLocalExperience.md


#Getting Started

Import InvokeAtomicBy.ps1


```PowerShell
#!pwsh

Import-Module ./InvokeAtomicBy.ps1 -Force
```
To list all groups, malwares, tactics, use -List parameter. 

Allowed values for -List, 

1. Group    - List all groups
2. Software - List all malwares
3. Tactic   - List all tactics

```PowerShell
#!pwsh

Invoke-AtomicTest-By -List Group
```

To invoke all atomic tests by group or malware or tactic use corresponding parameter. ID, Name or Aliases can be used.

For example, 
Invoke-AtomicTest-By -Group G0073
Invoke-AtomicTest-By -Group APT19
Invoke-AtomicTest-By -Group Codoso

All works the same. 

To invoke all the discovery tactic atomic tests used by group APT19, use
Invoke-AtomicTest-By -Group APT19 -Tactic discovery


```PowerShell
#!pwsh

Invoke-AtomicTest-By -Group APT19 -Tactic discovery
```
To Display only the techniques, use -ShowDetailsBrief parameter.

```PowerShell
#!pwsh

Invoke-AtomicTest-By -Group APT19 -Tactic discovery -ShowDetailsBrief
```
Note: If there is no Platform parameter specified, tests will be run for the current environment.