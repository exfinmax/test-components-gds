# 自动打包主线组件库与 Starter Packs
$zip = "component_library_release.zip"
Remove-Item $zip -ErrorAction SilentlyContinue
Compress-Archive -Path "ComponentLibrary","StarterPacks","addons/dialogue_manager","addons/enhance_save_system","README.md" -DestinationPath $zip -Force
Write-Host "Created $zip"
