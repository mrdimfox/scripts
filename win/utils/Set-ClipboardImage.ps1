# Copy image to clipboard. PNG is only supported extension.
# To convert to exe use ps2exe.

$_ = [Reflection.Assembly]::LoadWithPartialName('System.Drawing');
$_ = [Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms');

$filename = $args[0];

try {
    $file = Get-Item $filename -ErrorAction Stop;
}
catch [System.Exception] {
    return;
}

$extension = [System.IO.Path]::GetExtension($file)

if ($extension -eq ".png") {
    $img = [System.Drawing.Image]::Fromfile($file);
    $_ = [System.Windows.Forms.Clipboard]::SetImage($img);
    $img.Dispose()
}
