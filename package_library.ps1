# 自动打包 ComponentLibrary 插件
$zip = "component_library_release.zip"
Remove-Item $zip -ErrorAction SilentlyContinue
Compress-Archive -Path "ComponentLibrary","addons/component_library_share","Docs\ComponentLibrary.md" -DestinationPath $zip -Force
Write-Host "Created $zip"