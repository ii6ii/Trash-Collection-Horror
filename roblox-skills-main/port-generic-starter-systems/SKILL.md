---
name: port-generic-starter-systems
description: Перенос generic стартовых систем из cursed-lb в новый Roblox-репо — Admin Ban/Kick/Unban + RegisterAction + F2 без CLB-фич, Bootstrap/LifecycleRunner/manifests, UIManager, SoundSystem+SoundCues stub, RemoteThrottle, Argon default.project.json. Использовать при заведении стартового каркаса нового Roblox-репозитория, вычленении AdminService из мегамодуля существующей игры, или когда просят перенести «старые системы» без фич конкретной игры.
---

# Port generic starter systems (из CLB)

## Цель

Не копировать весь `AdminService` CLB (~50KB, Mates/Rebirth/Revenge/Curse/Brainrot). Вычленить **generic-каркас** для нового плейса.

## Что переносить

| Система | Что брать | Что выкинуть |
| :--- | :--- | :--- |
| Admin | `RegisterAction`, auth (`UserIds` / Group / `AllowStudio`), Ban/Kick/Unban через `BanKickManager`, mount F2 `AdminClient` | вкладки/actions Mates, Rebirth, Revenge, Curse, BrainrotBoss, GiveCash/LuckyBlock и пр. |
| Bootstrap | `Bootstrap.server`, `ClientBootstrap`, `ServerManifest` / `ClientManifest`, `LifecycleRunner`, `BootStatus`, `Profiler` | feature-сервисы игры |
| UIManager | Open/Close/Toggle/Register, remote watch, `ScreenGuiWhitelistState`, `GuiVisibilityScope`, `GuiRevealMotion` | экраны CLB |
| Sound | `SoundSystem` + thin `SoundCues`; в каталоге обязателен `Mix` (Master/Channels/Subgroups) | полный SoundCatalog CLB |
| Security | `RemoteThrottle.new(cooldown)` — в CLB часто **нет**, писать/брать из стартера | — |
| Toolchain | `default.project.json` (`$keepUnknowns`), `aftman.toml` (argon/selene/stylua), `selene.toml` + `testez.yml` | Rojo-only ожидания |

## Admin: контракт

1. `Init`: при `Admin.Enabled` зарегистрировать только `Ban` / `Kick` / `Unban`, повесить `RemoteFunction`.
2. `RegisterAction(name, handler)` — публичный API для будущих QA-команд новой игры.
3. `Start`: mount client script админам в PlayerGui.
4. F2-панель: одна вкладка Moderation (target, duration −1=Kick / 0=perm ban, Unban).
5. Если в игре есть `FirstPersonCursor` — вокруг open/close панели `AcquireUi`/`ReleaseUi` (иначе LockCenter ломает клики). Alt = hold-free, не замена Acquire для модалок.

## RemoteThrottle

```lua
local throttle = RemoteThrottle.new(cooldownSeconds)
if not throttle:Allow(player) then
	return
end
```

Подписка на remotes с cooldown (пример: music settings). `Clear(player)` / `Reset()` для тестов.

## SoundCatalog.Mix — блокер bootstrap

`SoundSystemModules/Config` читает `SoundCatalog.Mix.*` при `require`. Без `Mix` падает клиентский bootstrap (цепочка UIManager → SoundCues → SoundSystem → Config). Минимальный stub:

```lua
Mix = {
	Master = 1,
	Channels = { Sounds = 2, Music = 0.7 },
	Subgroups = { UI = 1, Gameplay = 1, Rewards = 1, Ambient = 1, Lobby = 1, Reveal = 1 },
}
```

Пустые `SoundId` в Entries + guard в `SoundCues` = no-op, не ошибка.

## Argon

1. `default.project.json` мапит `src/ReplicatedStorage|ServerScriptService|StarterPlayerScripts`.
2. `argon plugin` (раз) → `argon serve` → Connect в Studio.
3. `$keepUnknowns: true` сохраняет Studio-only GUI/карту.

## Скрытые зависимости

- `GuiRevealMotion` (под `GuiVisibilityScope`/`ScreenGuiWhitelistState`, значит и под UIManager) требует `ReplicatedStorage/Modules/MotionCurves` — файл лежит рядом с `SoundSystem.luau`, а не в `UIManagement/`, и таблица переноса его не называет. Без него клиентский bootstrap падает на `require`. Переносить вместе с UIManager.
- `$keepUnknowns` в `default.project.json` — расширение Argon, штатный Rojo (и любой sourcemap-тул на его основе, например `luau-lsp analyze` вне Studio) его не понимает и валит генерацию sourcemap. Для статического анализа без Studio собирать копию project-файла без этого ключа, а не чинить основной.

## Чеклист перед «готово»

- [ ] В AdminService нет require конфигов Mates/Rebirth/Revenge/Boss
- [ ] В F2 нет вкладок CLB-геймплея
- [ ] `SoundCatalog.Mix` есть
- [ ] `RemoteThrottle` лежит в `ReplicatedStorage/Modules/Security` и хотя бы один consumer
- [ ] `MotionCurves` перенесён вместе с UIManager, клиентский bootstrap не падает на require
- [ ] Есть `default.project.json` + `aftman.toml`; `argon sourcemap` проходит
- [ ] `stylua --check src` и `selene src` зелёные
- [ ] Если оценка ≥1ч — назван один из четырёх исходов гейта (`/coding-task-skill-gate`)

## Антипаттерны

- Копипаст всего `AdminService.luau` / `AdminClient` из CLB «как есть»
- Ленивый remote admin только после первого F2 без создания в `Init`/`Start`
- Игнор сабмодуля `.claude/skills` в новом игровом репо
