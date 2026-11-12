# Kingdom Rush Genesis Summon Trainer v1.3

An unofficial single-player mod for the Windows Steam edition of Kingdom Rush Genesis. The panel defaults to English. Select **简体中文** in its title bar to switch languages and **English** to switch back. The switch applies to the mod panel and its summoned unit names.

## 📥 下载 / Download

[进入发布下载页面 / Open releases](https://github.com/blue-earth411/kr6-summon-trainer/releases)

选择最新发布，在 **Assets** 中下载 **KR6SummonPublic-1.3.0-win.zip**，解压后按下方说明安装。 / Open the latest release, download **KR6SummonPublic-1.3.0-win.zip** under **Assets**, then extract it and follow the installation steps below.

## Basic features

- **Summon allies:** 15 unit types work with the base package, including the custom Arcane Archmage. The optional local Vengeance importer adds 27 other units, for 42 total.
- **Continuous placement:** Select a unit and left-click walkable ground to summon repeatedly. Right-click, select the same button again, or press Esc to cancel placement.
- **Move and inspect:** Select a summon to view its attributes, then click walkable ground to move it. Linirean Reinforcements move together as a pair.
- **Remove summons:** Toggle Remove Summons or press F10, then click a summon. Right-click or press Esc to leave the mode.
- **Gold mode:** Free summoning is the default. Enable Gold Summon Mode to show prices and deduct gold per purchase; insufficient gold blocks the purchase.
- **Add gold:** Press F7 to add 500 gold during a battle.
- **Experience multipliers:** Independently toggle 20× hero XP and 20× power XP in the panel.
- **Panel controls:** Switch between English and Simplified Chinese, browse faction tabs, drag the title bar, and collapse or expand with F6. The collapsed panel is also draggable.
- **Pause support:** Summons ordered while paused enter battle after play resumes.
- **Save preservation:** The public installer adds the mod to the game's save directory; reinstalling or uninstalling preserves save files.

| Shortcut | Action |
| --- | --- |
| F6 | Show/hide the panel |
| F7 | Add 500 gold |
| F8 | Select Classic Paladin for summoning |
| F9 | Select Northern Berserker for summoning |
| F10 | Toggle Remove Summons |
| Esc / right-click | Cancel the current placement/removal mode |

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

### 基础功能

- **召唤友军：**基础包直接提供15种兵种，包含自制奥术大魔导；可选导入本机《复仇》后再增加27种，总计42种。
- **连续召唤：**选择兵种后，左键点击可行走地面即可连续放置；再次点同一兵种、右键或按 Esc 取消。
- **移动与属性：**选中召唤单位查看属性，再点击地面移动；利尼维亚援兵按双人一组移动。
- **删除部队：**开启删除模式或按 F10，再点击召唤单位删除；右键或 Esc 退出模式。
- **金币召唤：**默认免费；开启金币模式后显示价格并扣金币，余额不足时无法购买。
- **增加金币：**战斗中按 F7 增加500金币。
- **经验倍率：**面板中可分别开启或关闭英雄经验20倍、法术经验20倍。
- **面板操作：**支持中英文切换、阵营分页、拖动标题栏，以及 F6 收起/展开；收起后也能拖动。
- **暂停下单：**暂停时可以召唤，恢复后单位入场。
- **保留存档：**公开版安装器将模组加入游戏存档目录，覆盖安装或卸载均保留存档。

| 快捷键 | 功能 |
| --- | --- |
| F6 | 显示/收起面板 |
| F7 | 增加500金币 |
| F8 | 选择召唤经典圣骑士 |
| F9 | 选择召唤北国狂战士 |
| F10 | 切换删除召唤部队模式 |
| Esc / 右键 | 取消当前召唤或删除模式 |

### v1.3 更新

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
