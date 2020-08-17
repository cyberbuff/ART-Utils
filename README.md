# ART-Utils

ART-Utils are scripts that can be used along with Atomic Red Team.

1. Filter-Atomic.ps1 contains scripts to filter atomic tests based on platform, executors,etc. It uses the YAML files in the atomics directory. 
2. invoke-script.ps1 invokes atomic tests and logs them into CSV file. 
3. Install-CTI.ps1 downloads the MITRE CTI repo into the default Atomic directory. It's also used in InvokeAtomicBy.ps1 file.
4. InvokeAtomicBy.ps1 invokes all atomic tests based on group, malware or tactic. 
