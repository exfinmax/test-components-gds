param(
	[switch]$IncludePlugins
)

$ErrorActionPreference = "Stop"

$packageName = if ($IncludePlugins) {
	"component_library_with_plugins.zip"
} else {
	"component_library_nonplugin_transfer.zip"
}

$paths = @(
	"StarterPacks",
	"ComponentLibrary/Core",
	"ComponentLibrary/Systems/MetaFlow",
	"ComponentLibrary/Systems/SceneFlow2D",
	"ComponentLibrary/Systems/Interaction2D",
	"ComponentLibrary/Systems/Camera2D",
	"ComponentLibrary/Systems/ObjectiveFlag",
	"ComponentLibrary/Modules/UI",
	"ComponentLibrary/Modules/Movement",
	"ComponentLibrary/Modules/Combat",
	"ComponentLibrary/Modules/GameLogic/Action",
	"README.md",
	"ComponentLibrary/ARCHITECTURE.md",
	"TRANSFER_TO_EXISTING_PLUGIN_PROJECT.md"
)

if ($IncludePlugins) {
	$paths += @(
		"addons/dialogue_manager",
		"addons/enhance_save_system",
		"addons/simple-gui-transitions"
	)
}

Remove-Item $packageName -ErrorAction SilentlyContinue
Compress-Archive -Path $paths -DestinationPath $packageName -Force
Write-Host "Created $packageName"
