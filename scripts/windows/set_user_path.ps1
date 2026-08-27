# Writes -Value to HKCU\Environment\PATH as REG_EXPAND_SZ - the type Windows
# normally stores PATH as, which lets entries like %JAVA_HOME%\bin expand on
# read. [Environment]::SetEnvironmentVariable writes plain REG_SZ instead,
# silently downgrading the type and breaking any %VARIABLE%-style entries
# elsewhere in PATH for every user who runs the installer/uninstaller - not
# just people with long PATHs.
#
# Kept as its own file (invoked via `-File`, not inlined as a `-Command`
# one-liner) so the registry/.NET calls below - which need their own
# parentheses and braces - never have to coexist with cmd.exe's parenthesized
# if/else blocks on the same line.
#
# install.bat/uninstall.bat check the exit code after calling this and only
# report success if it's 0, so a failure here (e.g. a restrictive execution
# policy or PowerShell Constrained Language Mode blocking the registry call)
# surfaces as an error instead of a false "PATH updated".
param(
    [Parameter(Mandatory = $true)]
    [AllowEmptyString()]
    [string]$Value
)

try {
    $key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment', $true)
    $key.SetValue('PATH', $Value, [Microsoft.Win32.RegistryValueKind]::ExpandString)
    $key.Close()
} catch {
    Write-Error $_
    exit 1
}
