# Azure Bay Unity + Cubism Skeleton

This folder provides a lightweight project skeleton for `Unity 2022 LTS + Live2D Cubism SDK`.

## Scope
- Character affection/mood state runtime
- Two-character data model (`Xi`, `Ning`)
- Economy runtime (orchard/fishery production, offline settlement)
- Local JSON save/load
- HUD presenter example
- Bootstrap entry script

## Quick Start
1. Create a new Unity 2022 LTS project (2D, portrait).
2. Copy `Assets/AzureBay` from this folder into your Unity project `Assets/`.
3. Install Cubism SDK for Unity from official package.
4. Add scene objects:
   - `AzureBayBootstrap` (attach `AzureBayBootstrap.cs`)
   - `HUDRoot` with text fields (attach `AzureBayHudPresenter.cs`)
5. Wire references in inspector.
6. Enter Play Mode and test affection/mood/economy tick.

## Cubism Integration Notes
- Keep Cubism model references in scene and bind via your own presenter.
- Drive expression parameters from `CharacterRuntime.Mood` + interaction events.
- Suggested mapping:
  - happy: `ParamEmotion_Happy`
  - tired: `ParamEmotion_Tired`
  - angry: `ParamEmotion_Angry`

## Folder Layout
- `Assets/AzureBay/Scripts/Bootstrap` startup scene composition
- `Assets/AzureBay/Scripts/Core` save/state core
- `Assets/AzureBay/Scripts/Character` character runtime + config
- `Assets/AzureBay/Scripts/Economy` building + production logic
- `Assets/AzureBay/Scripts/UI` sample presenter

