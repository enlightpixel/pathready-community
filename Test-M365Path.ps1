#Requires -Version 7.2
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Source,
    [Parameter(Mandatory)][string]$Destination,
    [switch]$IncludeSourceFolder
)

$root = Get-Item -LiteralPath $Source -Force -ErrorAction Stop
if ($root -isnot [System.IO.DirectoryInfo] -or ($root.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
    throw 'Source must be a filesystem directory that is not a link or reparse point.'
}
$target = $Destination.Trim().Trim('/')
if (!$target -or $target -match '[:\\?#]|//|[\x00-\x1f]' -or ($target.Split('/') | Where-Object { $_ -in '.', '..' })) {
    throw 'Use a decoded server-relative destination such as /sites/Operations/Shared Documents/Archive, without the hostname.'
}
$prefix = if ($IncludeSourceFolder) { "$target/$($root.Name)" } else { $target }
$queue = [Collections.Generic.Queue[object]]::new()
$queue.Enqueue($root)
while ($queue.Count) {
    $directory = $queue.Dequeue()
    try { $children = @(Get-ChildItem -LiteralPath $directory.FullName -Force -ErrorAction Stop) }
    catch {
        [pscustomobject]@{ RelativePath = [IO.Path]::GetRelativePath($root.FullName, $directory.FullName); Kind = 'Directory'; DecodedPathLength = $null; Finding = 'Directory could not be read' }
        continue
    }
    foreach ($item in $children) {
        $relative = [IO.Path]::GetRelativePath($root.FullName, $item.FullName)
        $decodedPath = "$prefix/$($relative.Replace([IO.Path]::DirectorySeparatorChar, '/'))"
        $isDirectory = $item -is [IO.DirectoryInfo]
        $isLink = [bool]($item.Attributes -band [IO.FileAttributes]::ReparsePoint)
        $findings = @(
            if ($isLink) { 'Reparse point skipped' }
            if ($decodedPath.Length -gt 400) { 'Decoded path exceeds 400 UTF-16 units' }
            if ($item.Name.Length -gt 255) { 'Name exceeds 255 UTF-16 units' }
            if ($item.Name -match '["*:<>?/\\|\x00-\x1F]|^ |[. ]$') { 'Unsupported character or edge space/dot' }
            if ($item.Name -match '^(\.lock|desktop\.ini)$|^~\$|_vti_|^(CON|PRN|AUX|NUL|COM[0-9]|LPT[0-9])(\.|$)') { 'Reserved name pattern' }
        )
        if ($findings.Count) {
            [pscustomobject]@{
                RelativePath = $relative
                Kind = if ($isDirectory) { 'Directory' } else { 'File' }
                DecodedPathLength = $decodedPath.Length
                Finding = $findings -join '; '
            }
        }
        if ($isDirectory -and !$isLink) { $queue.Enqueue($item) }
    }
}
