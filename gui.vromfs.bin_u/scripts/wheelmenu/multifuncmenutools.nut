from "%scripts/dagui_library.nut" import *
//-file:undefined-const
//-file:undefined-variable
//checked for explicitness
#no-root-fallback
#implicit-this

let { getPlayerCurUnit } = require("%scripts/slotbar/playerCurUnit.nut")

let getMfmHandler = @() ::handlersManager.findHandlerClassInScene(::gui_handlers.multifuncMenuHandler)
let getMfmSectionTitle = @(section) section?.getTitle() ?? loc(section?.title ?? "")

local isDebugMode = false

::debug_multifunc_menu <- @(enable) isDebugMode = enable


let function isEnabledByUnit(config, c, unitId)
{
  if (c == null)
    return false
  if (c?.enable)
    return c.enable(unitId)
  if (c?.section)
  {
    let sect = config[c.section]
    if (sect?.enable)
      return sect.enable(unitId)
    foreach (cc in sect.items)
      if (isEnabledByUnit(config, cc, unitId))
        return true
    return false
  }
  return true
}


let function handleWheelMenuApply(idx)
{
  if (idx < 0)
    getMfmHandler()?.gotoPrevMenuOrQuit()
  else if (menu?[idx].sectionId)
    getMfmHandler()?.gotoSection(menu[idx].sectionId)
  else if (menu?[idx].shortcutId)
    getMfmHandler()?.toggleShortcut(menu[idx].shortcutId)
  else if (menu?[idx].action != null)
    menu?[idx].action()
}


let function makeMfmSection(cfg, id, unit)
{
  let allowedShortcutIds = ::g_controls_utils.getControlsList({ unitType = unit.unitType }).map(@(s) s.id)
  let unitId = unit?.name
  let sectionConfig = cfg[id]

  let menu = []
  foreach (idx, item in sectionConfig.items)
  {
    let c = ::u.isFunction(item) ? item() : item

    let isShortcut = "shortcut" in c
    let isSection  = "section"  in c
    let isAction   = "action"   in c

    local shortcutId = null
    local sectionId = null
    local action = null
    local label = ""
    local isEnabled = false

    if (isShortcut)
    {
      shortcutId = c.shortcut.findvalue(@(id) allowedShortcutIds.indexof(id) != null)
      label = loc("hotkeys/{0}".subst(shortcutId ?? c.shortcut?[0] ?? ""))
      isEnabled = shortcutId != null && isEnabledByUnit(cfg, c, unitId)
    }
    else if (isSection)
    {
      sectionId = c.section
      let title = getMfmSectionTitle(cfg[sectionId])
      label = "".concat(title, loc("ui/ellipsis"))
      isEnabled = isEnabledByUnit(cfg, c, unitId)
    }
    else if (isAction)
    {
      action = c.action
      label = c.label
      isEnabled = isEnabledByUnit(cfg, c, unitId) && label != ""
    }

    local color = isEnabled ? "hudGreenTextColor" : ""

    if (!isEnabled && isDebugMode)
    {
      if (isShortcut)
        shortcutId = c.shortcut?[0]
      isEnabled = isSection || (isShortcut && shortcutId != null)
      color = isEnabled ? "fadedTextColor" : color
    }

    let isEmpty = label == ""

    local shortcutText = ""
    if (!isEmpty && is_platform_pc)
      shortcutText = ::get_shortcut_text({
        shortcuts = ::get_shortcuts([ $"ID_VOICE_MESSAGE_{idx+1}" ])
        shortcutId = 0
        cantBeEmpty = false
        strip_tags = true
        colored = isEnabled
      })

    menu.append(isEmpty ? null : {
      sectionId
      shortcutId
      action
      name = colorize(color, label)
      shortcutText = shortcutText != "" ? shortcutText : null
      wheelmenuEnabled = isEnabled
    })
  }

  return menu
}


local function openMfm(cfg, curSectionId = null, isForward = true)
{
  let unit = getPlayerCurUnit()
  let unitType = unit?.unitType
  if (!unitType)
    return false

  curSectionId = curSectionId ?? $"root_{unitType.tag}"
  if (cfg?[curSectionId] == null)
    return false

  let joyParams = ::joystick_get_cur_settings()
  let params = {
    menu = makeMfmSection(cfg, curSectionId, unit)
    callbackFunc = handleWheelMenuApply
    curSectionId = curSectionId
    mouseEnabled = joyParams.useMouseForVoiceMessage || joyParams.useJoystickMouseForVoiceMessage
    axisEnabled  = true
    shouldShadeBackground = ::is_xinput_device()
    mfmDescription = cfg
  }

  let handler = getMfmHandler()
  if (handler)
    handler.reinitScreen(params)
  else
    ::handlersManager.loadHandler(::gui_handlers.multifuncMenuHandler, params)

  if (isForward)
    cfg[curSectionId]?.onEnter()

  return true
}



return {
  getMfmHandler
  getMfmSectionTitle
  openMfm
}
