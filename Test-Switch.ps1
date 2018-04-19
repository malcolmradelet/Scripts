function Test-Switch {
    [CmdletBinding()]
    param(
        [ValidateSet("Large", "Medium", "Small")]
        $VMSize = 'Large'
    )
    switch ($VMSize) {
        'Large' { 'some stuff' }
        'Small' { 'smaller stuff' }
    }
    #Write-Output $VMSize
}
