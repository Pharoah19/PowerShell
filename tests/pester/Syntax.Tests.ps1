$sublimeRoot = "C:\st"

Import-Module "$PSScriptRoot\SyntaxHelper.psm1"

Describe "Syntax highlighting" {
    
    if (-not (Test-Path $scopesFile)) {
        Write-Warning @'
This Pester UT file consumes scopes generated by python unit test Test_TokenGenerator.testGetTokens .
You need to run python tests first to make it work.
'@
        return
    }

    Context "test-file.ps1" {
        
        $scopesFile = Join-Path $sublimeRoot "Data\Packages\User\UnitTesting\tokens\PowerShell_tokens"
        $testFile = Resolve-Path "$PSScriptRoot\..\samples\test-file.ps1"

        # splitted in two lines, because of a bug in Sort-Object
        $stScopes = cat -Raw $scopesFile | ConvertFrom-Json; $stScopes = $stScopes | sort -Property @('startOffset', 'endOffset')
        # tokens are already sorted
        $psScopes = Get-TokensFromFile $testFile | Convert-TokenToScope 

        It "doesn't split tokens across the scopes" {
            $stIndex = 0
            $psScopes | %{
                while ($stScopes[$stIndex].endOffset -le $_.startOffset) {
                    $stIndex++
                }
                #Write-Host "PowerShell scope $_ "
                #Write-Host "SublimeText scope $($stScopes[$stIndex])"
                
                if (-not (Test-ScopeInclosure $_ $stScopes[$stIndex])) {
                    #Write-Warning "PowerShell scope not found in SublimeText scopes $_ "
                    if (-not (Test-ScopeDisclosure $_ $stScopes[$stIndex])) {
                        Write-Error "PowerShell scope $_ overlap with SublimeText scope $($stScopes[$stIndex]) "
                        $false | Should be $true
                    }
                }
            }
        }
    }
}