param(
    [switch]$Uninstall,
    [string]$SaveDir = (Join-Path $env:APPDATA 'kingdom_rush_genesis')
)

$ErrorActionPreference = 'Stop'
$files = @(
    'kr6_summon_public/trainer_archmage_core.lua',
    'kr6_summon_public/trainer_magus.lua',
    'kr6_summon_public/trainer_magus/animations.lua',
    'kr6_summon_public/trainer_magus/atlas.lua',
    'kr6_summon_public/trainer_magus/death.lua',
    'kr6_summon_public/trainer_magus/death.png',
    'kr6_summon_public/trainer_magus/empowered.png',
    'kr6_summon_public/trainer_magus/motion.png',
    'kr6_summon_public/trainer_magus/smoke.lua',
    'kr6_summon_public/trainer_magus/smoke.png',
    'kr6_summon_public/trainer_audio.lua',
    'kr6_summon_public/trainer_gait.lua',
    'kr6_summon_public/trainer_native_units.lua',
    'kr6_summon_public/trainer_templar.lua',
    'kr6_summon_public/grail.png',
    'kr6_summon_public/kr4_allies.lua',
    'kr6_summon_public/trainer_kr4_audio.lua',
    'kr6_summon_public/ice_lake.lua',
    'kr6_summon_public/trainer_public_formation.lua',
    'kr6_summon_public/trainer_public_panel.lua',
    'kr6_summon_public/trainer_public_spear.lua',
    'kr6_summon_public/trainer_reinforcements.lua',
    'kr6_summon_public/trainer_reinforcements/animations.lua',
    'kr6_summon_public/trainer_reinforcements/trainer_reinforcements.lua',
    'kr6_summon_public/trainer_reinforcements/trainer_reinforcements.png',
    'kr6_summon_public/trainer_longbow.lua',
    'kr6_summon_public/trainer_longbow/animations.lua',
    'kr6_summon_public/trainer_longbow/trainer_longbow.lua',
    'kr6_summon_public/trainer_longbow/trainer_longbow.png',
    'kr6_summon_public.lua'
)

if ($Uninstall) {
    $generated = Join-Path $SaveDir 'kr6_summon_public/vengeance'
    if (Test-Path -LiteralPath (Join-Path $generated 'ready.lua') -PathType Leaf) {
        $parent = (Resolve-Path -LiteralPath (Join-Path $SaveDir 'kr6_summon_public')).Path
        $resolved = (Resolve-Path -LiteralPath $generated).Path
        if ($resolved -ne (Join-Path $parent 'vengeance') -or
            ((Get-Item -LiteralPath $resolved).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            throw "Unexpected import directory: $resolved"
        }
        Remove-Item -LiteralPath $resolved -Recurse
    }
    foreach ($name in $files) {
        $path = Join-Path $SaveDir $name
        if (Test-Path -LiteralPath $path -PathType Leaf) {
            Remove-Item -LiteralPath $path
        }
    }
    foreach ($name in @('kr6_summon_public/trainer_magus', 'kr6_summon_public/trainer_reinforcements', 'kr6_summon_public/trainer_longbow', 'kr6_summon_public')) {
        $path = Join-Path $SaveDir $name
        if ((Test-Path -LiteralPath $path -PathType Container) -and !(Get-ChildItem -LiteralPath $path -Force)) {
            [IO.Directory]::Delete($path)
        }
    }
    Write-Host 'Removed. Delete -custom_script kr6_summon_public from Steam Launch Options.'
    exit 0
}

foreach ($name in $files) {
    $path = Join-Path $PSScriptRoot $name
    if (!(Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Missing package file: $path. Extract the entire release before installing."
    }
}

foreach ($name in $files) {
    $destination = Join-Path $SaveDir $name
    [void][IO.Directory]::CreateDirectory((Split-Path -Parent $destination))
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot $name) -Destination $destination -Force
}
Write-Host 'Installed. Add -custom_script kr6_summon_public to Steam Launch Options.'
