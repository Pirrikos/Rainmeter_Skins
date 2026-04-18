Set objShell = CreateObject("Shell.Application")
objShell.ShellExecute "cmd.exe", "/k winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements --ignore-security-hash & echo. & echo Spotify se actualiza automaticamente al abrirlo.", "", "runas", 1
