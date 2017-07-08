#Requires -Version 5

<#PSScriptInfo

    .VERSION 1.0

    .GUID cad7db76-01e8-4abd-bdb9-3fca50cadbc7

    .AUTHOR psadmin.io

    .SYNOPSIS
        ps-vagabond provisioning boot

    .DESCRIPTION
        Provisioning bootstrap script for ps-vagabond

    .PARAMETER PATCH_ID
        Patch ID for the PUM image

    .PARAMETER MOS_USERNAME
        My Oracle Support Username

    .PARAMETER MOS_PASSWORD
        My Oracle Support Password

    .PARAMETER DPK_INSTALL
        Directory to use for downloading the DPK files

    .EXAMPLE
        provision-boot.ps1 -PATCH_ID 23711856 -MOS_USERNAME user@example.com -MOS_PASSWORD mymospassword -DPK_INSTALL C:/peoplesoft/dpk/fn92u020

#>

#-----------------------------------------------------------[Parameters]----------------------------------------------------------

[CmdletBinding()]
Param(
  [String]$PATCH_ID     = $env:PATCH_ID,
  [String]$DPK_INSTALL  = $env:DPK_INSTALL,
  [String]$PTP_INSTALL  = $env:PTP_INSTALL,
  [String]$PUPPET_HOME  = $env:PUPPET_HOME
)


#---------------------------------------------------------[Initialization]--------------------------------------------------------

# Valid values: "Stop", "Inquire", "Continue", "Suspend", "SilentlyContinue"
$ErrorActionPreference = "Stop"
$DebugPreference = "SilentlyContinue"
$VerbosePreference = "SilentlyContinue"

#------------------------------------------------------------[Variables]----------------------------------------------------------

$DEBUG = "true"
$computername = $env:computername

function change_to_midtier() {
  Write-Host "[${computername}][Task] Change env_type to 'midtier'"
  (Get-Content "${PUPPET_HOME}\data\defaults.yaml").replace("env_type: fulltier", "env_type: midtier") | Set-Content "${PUPPET_HOME}\data\defaults.yaml"
  (Get-Content "${PUPPET_HOME}\manifests\site.pp") -replace 'include.*', "include ::pt_role::pt_tools_deployment" | Set-Content "${PUPPET_HOME}\manifests\site.pp"
  Write-Host "[${computername}][Done] Change env_type to 'midtier'"
}

function execute_dpk_cleanup() {
  Write-Host "[${computername}][Task] Run the DPK cleanup script"
  Write-Host "PTP INSTALL: ${PTP_INSTALL}"

  Stop-Service psft*
  Stop-Service -name "ORACLE ProcMGR V12.1.3.0.0_VS2012"

  if ($DEBUG -eq "true") {
    . "${DPK_INSTALL}/setup/psft-dpk-setup.ps1" `
      -cleanup
  } else {
    . "${DPK_INSTALL}/setup/psft-dpk-setup.ps1" `
      -cleanup 2>&1 | out-null
  }
}
function execute_psft_dpk_setup() {

  # $begin=$(get-date)
  Write-Host "[${computername}][Task] Executing PeopleTools Patch DPK setup script"
  Write-Host "PTP INSTALL: ${PTP_INSTALL}"
  if ($DEBUG -eq "true") {
    . "${DPK_INSTALL}/setup/psft-dpk-setup.ps1" `
      -dpk_src_dir=$(resolve-path $DPK_INSTALL).path `
      -env_type=midtier `
      -deploy_only `
      -silent `
      -no_env_setup
  } else {
    . "${DPK_INSTALL}/setup/psft-dpk-setup.ps1" `
      -dpk_src_dir=$(resolve-path $DPK_INSTALL).path `
      -env_type=midtier `
      -deploy_only `
      -silent `
      -no_env_setup 2>&1 | out-null
  }

  Write-Host "[${computername}][Done] Executing PeopleTools Patch DPK setup script"
}

. change_to_midtier
. execute_dpk_cleanup
# . execute_psft_dpk_setup
# . change_dpk_role
# . patch_database
# . deploy_new_domains