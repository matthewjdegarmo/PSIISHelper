InModuleScope PSIISHelper {
    BeforeDiscovery {
        #! Finish nested path splitting.
        $ModuleRoot =   Split-Path (
                            Split-Path (
                                Split-Path $PSScriptRoot -Parent
                            ) -Parent
                        ) -Parent
        Remove-Module PSIISHelper -Force -ErrorAction SilentlyContinue
        Import-Module $ModuleRoot -Force
        $PrivateFunctionsPath = Join-Path $ModuleRoot 'Functions' 'Private' '*.ps1'

        $PrivateFunctions = Get-ChildItem $PrivateFunctionsPath
    }


    Describe "Function: <_.BaseName>" -ForEach $PrivateFunctions {
        BeforeDiscovery {
            $Parameters = ((Get-Command $_.BaseName -ErrorAction SilentlyContinue).Parameters).Keys 
                | Where-Object { 
                    $_ -notin ([System.Management.Automation.PSCmdlet]::CommonParameters) -and 
                    $_ -notin ([System.Management.Automation.PSCmdlet]::OptionalCommonParameters) 
                }
        }

        BeforeAll {
            $CurrentFunction = $_
            . $CurrentFunction.FullName
        }

        Context "Parameter - <_>" -ForEach $Parameters {
            BeforeAll {
                $Parameter = $_
            }
            It "Should have .PARAMETER help for each defined parameter" {
                $CurrentFunction.FullName | Should -FileContentMatch ".PARAMETER $Parameter"
            }
        }

        It "Should register command with Get-Command" {
            (Get-Command $CurrentFunction.BaseName) | Should -BeOfType [System.Management.Automation.CommandInfo]
        }
        It "Should have comment-based help block" {
            $CurrentFunction.FullName | Should -FileContentMatch '<#'
            $CurrentFunction.FullName | Should -FileContentMatch '#>'
        }
        It "Should have SYNOPSIS section in help" {
            $CurrentFunction.FullName | Should -FileContentMatch '.SYNOPSIS'
        }
        It "Should have DESCRIPTION section in help" {
            $CurrentFunction.FullName | Should -FileContentMatch '.DESCRIPTION'
        }
        It "Should have EXAMPLE section in help" {
            $CurrentFunction.FullName | Should -FileContentMatch '.EXAMPLE'
        }
        It "Should have NOTES section in help" {
            $CurrentFunction.FullName | Should -FileContentMatch '.NOTES'
        }
        It "Should be an advanced function" {
            $CurrentFunction.FullName | Should -FileContentMatch 'function'
            $CurrentFunction.FullName | Should -FileContentMatch 'cmdletbinding'
            $CurrentFunction.FullName | Should -FileContentMatch 'param'
        }
        It "Should have Begin and End Regions" {
            $CurrentFunction.FullName | Should -FileContentMatch "#Region"
            $CurrentFunction.FullName | Should -FileContentMatch "#EndRegion"
        }
        It "Should be valid PowerShell code" {
            $FileContent = Get-Content -Path $CurrentFunction.FullName -ErrorAction Stop
            $Errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize($FileContent, [ref]$errors)
            $errors.Count | Should -be 0
        }
    }
}