Set objShell = CreateObject("Shell.Application")
objShell.ShellExecute "cmd.exe", "/k winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements", "", "runas", 1
