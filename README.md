# ART-Utils

ART-Utils are scripts that can be used along with Atomic Red Team.

Filter-Atomic.ps1 contains scripts to filter atomic tests based on platform, executors,etc. It uses the YAML files in the atomics directory. 
invoke-script.ps1 invokes atomic tests and logs them into CSV file. 
Install-CTI.ps1 downloads the MITRE CTI repo into the default Atomic directory. It's also used in InvokeAtomicBy.ps1 file.
InvokeAtomicBy.ps1 invokes all atomic tests based on group, malware or tactic. 
