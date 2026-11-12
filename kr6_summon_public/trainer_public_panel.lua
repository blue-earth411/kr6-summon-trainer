-- KR6 Genesis build 26280216. Integrated into the original Steam game; native save identity is preserved.
local T = {visible=true, hero=false, power=false, gold_mode=false, placing=false, deleting=false, selected=nil,
    units={}, notice="F6 收起 / 展开修改器", notice_until=0, hooks=false,hero_xp=0,power_xp=0}
local E, SU, SYS, GR, U, I
local G=love.graphics
local unpack=unpack or table.unpack
local troops={
    arcane_sage={archmage=true,name="奥术大魔导",skills="射线/魔法雨·幻铸·双幻影"},
    genesis_militia={native=true,entity="soldier_militia_kr1",name="经典民兵",skills="经典一级兵营"},
    genesis_footman={native=true,entity="soldier_footmen_kr1",name="经典步兵",skills="经典二级兵营"},
    genesis_knight={native=true,entity="soldier_knight_kr1",name="经典骑士",skills="经典三级兵营"},
    genesis_order={native=true,group="knights",entity="soldier_knights_lvl4",name="守卫骑士团",skills="四级兵营 / 技能全满"},
    genesis_wildcat={native=true,group="wildcat",entity="soldier_wildcat_lvl4",name="野猫女猎手",skills="四级兵营 / 技能全满"},
    genesis_miner={native=true,group="miners",entity="soldier_miners_lvl4",name="淘金矿工",skills="近距离步行 / 满级破土攻击"},
    genesis_fallen={native=true,group="crossbows",entity="soldier_crossbows_ult",name="死魂骑士",skills="恐惧因子 3 / 持续 30 秒"},
    genesis_subject={native=true,group="alchemist",entity="soldier_alchemist_skill_b_lvl3",name="实验人员",skills="技能 3 / 真实伤害 / 持续 30 秒"},
    genesis_elemental={native=true,group="sunray_master",entity="soldier_sunray_master_lvl3",name="小型元素",skills="技能 3 / 近战拦截"},
    paladin={entity="soldier_paladin",tower="tower_paladin_kr1",name="经典圣骑士",
        skills="治疗 3 / 盾甲 1 / 圣击 3"},
    barbarian={entity="soldier_barbarian",tower="tower_barbarian_kr1",name="北国狂战士",
        skills="双斧 3 / 旋风 3 / 飞斧 3"},
    captain={imported=true,name="部队队长",skills="晋升我方普通士兵"},
    magus={imported=true,name="奥术法师",skills="敌退友进最多 4 人 / 共用冷却 15 秒"},
    shield={imported=true,name="持盾卫士",skills="脱战 90% 护甲"},
    djinni={imported=true,name="灯神",skills="变羊冷却 20 秒 / 单体 / 范围 250"},
    assassin={imported=true,name="刺客大师",skills="闪避 15% / 致命一击 15%"},
    footman={imported=true,name="步兵",skills="近战拦截 / 30% 护甲"},
    musketeer={imported=true,name="火枪手",skills="射程 150 / 狙击射程 487.5 / 近战拦截"},
    archer={imported=true,name="军团弓箭手",skills="生命 200 / 射箭间隔 0.6 秒 / 射程 210"},
    cavalry={imported=true,name="骑兵",skills="移动冲锋 / 阵亡后下马"},
    huntress={imported=true,name="北国女猎手",skills="近战双击 / 飞斧射程 187.5"},
    ranger={imported=true,name="精灵游侠",skills="三连射 / 射程 262.5 / 30% 魔抗"},
    wildling={imported=true,name="北国野人",skills="近战拦截 / 20% 护甲"},
    legionnaire={imported=true,name="军团士兵",skills="近战拦截"},
    mecha={imported=true,name="机械矮人 MK.9",skills="70% 护甲 / 范围重击"},
    gunman={imported=true,name="锡须枪手",skills="伤害提升 20% / 火弹射程 225"},
    valkyrie={imported=true,name="女武神",skills="70% 护甲 / 唤回北国友军亡魂"},
    warhammer={imported=true,name="战锤守卫",skills="生命 122 / 近战 6–8 / 20% 护甲"},
    sorcerer={imported=true,name="高阶巫师",skills="变羊射程 225 / 冷却 20 秒 / 范围近战"},
    templar={stage_native=true,name="圣殿骑士",skills="重斩流血 / 圣杯20%复活60%血"},
    falconer={imported=true,name="驯鹰师",skills="40% 护甲 / 近战 / 放鹰射程 352.5"},
    camel={imported=true,name="骆驼骑兵",skills="近战 / 骆驼阵亡后军团士兵继续作战"},
    mystic={imported=true,name="沙漠秘术师",skills="法术 36–52 / 近战 12–19 / 治疗"},
    alliance_paladin={alliance=true,name="联盟圣骑士",skills="蓝色圣骑士 / 治愈祷告 3"},
    alliance_captain={alliance=true,name="圣骑士队长",skills="紫色队长 / 治愈祷告 3 / 身先士卒 1"},
    elite_longbow={longbow=true,name="精英长弓手",skills="弹射箭 / 三连击流血 / 冷却均 10 秒"},
    linirea_reinforcements={reinforcements=true,name="利尼维亚援兵",skills="双人编队 / 荆棘护甲 10% / 脱战每秒回血 15"},
    royal_archer={royal=true,name="皇家弓箭手",skills="生命 150 / 护甲 30% / 三连发 3"},
    geomancer={imported=true,name="石须地卜师",skills="近战石化 / 生命容量 3.3 倍"},
    ice_witch={imported=true,name="冰霜女巫",skills="冻结 / 普通地面 3 冰晶 / 冰面不限"},
    alchemist={imported=true,name="硫磺炼金师",skills="射程 225 / 药瓶 / 治疗矮人"},
    frost_giant={imported=true,name="冰霜巨人",skills="60% 护甲 / 近战重击"},
    nomad={imported=true,name="游牧战士",skills="飞刀射程 131.25 / 暗影跳跃"},
    elephant={imported=true,name="战象",skills="近战 72–108 / 象背弓手 10–13 / 射程 231"},
    legion_captain={legion=true,name="军团上尉",skills="660 生命 / 50% 护甲 / 护卫组 20 秒"},
    shard={imported=true,name="冰晶",skills="女巫召唤 / 80% 魔抗 / 近战双击"},
    eagle={imported=true,name="沙漠鹰",skills="飞行追击 / 只攻击地面敌军"},
    draugr={imported=true,name="北国亡魂",skills="近战拦截 / 80% 魔抗"},
    dismounted={imported=true,name="下马圣骑士",skills="近战拦截 / 范围重击"}
}
local troop_order={"paladin","barbarian","captain","magus","shield","djinni","assassin","footman","musketeer","archer","cavalry","huntress","ranger","wildling","legionnaire","mecha","gunman","valkyrie","warhammer","sorcerer","templar","falconer","camel","mystic","alliance_paladin","alliance_captain","royal_archer","geomancer","ice_witch","alchemist","frost_giant","nomad","elephant","legion_captain","elite_longbow","linirea_reinforcements","arcane_sage",
    "genesis_militia","genesis_footman","genesis_knight","genesis_order","genesis_wildcat","genesis_miner","genesis_fallen","genesis_subject","genesis_elemental"}
