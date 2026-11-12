# Kingdom Rush Genesis Summon Trainer v1.3

## 📥 下载修改器 / Download

[点击进入下载页面 / Open downloads](https://github.com/blue-earth411/kr6-summon-trainer/releases)

选择最新版本，在 Assets 中下载 KR6SummonPublic-1.3.0-win.zip，解压后按 README 安装。

An unofficial single-player mod for the Windows Steam edition of Kingdom Rush Genesis. The panel defaults to English. Select **简体中文** in its title bar to switch languages and **English** to switch back. The switch applies to the mod panel and its summoned unit names.

## What's new in v1.3

- **Arcane Archmage** is available in **Linirea** immediately, with **no Vengeance import required**. It costs **1800 gold**, has **742 HP** and **95% magic resistance**.
- Single-target Arcane Ray (+20% native damage), multi-target Magic Rain, enemy/ally teleport, short walks and unlimited long-distance self-teleport, max-level Teleportation Sigil, Disintegration, and +40% tower empowerment with a visible badge.
- Arcane Forge: one of six native weapons hovers above the head for 0.8s before firing; 84–132 area damage, explosion radius **67.5** (Big Bertha basic shell blast radius), 5s cooldown.
- Phantoms: two copies with 30% HP/damage, melee blocking/attacks and Magic Rain; last 10s, 20s cooldown, purple-smoke exits. The Archmage has a close-up portrait and an arcane-dissolution death animation.
- Base roster: **15** units. The existing optional Vengeance import adds 27 other units, for **42** total. The Archmage itself never needs that import.

## Install

1. Close the game. If your installation has the private trainer that replaces `main.kra`, restore the stock game through Steam's **Verify integrity of game files** first.
2. Extract `KR6SummonPublic-1.3.0-win.zip`, then run `install.bat` from the extracted folder.
3. In Steam, open the game's **Properties → General → Launch Options** and add `-custom_script kr6_summon_public`. If you already use a `-custom_script` argument, replace that argument and its value for this launch.
4. Start the game from Steam. Open a battle and press **F6** if the panel is collapsed.

The installer adds a mod loader and its own folder to `%APPDATA%\kingdom_rush_genesis`. The mod targets Steam build **26280216**. An update to the game may require a compatible mod build.

To upgrade from v1.1 or v1.2, close the game and run the new `install.bat`. Your existing launch option and imported Vengeance assets can be reused.

## Optional Vengeance roster

The base mod has 15 units. If you have the Windows Steam edition of **Kingdom Rush Vengeance** installed, you can add 27 more units. Close Genesis, install Python 3.10 or later with the Windows `py` launcher, and install Pillow with `py -3 -m pip install Pillow`. Run `import-vengeance.bat` from the extracted package. It looks for Vengeance in your Steam libraries. If auto-detection fails, run `import-vengeance.bat --game "D:\path\to\Kingdom Rush Vengeance"`.

The importer generates the optional textures, animation data and audio on your computer. They appear under the faction tabs after restarting Genesis. For the full Chinese roster, install the Windows Simplified Chinese supplemental fonts if some characters appear as boxes.

## Remove

Close the game, remove `-custom_script kr6_summon_public` from Steam Launch Options, then run `uninstall.bat`. The script removes the mod's files and preserves the save files.

## Controls

- Drag the title bar to reposition the panel. You can also drag the collapsed window.
- Select a unit button, then left-click walkable ground to summon repeatedly. Select the same button again or right-click the battlefield to cancel.
- Select a summoned unit, then click the ground to move it. Select either Linirean reinforcement to move the pair together.
- Toggle **Remove Summons** or press **F10**, then click a summoned unit to remove it. Toggle the mode again or right-click the battlefield to exit.
- **F7** adds 500 gold. **F8** selects the Classic Paladin. **F9** selects the Northern Berserker. **F6** toggles the panel.

See [Features / 功能清单](功能清单.md) for the roster and base gold prices. The mod reads native content from your installed games. The release includes the mod code, custom artwork and the local importer. Kingdom Rush and its game assets belong to their respective owners. This is an unofficial fan project.

## 简体中文

适用于 Windows Steam 版《Kingdom Rush Genesis》，目标构建号 **26280216**。面板默认英文，点击标题栏的 **简体中文** 即可切换。

v1.3 新增无需导入《复仇》即可使用的**奥术大魔导**，位于「利尼维亚」，售价 **1800 金币**、生命 **742**、魔抗 **95%**。保留私人测试版 v78 已验收的完整技能：单敌射线、多敌魔法雨、敌我传送、自身瞬移、符印、分解、塔强化、幻铸和双幻影，以及头部特写、步行、死亡和退场动画。基础阵容共 **15 种**；可选导入四代后共 **42 种**。大魔导本身不需要四代或导入步骤。

退出游戏并解压发行包，双击 `install.bat`，在 Steam 游戏属性的「启动选项」中填写 `-custom_script kr6_summon_public`，然后从 Steam 启动。若已经装过替换 `main.kra` 的私人版，请先用 Steam 验证游戏文件完整性以恢复原版。

从公开版 v1.1 或 v1.2 升级时，退出游戏后运行新版的 `install.bat` 即可，原有 Steam 启动参数和已导入的《复仇》素材可继续使用。

想开启另外 **27 种《复仇》兵种**，先安装 Steam 版《复仇》、Python 3.10 或更新版本和 Pillow（`py -3 -m pip install Pillow`），再运行 `import-vengeance.bat`。它会从 Steam 库里找游戏并在本机生成素材。重启 Genesis 后即可在对应阵营页召唤。

卸载时退出游戏，删除该启动参数，再运行 `uninstall.bat`。详见[功能清单](功能清单.md)。


## Archmage details / 大魔导技能

| Feature / 功能 | Settings / 参数 |
| --- | --- |
| Normal attacks / 普攻 | 1 enemy: native Arcane Ray ×1.2; 2+: five-hit Magic Rain / 单敌射线，多敌魔法雨 |
| Combat teleport / 战斗传送 | Up to 4 units, shared 15s cooldown; enemies retreat 25 nodes / 最多4人，共用15秒冷却，敌退25节点 |
| Self movement / 自身移动 | Walk within150; self-teleport beyond150 with no cooldown / 近处步行，远处无冷却瞬移 |
| Sigil / 符印 | Max-level native effect,30s cooldown / 原生满级效果，CD30秒 |
| Disintegration / 分解 | Native eligibility and immunities,22s cooldown / 遵守原生目标与免疫，CD22秒 |
| Empowerment / 塔强化 | Range220,+40% damage for8s,22s cooldown,no stacking / 范围220，增伤40%持续8秒，CD22秒，不叠加 |
| Arcane Forge / 幻铸 | Damage84–132,blast radius67.5,CD5s / 武器头顶展示0.8秒后发射 |
| Phantoms / 分身 | Two copies,30% HP/damage,10s lifetime,CD20s / 两个幻影，近战与魔法雨，本体死亡同步退场 |

Only enemy knockback teleport is allowed as an active combat spell while the Archmage is in melee; other active spells wait until melee ends. / 大魔导近战时仅允许敌军后退传送，其他主动技能仍禁用。

All game textures and sounds are read from the installed Genesis game. The package contains only mod code and custom artwork. / 大魔导所需原生贴图、特效和音效均从本机六代读取，发行包仅包含修改器代码与自制素材。
