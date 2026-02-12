# clipshot watcher — event-driven clipboard image monitor
# Listens for WM_CLIPBOARDUPDATE, saves images as PNG, prints SAVED:/ERROR: to stdout
param([string]$SavePath)
if (-not $SavePath) { Write-Output "ERROR:SavePath required"; exit 1 }
if (-not (Test-Path $SavePath)) { New-Item -ItemType Directory -Path $SavePath -Force | Out-Null }

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$src = @"
using System;
using System.Runtime.InteropServices;
public class ClipboardWatcher {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool AddClipboardFormatListener(IntPtr hwnd);
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool RemoveClipboardFormatListener(IntPtr hwnd);
    public const int WM_CLIPBOARDUPDATE = 0x031D;
}
"@
Add-Type -TypeDefinition $src -ReferencedAssemblies System.Runtime.InteropServices

$lastHash = ""
$form = New-Object System.Windows.Forms.Form
$form.ShowInTaskbar = $false
$form.WindowState = 'Minimized'
$form.FormBorderStyle = 'None'
$form.Size = New-Object System.Drawing.Size(1, 1)

$form.Add_HandleCreated({
    [ClipboardWatcher]::AddClipboardFormatListener($form.Handle) | Out-Null
})

$form.Add_FormClosing({
    [ClipboardWatcher]::RemoveClipboardFormatListener($form.Handle) | Out-Null
})

# Override WndProc via a timer-based check after clipboard event
$script:clipChanged = $false
$form.Add_Activated({})

# Use a custom NativeWindow to intercept WM_CLIPBOARDUPDATE
$nativeWindowSrc = @"
using System;
using System.Windows.Forms;
public class ClipboardWindow : NativeWindow {
    public event EventHandler ClipboardChanged;
    private const int WM_CLIPBOARDUPDATE = 0x031D;
    protected override void WndProc(ref Message m) {
        if (m.Msg == WM_CLIPBOARDUPDATE) {
            if (ClipboardChanged != null) ClipboardChanged(this, EventArgs.Empty);
        }
        base.WndProc(ref m);
    }
}
"@
Add-Type -TypeDefinition $nativeWindowSrc -ReferencedAssemblies System.Windows.Forms

# Remove the basic form approach, use NativeWindow directly
$form2 = New-Object System.Windows.Forms.Form
$form2.ShowInTaskbar = $false
$form2.WindowState = 'Minimized'
$form2.FormBorderStyle = 'None'
$form2.Size = New-Object System.Drawing.Size(1, 1)
$form2.Opacity = 0

$form2.Add_Shown({
    $clipWin = New-Object ClipboardWindow
    $clipWin.AssignHandle($form2.Handle)
    [ClipboardWatcher]::AddClipboardFormatListener($form2.Handle) | Out-Null

    $clipWin.Add_ClipboardChanged({
        try {
            $data = [System.Windows.Forms.Clipboard]::GetDataObject()
            if ($null -eq $data) { return }
            if (-not $data.GetDataPresent([System.Windows.Forms.DataFormats]::Bitmap)) { return }

            $img = $data.GetData([System.Windows.Forms.DataFormats]::Bitmap)
            if ($null -eq $img) { return }

            # Hash-based dedup
            $ms = New-Object System.IO.MemoryStream
            $img.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
            $bytes = $ms.ToArray()
            $ms.Close()
            $hash = [System.BitConverter]::ToString(
                [System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
            ).Replace("-","").Substring(0,16)

            if ($hash -eq $script:lastHash) { return }
            $script:lastHash = $hash

            $ts = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
            $name = "screenshot_${ts}.png"
            $path = Join-Path $SavePath $name
            [System.IO.File]::WriteAllBytes($path, $bytes)
            $img.Dispose()

            [Console]::Out.WriteLine("SAVED:$name")
            [Console]::Out.Flush()
        } catch {
            [Console]::Out.WriteLine("ERROR:$($_.Exception.Message)")
            [Console]::Out.Flush()
        }
    })
})

[Console]::Out.WriteLine("READY")
[Console]::Out.Flush()
[System.Windows.Forms.Application]::Run($form2)