-- Prices are per purchase and include automatically spawned companions.
-- Anchors: KR6 basic barracks/archer 70, mage 100; level-four knights total 560 for 3 respawning soldiers.
local prices={
    arcane_sage=1800,
    paladin=180,barbarian=180,captain=340,magus=480,shield=320,djinni=420,assassin=360,
    footman=110,musketeer=180,archer=95,cavalry=320,huntress=65,ranger=150,wildling=55,
    legionnaire=85,mecha=650,gunman=75,valkyrie=380,warhammer=35,sorcerer=950,templar=180,
    falconer=260,camel=200,mystic=300,alliance_paladin=120,alliance_captain=210,
    royal_archer=220,geomancer=340,ice_witch=300,alchemist=200,frost_giant=650,nomad=150,elephant=1250,legion_captain=550,elite_longbow=320,
    linirea_reinforcements=210,
    genesis_militia=25,genesis_footman=45,genesis_knight=70,genesis_order=240,genesis_wildcat=260,
    genesis_miner=160,genesis_fallen=180,genesis_subject=130,genesis_elemental=90
}
T.prices=prices
-- Keep action IDs and F8/F9 stable while arranging buttons by faction.
local troop_groups={
    {name="北国",color={151,198,238},kinds={"barbarian","huntress","wildling","valkyrie","ice_witch","frost_giant"}},
    {name="利尼维亚",color={132,185,248},kinds={"footman","linirea_reinforcements","captain","paladin","shield","alliance_paladin","alliance_captain","cavalry","ranger","royal_archer","elite_longbow","musketeer","magus","arcane_sage","sorcerer"}},
    {name="沙漠军团",color={243,208,119},kinds={"legion_captain","templar","legionnaire","archer","assassin","nomad","camel","elephant","falconer","mystic","djinni"}},
    {name="矮人",color={228,170,133},kinds={"warhammer","gunman","mecha","geomancer","alchemist"}},
    {name="六代",color={166,205,147},kinds={"genesis_militia","genesis_footman","genesis_knight","genesis_order","genesis_wildcat","genesis_miner","genesis_fallen","genesis_subject","genesis_elemental"}}
}
local function available(kind)
    local def=troops[kind]
    return def and not (def.alliance or def.royal or def.legion) and (not def.imported or T.vengeance)
