# Writes $env:NEW_PATH to HKCU\Environment\PATH as REG_EXPAND_SZ - the type
# Windows normally stores PATH as, which lets entries like %JAVA_HOME%\bin
# expand on read. [Environment]::SetEnvironmentVariable writes plain REG_SZ
# instead, silently downgrading the type and breaking any %VARIABLE%-style
# entries elsewhere in PATH for every user who runs the installer/uninstaller
# - not just people with long PATHs.
#
# Kept as its own file (invoked via `-File`, not inlined as a `-Command`
# one-liner) so the registry/.NET calls below - which need their own
# parentheses and braces - never have to coexist with cmd.exe's parenthesized
# if/else blocks on the same line.
#
# The new value is read from $env:NEW_PATH (set by the calling batch script,
# inherited into this process's environment) rather than a -Value command-
# line parameter. That sidesteps two argv-passing pitfalls: Windows argv
# quoting mangles a trailing backslash right before a closing quote (e.g.
# "...\Git\bin\" arrives with the escaped quote folded into the value), and
# an empty-string argument isn't guaranteed to bind cleanly to a Mandatory
# parameter on every PowerShell version - which could otherwise prompt
# interactively for the value and hang the caller instead of erroring.
#
# install.bat/uninstall.bat check the exit code after calling this and only
# report success if it's 0, so a failure here (e.g. a restrictive execution
# policy or PowerShell Constrained Language Mode blocking the registry call)
# surfaces as an error instead of a false "PATH updated".

$value = $env:NEW_PATH
if ($null -eq $value) { $value = '' }

try {
    $key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment', $true)
    $key.SetValue('PATH', $value, [Microsoft.Win32.RegistryValueKind]::ExpandString)
    $key.Close()
} catch {
    Write-Error $_
    exit 1
}
