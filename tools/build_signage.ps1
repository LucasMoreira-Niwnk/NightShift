$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
Push-Location $projectRoot
try {
    & node (Join-Path $PSScriptRoot 'create_floor_plan.mjs')
    if ($LASTEXITCODE -ne 0) { throw 'Could not generate floor plans.' }
    Add-Type -AssemblyName System.Drawing
    $culture = [Globalization.CultureInfo]::InvariantCulture
    function Format-Number([double]$value) { return $value.ToString('0.###', $culture) }
    foreach ($name in 'reception', 'security') {
        $file = Join-Path $projectRoot ('game\assets\signage\floor_plan_' + $name + '.svg')
        [xml]$svg = Get-Content -LiteralPath $file -Raw -Encoding UTF8
        $texts = @($svg.GetElementsByTagName('text'))
        foreach ($text in $texts) {
            $size = [single]::Parse($text.GetAttribute('font-size'), $culture)
            $x = [double]::Parse($text.GetAttribute('x'), $culture)
            $y = [double]::Parse($text.GetAttribute('y'), $culture)
            $outline = New-Object System.Drawing.Drawing2D.GraphicsPath
            $outline.AddString($text.InnerText, [Drawing.FontFamily]::GenericSansSerif, 0, $size, [Drawing.PointF]::new(0, 0), [Drawing.StringFormat]::GenericTypographic)
            $bounds = $outline.GetBounds()
            if ($text.GetAttribute('text-anchor') -ne 'start') { $x -= $bounds.Width / 2 }
            $x -= $bounds.X
            $y -= $size * 0.95
            $points = $outline.PathPoints
            $types = $outline.PathTypes
            $commands = New-Object 'System.Collections.Generic.List[string]'
            for ($i = 0; $i -lt $points.Length; $i++) {
                $type = $types[$i] -band 7
                $point = (Format-Number $points[$i].X) + ',' + (Format-Number $points[$i].Y)
                if ($type -eq 0) { $commands.Add('M' + $point) }
                elseif ($type -eq 1) { $commands.Add('L' + $point) }
                elseif ($type -eq 3) {
                    $point2 = (Format-Number $points[$i+1].X) + ',' + (Format-Number $points[$i+1].Y)
                    $point3 = (Format-Number $points[$i+2].X) + ',' + (Format-Number $points[$i+2].Y)
                    $commands.Add('C' + $point + ' ' + $point2 + ' ' + $point3)
                    $i += 2
                }
                if (($types[$i] -band 128) -ne 0) { $commands.Add('Z') }
            }
            $path = $svg.CreateElement('path', 'http://www.w3.org/2000/svg')
            $path.SetAttribute('d', ($commands -join ' '))
            $path.SetAttribute('fill-rule', 'evenodd')
            $transform = $text.GetAttribute('transform') + ' translate(' + (Format-Number $x) + ' ' + (Format-Number $y) + ')'
            $path.SetAttribute('transform', $transform.Trim())
            if ($text.HasAttribute('fill')) { $path.SetAttribute('fill', $text.GetAttribute('fill')) }
            $null = $text.ParentNode.ReplaceChild($path, $text)
            $outline.Dispose()
        }
        $svg.Save($file)
    }
} finally { Pop-Location }