end
T.available=available
local function faction_tabs(x,y,w)
    local tabs={}
    local tab_width=(w-18-2*#troop_groups)/#troop_groups
    for i,group in ipairs(troop_groups)do
        tabs[i]={x=x+10+(i-1)*(tab_width+2),y=y+118,w=tab_width,h=26,name=group.name}
    end
    return tabs
end
local english={
    ["近战与魔法雨 / 本体30% / 10秒"]="Melee/Rain | 30% stats | 10s",
    ["奥术大魔导"]="Arcane Archmage",
    ["奥术幻影"]="Arcane Illusion",
    ["射线/魔法雨·幻铸·双幻影"]="Ray/Rain | Forge | Phantoms",
    ["奥术大魔导正在传送至目的地"]="Arcane Archmage is teleporting.",
    ["F6 收起 / 展开修改器"]="F6 toggles the panel",
    ["经典圣骑士"]="Classic Paladin",
    ["治疗 3 / 盾甲 1 / 圣击 3"]="Healing 3 / Shield 1 / Holy Strike 3",
    ["北国狂战士"]="Northern Berserker",
    ["双斧 3 / 旋风 3 / 飞斧 3"]="Dual Axes 3 / Whirlwind 3 / Throwing Axes 3",
    ["精英长弓手"]="Elite Longbowman",
    ["弹射箭 / 三连击流血 / 冷却均 10 秒"]="Ricochet Arrow / Triple Slash with bleed / 10s each",
    ["利尼维亚援兵"]="Linirean Reinforcements",
    ["双人编队 / 荆棘护甲 10% / 脱战每秒回血 15"]="Two soldiers / 10% thorn damage / 15 HP/s out of combat",
    ["北国"]="Northlands",
    ["利尼维亚"]="Linirea",
    ["操作失败，请查看 trainer.log"]="Action failed. See the game log.",
    ["修改器已就绪：Steam 原版存档"]="Summon Trainer is ready",
    ["利尼维亚援兵已入场：选中任意一人即可整组移动"]="Reinforcements ready. Select either soldier to move both.",
    ["援兵入场异常，金币已退还"]="Reinforcements failed to deploy. Gold refunded.",
    ["援兵入场异常，请查看 trainer.log"]="Reinforcements failed to deploy. See the game log.",
    ["召唤后已阵亡"]=" died after deployment.",
    ["已召唤：可继续左键地面召唤"]=" deployed. Click the ground to summon more.",
    ["已召唤：左键选中，再左键地面移动"]=" deployed. Select it, then click the ground to move.",
    ["入场异常，金币已退还"]=" failed to deploy. Gold refunded.",
    ["入场异常，请查看 trainer.log"]=" failed to deploy. See the game log.",
    ["请先进入战场"]="Enter a battle first.",
    ["金币 +500；当前 "]="+500 gold. New total: ",
    ["该处没有足够的可行走地面供援兵入场"]="Choose an open area for both soldiers to enter.",
    ["双人援兵已排队：请恢复游戏"]="Reinforcements queued. Resume the battle.",
    ["利尼维亚援兵正在进入战场…"]="Reinforcements are entering…",
    ["金币不足：%s需 %d 金，当前 %d 金"]="%s costs %d gold. You have %d.",
    ["请点击可行走的地面"]="Click walkable ground.",
    ["已付 %d 金："]="%d gold paid. ",
    ["召唤已排队：请恢复游戏"]=" queued. Resume the battle.",
    ["正在进入战场…"]=" is entering…",
    ["请先选择存活的召唤士兵"]="Select a living summoned unit first.",
    ["利尼维亚援兵正在整组移动"]="Reinforcements are moving together.",
    ["该处放不下队形，请换个位置"]="The formation does not fit here. Choose an open area.",
    ["该处不能站立，请选择地面"]="The unit cannot stand here. Choose walkable ground.",
    ["正在前往指定位置"]=" is moving to the destination.",
    ["利尼维亚援兵已整组删除"]="Both reinforcements removed.",
    ["已删除：可以继续点击部队"]=" removed. Click another unit to remove it.",
    ["请点击修改器召唤的部队"]="Click a unit summoned by this mod.",
    ["金币 +500   [F7]"]="+500 Gold [F7]",
    ["召唤"]="",
    ["英雄经验 20 倍："]="Hero XP ×20: ",
    ["法术经验 20 倍："]="Power XP ×20: ",
    ["开启"]="On",
    ["停用"]="Off",
    ["删除召唤部队 [F10]"]="Remove Summons [F10]",
    ["金币召唤模式："]="Gold mode: ",
    ["开启（显示价格）"]="On (prices shown)",
    ["停用（免费召唤）"]="Off (free summons)",
    ["删除模式"]="Remove Mode",
    ["金币召唤"]="Gold Mode",
    ["召唤助手"]="Summons",
    [" 种"]=" types",
    ["删除模式：左键召唤部队，再点取消"]="Click summoned units to remove them. Click the button again to stop.",
    ["连续召唤：左键地面，再点选项取消"]="Click the ground to summon. Click the unit button again to stop.",
    ["左键选中显示属性，再左键地面移动"]="Select a unit for stats, then click the ground to move it.",
    ["已加载：进入战场后使用面板"]="Loaded. Enter a battle to use the trainer.",
    ["本关倍率经验：英雄 +"]="Bonus XP this battle: Hero +",
    ["  法术 +"]="  Power +",
    ["援兵 %d/2 人 · 荆棘反伤 10%% · 脱战回血"]="%d/2 soldiers · 10%% thorns · Regenerates out of combat",
    ["："]=": ",
    ["生命 %d/%d  近战物理 %d-%d"]="HP %d/%d  Physical melee %d-%d",
    ["远程物理 %d-%d"]="Physical ranged %d-%d",
    ["生命 %d/%d  攻击 %d-%d"]="HP %d/%d  Damage %d-%d",
    ["护甲 %d%%  魔抗 %d%%"]="Armor %d%%  Magic resistance %d%%",
    ["连续召唤"]="Continuous summon: ",
    ["：再点选项取消"]=". Click its button again to stop.",
    ["已取消召唤"]="Summoning cancelled.",
    ["英雄经验："]="Hero XP: ",
    ["法术经验："]="Power XP: ",
    ["20 倍"]="×20",
    ["正常"]="Normal",
    ["金币召唤已开启：按标价扣费，金币不足不召唤"]="Gold mode on. Summons charge the listed price.",
    ["金币召唤已停用：恢复免费召唤"]="Gold mode off. Summons are free.",
    ["删除模式：左键召唤部队，再点选项取消"]="Click summoned units to remove them. Click the button again to stop.",
    ["已取消删除模式"]="Remove mode cancelled.",
    ["召唤助手 v1.3"]="Summon Trainer v1.3",
    ["已取消操作模式"]="Action mode cancelled.",
    ["语言已切换"]="Language switched to English.",
    ["六代"]="Genesis",
    ["经典民兵"]="Classic Militia",
    ["经典一级兵营"]="Level 1 classic barracks",
    ["经典步兵"]="Classic Footman",
    ["经典二级兵营"]="Level 2 classic barracks",
    ["经典骑士"]="Classic Knight",
    ["经典三级兵营"]="Level 3 classic barracks",
    ["守卫骑士团"]="Knights Order",
    ["野猫女猎手"]="Wildcat Huntress",
    ["四级兵营 / 技能全满"]="Level 4 barracks / Maxed skills",
    ["淘金矿工"]="Gold Prospector",
    ["近距离步行 / 满级破土攻击"]="Walks short distances / Maxed Emerging Blast",
    ["死魂骑士"]="Fallen Knight",
    ["恐惧因子 3 / 持续 30 秒"]="Fear Factor 3 / Lasts 30s",
    ["实验人员"]="Test Subject",
    ["技能 3 / 真实伤害 / 持续 30 秒"]="Skill level 3 / True damage / Lasts 30s",
    ["小型元素"]="Minor Elemental",
    ["技能 3 / 近战拦截"]="Skill level 3 / Blocks enemies",
    ["矿工正挖地前往目的地"]="Prospector is tunneling to the destination.",
    ["部队队长"]="Troop Captain",
    ["晋升我方普通士兵"]="Promotes allied footmen",
    ["奥术法师"]="Arcane Magus",
    ["敌退友进最多 4 人 / 共用冷却 15 秒"]="Teleports up to 4 units / Shared 15s cooldown",
    ["持盾卫士"]="Shieldbearer",
    ["脱战 90% 护甲"]="90% armor out of combat",
    ["灯神"]="Djinni",
    ["变羊冷却 20 秒 / 单体 / 范围 250"]="Single-target polymorph / Range 250 / 20s cooldown",
    ["刺客大师"]="Master Assassin",
    ["闪避 15% / 致命一击 15%"]="15% dodge / 15% killing blow",
    ["步兵"]="Footman",
    ["近战拦截 / 30% 护甲"]="Blocks enemies / 30% armor",
    ["火枪手"]="Musketeer",
    ["射程 150 / 狙击射程 487.5 / 近战拦截"]="Range 150 / Snipe range 487.5 / Blocks enemies",
    ["军团弓箭手"]="Legion Archer",
    ["生命 200 / 射箭间隔 0.6 秒 / 射程 210"]="200 HP / One arrow every 0.6s / Range 210",
    ["骑兵"]="Cavalier",
    ["移动冲锋 / 阵亡后下马"]="Charges while moving / Dismounts when defeated",
    ["北国女猎手"]="Northern Huntress",
    ["近战双击 / 飞斧射程 187.5"]="Double melee strike / Throw range 187.5",
    ["精灵游侠"]="Elven Ranger",
    ["三连射 / 射程 262.5 / 30% 魔抗"]="Triple shot / Range 262.5 / 30% magic resistance",
    ["北国野人"]="Northern Wildling",
    ["近战拦截 / 20% 护甲"]="Blocks enemies / 20% armor",
    ["军团士兵"]="Legionnaire",
    ["近战拦截"]="Blocks enemies",
    ["机械矮人 MK.9"]="MechaDwarf MK.9",
    ["70% 护甲 / 范围重击"]="70% armor / Heavy area attack",
    ["锡须枪手"]="Tinbeard Gunman",
    ["伤害提升 20% / 火弹射程 225"]="20% bonus damage / Range 225",
    ["女武神"]="Valkyrie",
    ["70% 护甲 / 唤回北国友军亡魂"]="70% armor / Revives fallen Northlanders",
    ["战锤守卫"]="Warhammer Guard",
    ["生命 122 / 近战 6–8 / 20% 护甲"]="122 HP / Melee 6-8 / 20% armor",
    ["高阶巫师"]="High Sorcerer",
    ["变羊射程 225 / 冷却 20 秒 / 范围近战"]="Polymorph range 225 / 20s cooldown / Area melee",
    ["圣殿骑士"]="Templar",
    ["重斩流血 / 圣杯20%复活60%血"]="Heavy slash bleeds / 20% revive chance at 60% HP",
    ["驯鹰师"]="Falconer",
    ["40% 护甲 / 近战 / 放鹰射程 352.5"]="40% armor / Melee / Eagle range 352.5",
    ["骆驼骑兵"]="Camel Rider",
    ["近战 / 骆驼阵亡后军团士兵继续作战"]="Melee / Spawns a Legionnaire on defeat",
    ["沙漠秘术师"]="Sand Mystic",
    ["法术 36–52 / 近战 12–19 / 治疗"]="Magic 36-52 / Melee 12-19 / Heals allies",
    ["联盟圣骑士"]="Alliance Paladin",
    ["蓝色圣骑士 / 治愈祷告 3"]="Blue Paladin / Healing Prayer 3",
    ["圣骑士队长"]="Paladin Captain",
    ["紫色队长 / 治愈祷告 3 / 身先士卒 1"]="Purple Captain / Healing Prayer 3 / Lead by Example 1",
    ["皇家弓箭手"]="Royal Archer",
    ["生命 150 / 护甲 30% / 三连发 3"]="150 HP / 30% armor / Triple Shot 3",
    ["石须地卜师"]="Stonebeard Geomancer",
    ["近战石化 / 生命容量 3.3 倍"]="Stone form in melee / 3.3x health capacity",
    ["冰霜女巫"]="Ice Witch",
    ["冻结 / 普通地面 3 冰晶 / 冰面不限"]="Freeze / Up to 3 shards off ice / Unlimited on ice",
    ["硫磺炼金师"]="Sulfur Alchemist",
    ["射程 225 / 药瓶 / 治疗矮人"]="Range 225 / Potions / Heals dwarves",
    ["冰霜巨人"]="Frost Giant",
    ["60% 护甲 / 近战重击"]="60% armor / Heavy melee",
    ["游牧战士"]="Nomad",
    ["飞刀射程 131.25 / 暗影跳跃"]="Throw range 131.25 / Shadow Jump",
    ["战象"]="War Elephant",
    ["近战 72–108 / 象背弓手 10–13 / 射程 231"]="Melee 72-108 / Mounted archer 10-13 / Range 231",
    ["军团上尉"]="Legion Captain",
    ["660 生命 / 50% 护甲 / 护卫组 20 秒"]="660 HP / 50% armor / Escort group every 20s",
    ["冰晶"]="Ice Shard",
    ["女巫召唤 / 80% 魔抗 / 近战双击"]="Witch summon / 80% magic resistance / Double melee",
    ["沙漠鹰"]="Desert Eagle",
    ["飞行追击 / 只攻击地面敌军"]="Flying pursuer / Attacks ground enemies",
    ["北国亡魂"]="Draugr",
    ["近战拦截 / 80% 魔抗"]="Blocks enemies / 80% magic resistance",
    ["下马圣骑士"]="Dismounted Paladin",
    ["近战拦截 / 范围重击"]="Blocks enemies / Heavy area attack",
    ["沙漠军团"]="Desert Legion",
    ["矮人"]="Dwarves",
    ["此兵种需要导入素材"]="Import this unit's local assets first.",
    ["四代兵种已启用"]="Vengeance roster enabled",
    ["导入四代素材可解锁更多兵种"]="Import Vengeance assets to unlock more units",
    ["护卫组正在整组移动：前方双兵，后方弓手"]="Escort formation is moving together.",
    ["该处放不下队形，请选择开阔地面"]="Choose a more open location for the formation.",
    ["护卫组已整组删除"]="Escort group removed.",
    ["护卫组 %d/3 人 · 点击地面整组移动"]="Escort %d/3 / Click the ground to move the group",
    ["护卫组 %d/2 · 暂无空位，待命"]="Escort groups %d/2 / Waiting for open ground",
    ["本上尉护卫组 %d/2 · 冷却 20 秒"]="Escort groups %d/2 / 20s cooldown",
    ["冰晶 %d · 冰面不限"]="%d shards / Unlimited on ice",
    ["冰晶 %d/3 · 普通地面"]="%d/3 shards / Off ice",
    ["远程物理 "]="Physical ranged ",
    ["远程法术 "]="Magic ranged ",
}
T.language="en"
local function tr(key)
    return T.language=="zh-CN" and key or english[key] or key
end
T.notice=tr("F6 收起 / 展开修改器")

local function update_names()
    for _,messages in pairs(require('i18n').msgs or {})do
        messages.TRAINER_ARCANE_ILLUSION_NAME=tr("奥术幻影")
        for kind,def in pairs(troops)do
            messages["TRAINER_PUBLIC_"..kind:upper().."_NAME"]=tr(def.name)
        end
    end
end
local function tag_name(entity,kind)
    if not entity.info then return end
    entity.info.random_name_format=nil
    entity.info.i18n_key="TRAINER_PUBLIC_"..kind:upper()
    update_names()
end
local function refresh_selected_name()
    local gui=game and game.game_gui
    local unit=gui and gui.selected_entity
    local def=unit and unit._kr6_trainer and troops[unit._trainer_kind]
    local part=def and gui.window and gui.window.ci and gui.window:ci("infobar_part_a")
    if not part then return end
    for _,view in ipairs(part.children or {})do
        local title=not view.hidden and view:ci("title")
        if title then title.text=tr(def.name):upper() end
    end
end
local function summon_layout(x,y,w)
    local group=troop_groups[T.faction or 2]
    local half=(w-28)/2
    local top=y+149
    local kinds,slots={},{}
    for _,kind in ipairs(group.kinds)do if available(kind)then kinds[#kinds+1]=kind end end
    local headers={{name=group.name,count=#kinds,color=group.color,x=x+10,y=top,w=w-20,h=18}}
    top=top+22
    for j,kind in ipairs(kinds)do
        slots[kind]={x=x+10+((j-1)%2)*(half+8),y=top+math.floor((j-1)/2)*24,w=half,h=22,group=group.name}
    end
    return slots,headers,top+math.max(1,math.ceil(#kinds/2))*24+5
end
local hero_button,power_button=#troop_order+2,#troop_order+3
local delete_button=#troop_order+4
local gold_mode_button=#troop_order+5
local function imported()return require('kr6_summon_public.kr4_allies')end
local function note(s)
    T.notice=s; T.notice_until=love.timer.getTime()+6
    print("[KR6Trainer] "..s)
end
local function battle()
    return game and game.store and game.store.entities and game.game_gui and
        game.simulation and not game.store.game_outcome and main and main.handler and
        main.handler.active_item==game
end
local function attempt(fn,...)
    local ok,err=pcall(fn,...)
    if not ok then note(tr("操作失败，请查看 trainer.log")); print("[KR6Trainer ERROR] "..tostring(err)) end
    return ok
end
local function hooks()
    if not package.loaded.script_utils or not package.loaded.systems then return end
    E=require("entity_db"); SU=require("script_utils"); SYS=require("systems")
    GR=require("grid_db"); U=require("utils"); I=require("klove.image_db")
    assert(type(SU.hero_level_up)=="function","hero_level_up interface changed")
    assert(SYS.power_xp_tracking and type(SYS.power_xp_tracking.on_insert)=="function", "power XP interface changed")
    if T.hooked_su~=SU then
      local level_up=SU.hero_level_up
      SU.hero_level_up=function(store,this,...)
        local before=this.hero and this.hero.xp or 0
        if T.hero and this.hero and this.hero.xp_queued>0 then
            this.hero.xp_queued=this.hero.xp_queued*20
        end
        local result=level_up(store,this,...)
        if T.hero and this.hero then
            local gain=this.hero.xp-before
            T.hero_xp=T.hero_xp+gain
            if gain>0 and (T.hero_logs or 0)<5 then
                T.hero_logs=(T.hero_logs or 0)+1
                print("[KR6Trainer XP] hero "..this.id.." gained "..gain.." (20x enabled)")
            end
        end
        return result
      end
      T.hooked_su=SU
    end
    if T.hooked_sys~=SYS then
      local health_update=SYS.health.on_update
      SYS.health.on_update=function(self,dt,tick_ts,store,...)
        if store._linirea_spiked_hits then require('kr6_summon_public.trainer_reinforcements').flush_spikes(store)end
        return health_update(self,dt,tick_ts,store,...)
      end
      local power_insert=SYS.power_xp_tracking.on_insert
      SYS.power_xp_tracking.on_insert=function(self,entity,store,...)
        local p=entity.user_power
        if not T.power or not p or type(p.xp_per_use)~="number" then
            return power_insert(self,entity,store,...)
        end
        local before=p.xp_per_use; p.xp_per_use=before*20
        local status=store.ephemeral and store.ephemeral.powers_xp and store.ephemeral.powers_xp[p.power_id]
        local old_gain=status and status.xp_gain or 0
        local results={pcall(power_insert,self,entity,store,...)}
        p.xp_per_use=before
        if not results[1] then error(results[2]) end
        if status then
            local gain=status.xp_gain-old_gain
            T.power_xp=T.power_xp+gain
            if gain>0 and (T.power_logs or 0)<5 then
                T.power_logs=(T.power_logs or 0)+1
                print("[KR6Trainer XP] spell "..p.power_id.." gained "..gain.." (20x enabled)")
            end
        end
        return unpack(results,2)
      end
      T.hooked_sys=SYS
    end
    if not T.hooks then T.hooks=true; note(tr("修改器已就绪：Steam 原版存档")) end
end
local function world(x,y)
    local wx,wy=game.game_gui:s2g({x=x,y=y})
    return {x=wx,y=wy}
end
local function ground(p,e)
    local terrains=e and e.nav_grid and e.nav_grid.valid_terrains_dest
    if not terrains then terrains=e and e.nav_grid and e.nav_grid.valid_terrains end
    if e and e._ice_surface_walker then
        if imported().is_visual_ice(p,game.store) then return true end
        if terrains then terrains=require('bit').band(terrains,require('bit').bnot(TERRAIN_NOWALK)) end
    end
    if terrains then return GR:cell_is_only(p.x,p.y,terrains) end
    return true
end
local classic_group="go_towers_barrack_kr1"
local function classic_animations()
    if not T.classic_animations then
        local chunk=assert(love.filesystem.load(KR_PATH_GAME.."/data/animations/"..classic_group.."/tower_barrack_kr1.lua"))
        local animations=chunk(); T.classic_animations=animations.animations or animations
    end
    return T.classic_animations
end
local function classic_ready()
    local A=require("klove.animation_db")
    local images=require("klove.image_db")
    local checked={}
    for name,a in pairs(classic_animations()) do
        if name:find("^soldier_paladin_") or name:find("^soldier_barbarian_") then
            if not A.db[name] then return false,"animation "..name end
            for n=a.from,a.to do
                local key=string.format("%s_%04i",a.prefix,n)
                local frame=images.db_atlas[key]
                if not frame then return false,"frame "..key end
                if not checked[frame.atlas] then
                    if not images:i(frame.atlas,true) then return false,"texture "..tostring(frame.atlas) end
                    checked[frame.atlas]=true
                end
            end
        end
    end
    return true
end
local function load_troop_images()
    local ready,why=classic_ready()
    if ready then return end
    print("[KR6Trainer ASSETS] reload classic troops: "..why)
    local director=require("director")
    local images=require("klove.image_db")
    -- Native preload marks a group loaded before its images finish loading.
    -- Recover an incomplete group without increasing its existing reference count.
    local uses={}
    for key,count in pairs(images.atlas_uses) do
        if key:sub(1,#classic_group+1)==classic_group.."-" then
            uses[key]=count; images.atlas_uses[key]=nil
        end
    end
    local ok,err=pcall(function()
        director:load_texture_groups({classic_group},main.params.texture_size,game.ref_res,false,"game")
    end)
    for key,count in pairs(uses) do images.atlas_uses[key]=count end
    if not ok then error(err) end
    -- A:load resets the animation database. Merge to preserve battle animations.
    local A=require("klove.animation_db")
    for name,animation in pairs(classic_animations()) do
        if not A.db[name] then animation.group=classic_group; A.db[name]=animation end
    end
    local valid,missing=classic_ready()
    assert(valid,"Classic troop assets unavailable: "..tostring(missing))
    print("[KR6Trainer] classic troop textures and animations loaded")
end
local function summon_state(e)
    local store=game.store
    local sprite=e.render.sprites[1]
    local frame=e.render.frames and e.render.frames[1]
    local co=e.main_script and e.main_script.co
    return string.format("id=%s kind=%s pos=%.1f,%.1f tick=%.3f paused=%s inserted=%s animation=%s frame=%s visible=%s hp=%s script=%s",
        tostring(e.id),tostring(e._trainer_kind),e.pos.x,e.pos.y,store.tick_ts,
        tostring(store.paused),tostring(store.entities[e.id]==e),tostring(sprite.name),tostring(sprite.frame_name),
        tostring(frame and (frame.ss or frame.exo_frame) and not frame.hidden and (frame.alpha or 255)>0 or false),
        tostring(e.health.hp),co and coroutine.status(co) or "pending")
end
local function refund_summon(e)
    local purchase=e._trainer_purchase
    if not purchase or purchase.settled or purchase.refunded then return false end
    purchase.refunded=true
    purchase.store.player_gold=purchase.store.player_gold+purchase.amount
    print('[KR6Trainer REFUND] '..e.id..' gold='..purchase.amount)
    return true
end
local function cancel_failed_summon(e,store)
    e._trainer_deleted=true;e._trainer_pending=nil;e.health.dead=true
    e.ui.can_click=false;e.ui.can_select=false
    for _,r in ipairs(e.render.sprites or {})do r.hidden=true end
    for _,r in pairs(e.render.frames or {})do r.hidden=true end
    if e.health_bar then e.health_bar.hidden=true end
    for i=#store.pending_inserts,1,-1 do
        if store.pending_inserts[i]==e then table.remove(store.pending_inserts,i)end
    end
    if store.entities[e.id]==e then
        U.unblock_target(store,e)
        game.simulation:queue_remove_entity(e)
    end
    T.units[e.id]=nil
end
local function confirm_summon(e)
    if not e._trainer_pending then return end
    local store=game.store
    local def=troops[e._trainer_kind]
    local group=e._legion_group
    if group and group.reinforcements then
        local ready=true
        for _,member in ipairs(group.members)do
            local frame=member.render.frames and member.render.frames[1]
            if store.entities[member.id]~=member or
              (not member.health.dead and not (frame and (frame.ss or frame.exo_frame) and not frame.hidden and (frame.alpha or 255)>0))then ready=false end
        end
        if ready then
            if group.purchase then group.purchase.settled=true end
            for _,member in ipairs(group.members)do member._trainer_pending=nil;member._trainer_seen=true end
            require('kr6_summon_public.trainer_reinforcements').play_arrival()
            note(tr("利尼维亚援兵已入场：选中任意一人即可整组移动"))
        elseif not store.paused and store.tick_ts-e._trainer_queued_ts>=2 then
            local refunded=refund_summon(group.members[1])
            for _,member in ipairs(group.members)do cancel_failed_summon(member,store)end
            note(refunded and tr("援兵入场异常，金币已退还") or tr("援兵入场异常，请查看 trainer.log"))
        end
        return
    end
    local frame=e.render.frames and e.render.frames[1]
    if e.health.dead then
        e._trainer_pending=nil
        if store.entities[e.id]~=e then refund_summon(e)
        elseif e._trainer_purchase then e._trainer_purchase.settled=true end
        print("[KR6Trainer SUMMON DEAD] "..summon_state(e))
        note(tr(def.name)..tr("召唤后已阵亡"))
    elseif store.entities[e.id]==e and frame and (frame.ss or frame.exo_frame) and not frame.hidden and (frame.alpha or 255)>0 then
        e._trainer_pending=nil; e._trainer_seen=true
        if e._trainer_purchase then e._trainer_purchase.settled=true end
        print("[KR6Trainer SUMMON OK] "..summon_state(e))
        note(tr(def.name)..(T.placing and tr("已召唤：可继续左键地面召唤") or tr("已召唤：左键选中，再左键地面移动")))
    elseif not store.paused and store.tick_ts-e._trainer_queued_ts>=2 then
        e._trainer_pending=nil
        print("[KR6Trainer SUMMON FAILED] "..summon_state(e))
        local refunded=refund_summon(e)
        if refunded then cancel_failed_summon(e,store)end
        note(tr(def.name)..(refunded and tr("入场异常，金币已退还") or tr("入场异常，请查看 trainer.log")))
        if store.entities[e.id]~=e then T.units[e.id]=nil end
    end
end
function T.track_summon(e,store)
    if T.store~=store then return end
    e._trainer_pending=true; e._trainer_queued_ts=store.tick_ts
    T.units[e.id]=e
    print("[KR6Trainer SUMMON QUEUED AUTO] "..summon_state(e))
end
function T.add_gold()
    if not battle() then note(tr("请先进入战场")) return end
    game.store.player_gold=game.store.player_gold+500
    note(tr("金币 +500；当前 ")..tostring(game.store.player_gold))
end
local function summon_reinforcements(p,def,price)
    local store=game.store
    local group=require('kr6_summon_public.trainer_reinforcements').prepare(def,store,p)
    if not group then note(tr("该处没有足够的可行走地面供援兵入场")) return end
    for _,member in ipairs(group.members)do tag_name(member,"linirea_reinforcements")end
    local leader=group.members[1]
    if price>0 then
        group.purchase={store=store,amount=price}
        leader._trainer_purchase=group.purchase
        store.player_gold=store.player_gold-price
    end
    local queued,err=pcall(function()
        for _,member in ipairs(group.members)do
            game.simulation:queue_insert_entity(member)
            T.track_summon(member,store)
        end
    end)
    if not queued then
        refund_summon(leader)
        for _,member in ipairs(group.members)do cancel_failed_summon(member,store)end
        error(err)
    end
    T.selected=nil
    note(game.store.paused and tr("双人援兵已排队：请恢复游戏") or tr("利尼维亚援兵正在进入战场…"))
    return leader
end
function T.summon(p,kind)
    assert(battle(),"not in battle")
    kind=kind or "paladin"
    if not available(kind)then note(tr("此兵种需要导入素材")) return end
    local def=assert(troops[kind],"Unknown trainer troop")
    local price=T.gold_mode and (prices[kind]or 0)or 0
    if price>0 and (game.store.player_gold or 0)<price then
        note(string.format(tr("金币不足：%s需 %d 金，当前 %d 金"),tr(def.name),price,game.store.player_gold or 0))
        return
    end
    if def.reinforcements then return summon_reinforcements(p,def,price) end
    local e=def.longbow and require('kr6_summon_public.trainer_longbow').create(def,game.store)
        or def.archmage and require('kr6_summon_public.trainer_archmage_core').create(kind,def,game.store)
        or def.native and require('kr6_summon_public.trainer_native_units').create(def)
        or def.stage_native and require('kr6_summon_public.trainer_templar').create(def)
        or def.imported and imported().create(kind,def,game.store) or E:create_entity(def.entity)
    assert(e and e.health and e.nav_rally,"Troop template is unavailable")
    if not ground(p,e) then note(tr("请点击可行走的地面")) return end
    load_troop_images()
    if def.longbow then
      require('kr6_summon_public.trainer_longbow').load_assets()
    elseif def.stage_native then
      require('kr6_summon_public.trainer_templar').load_assets();require('kr6_summon_public.trainer_audio').prepare_native()
    elseif def.archmage then require('kr6_summon_public.trainer_archmage_core').load_assets()
    elseif def.imported then imported().load_assets()
    elseif not def.native then
      require('kr6_summon_public.trainer_audio').prepare_native()
      local tower=E:create_entity(def.tower)
      for name,power in pairs(e.powers) do
        power.level=tower.powers[name].max_level or 3; power.changed=nil
      end
      for _,attack in ipairs(e.melee.attacks)do attack.sound=attack.sound or 'MeleeSword'end
    end
    e.pos={x=p.x,y=p.y}; e.nav_rally.pos={x=p.x,y=p.y}
    e.nav_rally.center={x=p.x,y=p.y}; e.nav_rally.new=false
    e.nav_rally.delay_min=nil; e.nav_rally.delay_max=nil
    e.nav_grid.ignore_waypoints=true
    e.health.hp=e.health.hp_max
    e.render.sprites[1].name="idle"
    e.render.sprites[1].ts=game.store.tick_ts
    -- Preserve native insertion/update and upgrade callbacks, including dual axes.
    e.ui.can_click=true; e.ui.can_select=true
    e._kr6_trainer=true
    e._trainer_kind=kind
    tag_name(e,kind)
    e._trainer_pending=true; e._trainer_queued_ts=game.store.tick_ts
    if price>0 then
        e._trainer_purchase={store=game.store,amount=price}
        game.store.player_gold=game.store.player_gold-price
    end
    local queued,queue_error=pcall(game.simulation.queue_insert_entity,game.simulation,e)
    if not queued then
        refund_summon(e);cancel_failed_summon(e,game.store)
        error(queue_error)
    end
    T.units[e.id]=e; T.selected=nil
    print("[KR6Trainer SUMMON QUEUED] "..summon_state(e))
    print("[KR6Trainer] "..tr(def.name).." powers: "..tr(def.skills))
    note((price>0 and string.format(tr("已付 %d 金："),price)or "")..tr(def.name)..(game.store.paused and tr("召唤已排队：请恢复游戏") or tr("正在进入战场…")))
    confirm_summon(e)
    return e
end
function T.move(p)
    local e=T.selected
    if not battle() or not e or e.health.dead then note(tr("请先选择存活的召唤士兵")) return end
    if e._legion_group then
        local g=e._legion_group
        if require('kr6_summon_public.trainer_public_formation').move_group(g,game.store,p) then
            note(g.reinforcements and tr("利尼维亚援兵正在整组移动") or tr("护卫组正在整组移动：前方双兵，后方弓手"))
        else note(tr("该处放不下队形，请换个位置")) end
        return
    end
    if not ground(p,e) then note(tr("该处不能站立，请选择地面")) return end
    if e._trainer_kind=='arcane_sage' and require('kr6_summon_public.trainer_magus').request_move(e,p)then
        note(tr('奥术大魔导正在传送至目的地'));return
    end
    if e._trainer_kind=="genesis_miner" and require('kr6_summon_public.trainer_native_units').move_miner(e,p) then
        note(tr("矿工正挖地前往目的地"))
        return
    end
    U.unblock_target(game.store,e)
    e.nav_rally.pos={x=p.x,y=p.y}; e.nav_rally.center={x=p.x,y=p.y}
    e.nav_rally.new=true
    e.motion.forced_waypoint=nil
    note((tr(troops[e._trainer_kind or "paladin"].name))..tr("正在前往指定位置"))
end
local function deletable(e)
    return e and e._kr6_trainer and e.soldier and not e.enemy and not e.hero and
        not e._trainer_deleted and e.pos and e.ui and e.ui.can_click~=false
end
function T.delete_unit(e)
    if not battle() or not deletable(e) or game.store.entities[e.id]~=e then return false end
    if e._legion_group and not e._legion_group.deleting then
        local group=e._legion_group;group.deleting=true
        for _,member in ipairs(require('kr6_summon_public.trainer_public_formation').members(group,game.store))do T.delete_unit(member) end
        note(group.reinforcements and tr("利尼维亚援兵已整组删除") or tr("护卫组已整组删除"))
        return true
    end
    if e._arcane_illusion then require('kr6_summon_public.trainer_magus').mirror_exit(e,game.store)end
    e._trainer_deleted=true;e._trainer_pending=nil;e._kr4_revived=true
    U.unblock_target(game.store,e)
    if e._charge_audio then require('kr6_summon_public.trainer_kr4_audio').stop(e._charge_audio);e._charge_audio=nil end
    e.ui.can_click=false;e.ui.can_select=false
    if e.render then
        for _,sprite in ipairs(e.render.sprites or {})do sprite.hidden=true end
        for _,frame in pairs(e.render.frames or {})do frame.hidden=true end
    end
    if e.health_bar then e.health_bar.hidden=true end
    local gui=game.game_gui
    if gui.selected_entity==e then
        if gui.c_deselect then gui.c_deselect()else gui.selected_entity=nil end
    end
    if T.selected==e then T.selected=nil end
    game.simulation:queue_remove_entity(e)
    T.units[e.id]=nil
    print('[KR6Trainer DELETE] id='..e.id..' kind='..tostring(e._trainer_kind))
    note(tr((troops[e._trainer_kind] or troops.paladin).name)..tr("已删除：可以继续点击部队"))
    return true
end
function T.delete_click(p)
    if not battle() then return false end
    local gui=game.game_gui
    if gui.entity_at_pos then
        local e=gui:entity_at_pos(p.x,p.y,0,deletable)
        if e then return T.delete_unit(e)end
        note(tr("请点击修改器召唤的部队"));return false
    end
    local best,best_distance
    for _,e in pairs(game.store.entities)do
        if deletable(e) then
            local rect=e.ui.click_rect or {pos={x=-14,y=-2},size={x=28,y=40}}
            local x,y=e.pos.x+rect.pos.x,e.pos.y+rect.pos.y
            if p.x>=x and p.x<=x+rect.size.x and p.y>=y and p.y<=y+rect.size.y then
                local distance=(p.x-(x+rect.size.x/2))^2+(p.y-(y+rect.size.y/2))^2
                if not best or distance<best_distance or (distance==best_distance and e.id>best.id)then
                    best=e;best_distance=distance
                end
            end
        end
    end
    if best then return T.delete_unit(best)end
    note(tr("请点击修改器召唤的部队"));return false
end
local function layout()
    local w=math.min(T.visible and 400 or 148,G.getWidth()-20)
    local _,_,bottom=summon_layout(0,0,w)
    local h=T.visible and (bottom+322) or 38
    T.panel=T.panel or {x=G.getWidth()-w-10,y=math.min(100,math.max(10,G.getHeight()-h-10))}
    T.panel.x=math.max(0,math.min(T.panel.x,G.getWidth()-w))
    T.panel.y=math.max(0,math.min(T.panel.y,math.max(0,G.getHeight()-h)))
    return T.panel.x,T.panel.y,w,h
end
T.panel_layout=layout
function T.group_layout()
    local x,y,w=layout()
    local _,headers=summon_layout(x,y,w)
    return headers
end
local function buttons()
    local x,y,w=layout()
    local result={{i=1,x=x+10,y=y+39,w=w-20,h=33,label=tr("金币 +500   [F7]")}}
    local slots,_,bottom=summon_layout(x,y,w)
    for j,kind in ipairs(troop_order)do
        local slot=slots[kind]
        if slot then result[#result+1]={i=j+1,x=slot.x,y=slot.y,w=slot.w,h=slot.h,kind=kind,group=slot.group,
            label=T.gold_mode and tr(troops[kind].name) or tr("召唤")..tr(troops[kind].name)..(kind=="paladin" and " [F8]" or kind=="barbarian" and " [F9]" or ""),
            price=prices[kind],unaffordable=T.gold_mode and battle()and (game.store.player_gold or 0)<prices[kind],
            on=T.placing==kind} end
    end
    result[#result+1]={i=hero_button,x=x+10,y=bottom+39,w=w-20,h=33,
        label=tr("英雄经验 20 倍：")..(T.hero and tr("开启") or tr("停用")),on=T.hero}
    result[#result+1]={i=power_button,x=x+10,y=bottom+78,w=w-20,h=33,
        label=tr("法术经验 20 倍：")..(T.power and tr("开启") or tr("停用")),on=T.power}
    result[#result+1]={i=delete_button,x=x+10,y=bottom,
        w=w-20,h=33,label=tr("删除召唤部队 [F10]"),on=T.deleting}
    result[#result+1]={i=gold_mode_button,x=x+10,y=y+78,w=w-20,h=33,
        label=tr("金币召唤模式：")..(T.gold_mode and tr("开启（显示价格）") or tr("停用（免费召唤）")),on=T.gold_mode}
    return result
end
T.button_layout=buttons
local function inside(x,y,rx,ry,w,h) return x>=rx and x<=rx+w and y>=ry and y<=ry+h end
local function language_button(x,y,w)
    return x+w-124,y+5,82,28
end
local function panel_font_file()
    if T.language=="zh-CN" then
        if T.windows_font==nil then
            T.windows_font=false
            local system=os.getenv("WINDIR")
            local file=system and io.open(system.."/Fonts/msyh.ttc","rb")
            if file then
                local bytes=file:read("*a");file:close()
                local ok,data=pcall(love.filesystem.newFileData,bytes,"msyh.ttc")
                if ok then T.windows_font=data end
            end
        end
        if T.windows_font then return T.windows_font end
    end
    return "_assets/kr6-desktop/fonts/NotoSansCJKsc-Regular.otf"
end
local function font()
    if not T.font then
        T.font=G.newFont(panel_font_file(),15)
    end
    return T.font
end
local function draw()
    if not main or not main.params then return end
    local x,y,w,h=layout()
    G.push("all"); G.origin(); G.setScissor(); G.setShader(); G.setBlendMode("alpha")
    G.setColor(17,24,34,235); G.rectangle("fill",x,y,w,h,8,8)
    G.setFont(font()); G.setColor(243,208,119,255)
    G.print(T.visible and tr("召唤助手 v1.3") or (T.deleting and tr("删除模式") or T.gold_mode and tr("金币召唤") or tr("召唤助手")),x+12,y+8)
    G.setColor(41,65,83,255);G.rectangle("fill",x+w-34,y+5,28,28,4,4)
    G.setColor(243,208,119,255);G.print(T.visible and "-" or "+",x+w-26,y+6)
    if T.visible then
        local lx,ly,lw,lh=language_button(x,y,w)
        G.setColor(41,65,83,255); G.rectangle("fill",lx,ly,lw,lh,4,4)
        G.setColor(243,208,119,255)
        G.printf(T.language=="en" and "简体中文" or "English",lx,ly+4,lw,"center")
        local mx,my=love.mouse.getPosition()
        for i,tab in ipairs(faction_tabs(x,y,w))do
            G.setColor(38,i==T.faction and 105 or 60,78,255)
            G.rectangle("fill",tab.x,tab.y,tab.w,tab.h,4,4)
            G.setColor(244,245,247,255)
            local label=tr(tab.name)
            local factor=math.min(1,(tab.w-6)/math.max(1,font():getWidth(label)))
            G.printf(label,tab.x,tab.y+2,tab.w/factor,"center",0,factor,factor)
        end
        for _,group in ipairs(T.group_layout())do
            G.setColor(group.color[1],group.color[2],group.color[3],255)
            G.print(tr(group.name).."  ·  "..group.count..tr(" 种"),group.x+2,group.y)
        end
        for _,b in ipairs(buttons()) do
            local on=b.on
            local hover=inside(mx,my,b.x,b.y,b.w,b.h)
            if b.i==delete_button and on then G.setColor(125,45,50,255)
            else G.setColor(on and 33 or 41,on and 100 or (hover and 70 or 53),on and 78 or 73,255)end
            G.rectangle("fill",b.x,b.y,b.w,b.h,4,4)
            G.setColor(244,245,247,255); local label_font=font()
            local label_width=b.w-(T.gold_mode and b.price and 47 or 14)
            local scale=math.min(1,label_width/math.max(1,label_font:getWidth(b.label)))
            G.print(b.label,b.x+8,b.y+(b.h<30 and 1 or 5),0,scale,scale)
            if T.gold_mode and b.price then
                if b.unaffordable then G.setColor(255,125,125,255)else G.setColor(243,208,119,255)end
                G.printf(tostring(b.price),b.x+b.w-46,b.y+1,38,"right")
            end
        end
        G.setColor(187,200,211,255)
        local _,_,bottom=summon_layout(x,y,w)
        local footer=bottom+118
        G.printf(T.deleting and tr("删除模式：左键召唤部队，再点取消") or T.placing and tr("连续召唤：左键地面，再点选项取消") or tr("左键选中显示属性，再左键地面移动"),x+12,footer,w-24,"left")
    G.setColor(243,208,119,255)
    G.printf(battle() and T.notice or tr("已加载：进入战场后使用面板"),x+12,footer+24,w-24,"left")
        G.setColor(187,200,211,255)
        G.printf(T.vengeance and tr("四代兵种已启用") or tr("导入四代素材可解锁更多兵种"),x+12,footer+52,w-24,"left")
        G.print(tr("本关倍率经验：英雄 +")..math.floor(T.hero_xp)..tr("  法术 +")..math.floor(T.power_xp),x+12,footer+73)
        if battle() and T.selected and not T.selected.health.dead then
            local e=T.selected; local a=e.melee and e.melee.attacks[1] or {damage_min=0,damage_max=0}
            local def=troops[e._trainer_kind or "paladin"]
            if e._arcane_illusion then def={name="奥术幻影",skills="近战与魔法雨 / 本体30% / 10秒"}end
            -- Native barbarian info includes the full dual-axe multi-hit damage.
            local stats=e._ranged_display_attack or (e.info and e.info.fn and e.info.fn(e)) or a
            G.setColor(105,240,147,255)
            local detail=tr(def.skills)
            if e._legion_group and e._legion_group.reinforcements then
                detail=string.format(tr("援兵 %d/2 人 · 荆棘反伤 10%% · 脱战回血"),#require('kr6_summon_public.trainer_public_formation').members(e._legion_group,game.store))
            elseif e._legion_group then
                detail=string.format(tr("护卫组 %d/3 人 · 点击地面整组移动"),#require('kr6_summon_public.trainer_public_formation').members(e._legion_group,game.store))
            elseif e._trainer_kind=='legion_captain' then
                local count=require('kr6_summon_public.trainer_public_formation').group_count(game.store,e)
                detail=e._legion_spawn_blocked and count<2 and string.format(tr("护卫组 %d/2 · 暂无空位，待命"),count)or string.format(tr("本上尉护卫组 %d/2 · 冷却 20 秒"),count)
            elseif e._trainer_kind=='ice_witch' then
                local module=imported();local count=module.shard_count(e,game.store)
                detail=module.on_shard_ice(e,game.store) and string.format(tr("冰晶 %d · 冰面不限"),count) or string.format(tr("冰晶 %d/3 · 普通地面"),count)
            end
            G.printf(tr(def.name)..tr("：")..detail,x+12,footer+102,w-24,"left")
            G.setColor(244,245,247,255)
            if (e._trainer_kind=='magus' or e._trainer_kind=='arcane_sage') or e._trainer_kind=='mystic' or e._trainer_kind=='elite_longbow' or e._trainer_kind=='royal_archer' or e._trainer_kind=='ice_witch' or e._trainer_kind=='alchemist' or e._trainer_kind=='elephant' or def.reinforcements then
                local melee=e.melee.attacks[#e.melee.attacks]
                G.print(string.format(tr("生命 %d/%d  近战物理 %d-%d"),e.health.hp,e.health.hp_max,melee.damage_min,melee.damage_max),x+12,footer+132)
                G.print(string.format(((e._trainer_kind=='elite_longbow'or e._trainer_kind=='royal_archer'or e._trainer_kind=='alchemist'or e._trainer_kind=='elephant'or def.reinforcements)and tr("远程物理 ")or tr("远程法术 ")).."%s%d-%d",(e._trainer_kind=='magus' or e._trainer_kind=='arcane_sage') and "5×" or "",stats.damage_min,stats.damage_max),x+12,footer+155)
            else
                G.print(string.format(tr("生命 %d/%d  攻击 %d-%d"),e.health.hp,e.health.hp_max,stats.damage_min,stats.damage_max),x+12,footer+155)
            end
            G.print(string.format(tr("护甲 %d%%  魔抗 %d%%"),math.floor(e.health.armor*100+0.5),math.floor((e.health.magic_armor or 0)*100+.5)),x+12,footer+178)
        end
    end
    if battle() and T.selected and not T.selected.health.dead then
        local selected=T.selected
        local members=selected._legion_group and require('kr6_summon_public.trainer_public_formation').members(selected._legion_group,game.store) or {selected}
        G.setColor(105,240,147,255); G.setLineWidth(2)
        for _,member in ipairs(members)do
            local sx,sy=game.game_gui:g2s(member.pos);G.ellipse("line",sx,sy,19,8)
        end
    end
    G.pop()
end
local function action(i)
    if i==1 then T.add_gold()
    elseif i>=2 and i<=#troop_order+1 then
        local kind=troop_order[i-1]
        if not available(kind)then return end
        for index,group in ipairs(troop_groups)do
            for _,unit in ipairs(group.kinds)do if unit==kind then T.faction=index end end
        end
        T.deleting=false
        T.placing=T.placing~=kind and kind or false
        note(T.placing and tr("连续召唤")..tr(troops[kind].name)..tr("：再点选项取消") or tr("已取消召唤"))
    elseif i==hero_button then T.hero=not T.hero; note(tr("英雄经验：")..(T.hero and tr("20 倍") or tr("正常")))
    elseif i==power_button then T.power=not T.power; note(tr("法术经验：")..(T.power and tr("20 倍") or tr("正常")))
    elseif i==gold_mode_button then
        T.gold_mode=not T.gold_mode
        note(T.gold_mode and tr("金币召唤已开启：按标价扣费，金币不足不召唤") or tr("金币召唤已停用：恢复免费召唤"))
    elseif i==delete_button then
        if not battle() then note(tr("请先进入战场"));return end
        T.deleting=not T.deleting;T.placing=false
        if T.deleting and game.game_gui.c_deselect then game.game_gui.c_deselect()end
        note(T.deleting and tr("删除模式：左键召唤部队，再点选项取消") or tr("已取消删除模式"))
    end
end
local function press(x,y,button)
    local left=button==1 or button=="l"; local right=button==2 or button=="r"
    local rx,ry,w,h=layout()
    if inside(x,y,rx,ry,w,h) then
        if left then
            if y<ry+38 and x>=rx+w-38 then T.visible=not T.visible
            elseif T.visible and inside(x,y,language_button(rx,ry,w)) then
                T.language=T.language=="en" and "zh-CN" or "en"
                T.font=nil
                update_names()
                refresh_selected_name()
                note(tr("语言已切换"))
            elseif y<ry+34 or not T.visible then
                T.drag={start_x=x,start_y=y,x=rx,y=ry,moved=false,mini=not T.visible}
            elseif T.visible then
                for i,tab in ipairs(faction_tabs(rx,ry,w))do
                    if inside(x,y,tab.x,tab.y,tab.w,tab.h)then T.faction=i;layout();return true end
                end
                for _,b in ipairs(buttons())do
                    if inside(x,y,b.x,b.y,b.w,b.h) then action(b.i);break end
                end
            end
        end
        return true
    end
    if not battle() then return false end
    if T.deleting then
        if right then T.deleting=false;note(tr("已取消删除模式"))
        elseif left then attempt(T.delete_click,world(x,y))end
        return true
    end
    if T.placing then
        if right then T.placing=false; note(tr("已取消召唤"))
        elseif left then attempt(T.summon,world(x,y),T.placing) end
        return true
    end
    return false
end
local function drag_move(x,y)
    local d=T.drag
    if not d then return false end
    if (x-d.start_x)^2+(y-d.start_y)^2>16 then d.moved=true end
    if d.moved then
        T.panel.x=d.x+x-d.start_x;T.panel.y=d.y+y-d.start_y;layout()
    end
    return true
end
-- Only replace the idle ground-click fallback. Every native GUI, entity,
-- hero and spell rule runs first, in the original order and original mode.
function T.hook_input(gui)
    if not gui or not gui.ism_data or T.input_gui==gui then return end
    local rows=gui.ism_data[GUI_MODE_IDLE]
    if not rows then return end
    for _,row in ipairs(rows) do
        if row[1]=="click1" and row[2]==true and row[4]==gui.c_deselect then
            local deselect=row[4]
            row[4]=function(ctx,...)
                local e=gui.selected_entity
                if battle() and e and e._kr6_trainer and not e.health.dead and
                    ctx and not ctx.from_gamepad then
                    local x,y,wx,wy=gui.get_pos_from_ctx(ctx)
                    if wx then
                        T.selected=e
                        attempt(T.move,{x=wx,y=wy})
                        return
                    end
                end
                return deselect(ctx,...)
            end
            T.input_gui=gui
            print("[KR6Trainer] native idle ground click hook installed")
            return
        end
    end
end
-- Use the bundled CJK font for summoned-unit names and restore the native font for other selections.
function T.update_name_font(gui,selected)
    if not gui or not gui.window or not gui.window.ci then return end
    local part=gui.window:ci("infobar_part_a")
    if not part then return end
    local F=require('klove.font_db')
    if not F.font_files then return end
    local alias="trainer_unit_name_"..(T.language=="zh-CN" and "zh" or "en")
    F.font_files[alias]=F.font_files[alias] or panel_font_file()
    for _,name in ipairs({"with_health","with_portrait","text_only"})do
        local view=part:ci(name)
        local title=view and view:ci("title")
        if title then
            if selected and selected._kr6_trainer then
                if not title._trainer_name_font then
                    title._trainer_name_font={name=title.font_name}
                end
                if title.font_name~=alias then
                    title.font_name=alias
                    if title._load_font then title:_load_font()end
                end
            elseif title._trainer_name_font then
                title.font_name=title._trainer_name_font.name
                title._trainer_name_font=nil
                if title._load_font then title:_load_font()end
            end
        end
    end
end
function T.install(version)
    T.faction=2
    T.vengeance=love.filesystem.exists("kr6_summon_public/vengeance/ready.lua")
    local old_update,old_draw=love.update,love.draw
    local old_press,old_release=love.mousepressed,love.mousereleased
    local old_motion=love.mousemoved
    local old_key=love.keypressed
    local old_focus=love.focus
    love.update=function(dt)
        if old_update then old_update(dt) end
        if T.hooked_su~=package.loaded.script_utils or T.hooked_sys~=package.loaded.systems then attempt(hooks) end
        if T.store~= (game and game.store) then
            T.store=game and game.store; T.units={}; T.selected=nil; T.placing=false;T.deleting=false
            T.hero_xp=0; T.power_xp=0; T.hero_logs=0; T.power_logs=0
        end
        local gui=game and game.game_gui
        T.hook_input(gui)
        local selected=gui and gui.selected_entity
        attempt(T.update_name_font,gui,selected)
        T.selected=selected and selected._kr6_trainer and selected or nil
        for id,e in pairs(T.units) do
            confirm_summon(e)
            if e.health.dead or not game.store.entities[id] then
                if e._trainer_seen or e.health.dead then T.units[id]=nil; if T.selected==e then T.selected=nil end end
            else e._trainer_seen=true end
        end
    end
    love.draw=function() if old_draw then old_draw() end; attempt(draw) end
    T.consumed={}
    love.mousepressed=function(x,y,b,...)
        if press(x,y,b) then T.consumed[b]=true; return end
        if old_press then return old_press(x,y,b,...) end
    end
    love.mousereleased=function(x,y,b,...)
        if T.drag and (b==1 or b=="l") then
            drag_move(x,y)
            local d=T.drag;T.drag=nil;T.consumed[b]=nil
            if d.mini and not d.moved then T.visible=true;layout()end
            return
        end
        if T.consumed[b] then T.consumed[b]=nil; return end
        if old_release then return old_release(x,y,b,...) end
    end
    love.mousemoved=function(x,y,...)
        if drag_move(x,y)then return end
        if old_motion then return old_motion(x,y,...)end
    end
    love.focus=function(focused,...)
        if not focused then T.drag=nil;T.consumed[1]=nil;T.consumed.l=nil end
        if old_focus then return old_focus(focused,...)end
    end
    love.keypressed=function(k,...)
        if k=="f6" then T.drag=nil;T.visible=not T.visible;layout();return end
        if battle() then
            if k=="f7" then action(1); return end
            if k=="f8" then action(2); return end
            if k=="f9" then action(3); return end
            if k=="f10" then action(delete_button);return end
            if k=="escape" and (T.placing or T.deleting) then
                T.placing=false;T.deleting=false;note(tr("已取消操作模式"));return
            end
        end
        if old_key then return old_key(k,...) end
    end
    _G.KR6_TRAINER=T
end
return T
