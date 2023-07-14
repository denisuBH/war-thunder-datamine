
let { format } = require("string")
let { Color4 } = require("dagor.math")
let { hexStringToInt } =  require("%sqstd/string.nut")
let regexp2 = require("regexp2")
let { wrapIdxInArrayLen } = require("%sqStdLibs/helpers/u.nut")

global enum ALIGN {
  LEFT   = "left"
  TOP    = "top"
  RIGHT  = "right"
  BOTTOM = "bottom"
  CENTER = "center"
}

let DEFAULT_OVERRIDE_PARAMS = {
  windowSizeX = -1
  windowSizeY = -1
}

let check_obj = @(obj) obj != null && obj.isValid()

/*
* return pixels (int)
* operations depend on value type^
  * int, float - tointeger()
  * string - calculate string by dagui calculator
*/
let function toPixels(guiScene, value, obj = null) {
  if (type(value) == "float" || type(value) == "integer")
    return value.tointeger()
  if (type(value) == "string")
    return guiScene.calcString(value, obj)
  return 0
}

/*
* count amount of items can be filled in current obj.
* return table with itemsCount and items sizes in pixels
  {
    itemsCountX, itemsCountY (int)  //min = 1
    sizeX, sizeY, spaceX, spaceY (int)
  }
* parameters^
  * listObj - list of items object
  * sizeX, sizeY - item size in pixels (int) or dagui constant (string)
  * spaceX, spaceY - space between items in pixels (int) or dagui constant (string)
  * reserveX, reserveY - space items in pixels (int) or dagui constant (string) reserved for non-item listObj's elements
*/
let function countSizeInItems(listObj, sizeX, sizeY, spaceX, spaceY, reserveX = 0, reserveY = 0) {
  let res = {
    itemsCountX = 1
    itemsCountY = 1
    sizeX = 0
    sizeY = 0
    spaceX = 0
    spaceY = 0
    reserveX = 0
    reserveY = 0
  }
  if (!check_obj(listObj))
    return res

  let listSize = listObj.getSize()
  let guiScene = listObj.getScene()
  res.sizeX = toPixels(guiScene, sizeX)
  res.sizeY = toPixels(guiScene, sizeY)
  res.spaceX = toPixels(guiScene, spaceX)
  res.spaceY = toPixels(guiScene, spaceY)
  res.reserveX = toPixels(guiScene, reserveX)
  res.reserveY = toPixels(guiScene, reserveY)
  res.itemsCountX = max(1, ((listSize[0] - res.spaceX - res.reserveX) / (res.sizeX + res.spaceX)).tointeger())
  res.itemsCountY = max(1, ((listSize[1] - res.spaceY - res.reserveY) / (res.sizeY + res.spaceY)).tointeger())
  return res
}

//config generated by countSizeInItems
let function adjustWindowSizeByConfig(wndObj, listObj, config, overrideParams = DEFAULT_OVERRIDE_PARAMS) {
  if (!check_obj(wndObj) || !check_obj(listObj))
    return [0, 0]

  overrideParams = DEFAULT_OVERRIDE_PARAMS.__merge(overrideParams)
  let wndSize = wndObj.getSize()
  let listSize = listObj.getSize()
  let windowSizeX = overrideParams.windowSizeX
  let windowSizeY = overrideParams.windowSizeY

  let wndSizeX = windowSizeX != -1 ? windowSizeX
    : min(wndSize[0], wndSize[0] - listSize[0] + (config.spaceX + config.itemsCountX * (config.sizeX + config.spaceX)))
  let wndSizeY = windowSizeY != -1 ? windowSizeY
    : min(wndSize[1], wndSize[1] - listSize[1] + (config.spaceY + config.itemsCountY * (config.sizeY + config.spaceY)))
  wndObj.size = format("%d, %d", wndSizeX, wndSizeY)
  return [wndSizeX, wndSizeY]
}

/**
* adjust window object size to make listobject size integer amount of items.
  work only when listobject size linear dependent on window object size
* return table with itemsCount, items sizes in pixels and window size in pixels
  {
    itemsCountX, itemsCountY (int) //min = 1
    sizeX, sizeY, spaceX, spaceY (int)
    windowSize = [width, height]
  }
* parameters:
  * wndObj - window object
  * listObj - list of items object
  * sizeX, sizeY - item size in pixels (int) or dagui constant (string)
  * spaceX, spaceY - space between items in pixels (int) or dagui constant (string)
*/
let function adjustWindowSize(wndObj, listObj, sizeX, sizeY, spaceX, spaceY, overrideParams = DEFAULT_OVERRIDE_PARAMS) {
  let res = countSizeInItems(listObj, sizeX, sizeY, spaceX, spaceY)
  local windowSize = adjustWindowSizeByConfig(wndObj, listObj, res, overrideParams)
  return res.__update({ windowSize })
}


let function setObjPosition(obj, reqPos_, border_) {
  if (!check_obj(obj))
    return

  let guiScene = obj.getScene()

  guiScene.applyPendingChanges(true)

  let objSize = obj.getSize()
  let screenSize = [ ::screen_width(), ::screen_height() ]
  let reqPos = [toPixels(guiScene, reqPos_[0], obj), toPixels(guiScene, reqPos_[1], obj)]
  let border = [toPixels(guiScene, border_[0], obj), toPixels(guiScene, border_[1], obj)]

  let posX = clamp(reqPos[0], border[0], screenSize[0] - border[0] - objSize[0])
  let posY = clamp(reqPos[1], border[1], screenSize[1] - border[1] - objSize[1])

  if (obj?.pos != null)
    obj.pos = format("%d, %d", posX, posY)
  else {
    obj.left = format("%d", posX)
    obj.top =  format("%d", posY)
  }
}

/*
* Checks if menu fits in safearea with selected 'align'. If not, selects a better 'align'.
* Sets menuObj object 'pos' and 'menu_align' properties, the way it fits into safearea,
* and its 'popup_menu_arrow' points to parentObjOrPos.
* @param {daguiObj|array(2)|null}  parentObjOrPos - Menu source - dagui object, or position.
*                                  Position must be array(2) of numbers or strings.
*                                  Use null for mouse pointer position.
* @param {string} defAlign - recommended align (see ALIGN enum)
* @param {daguiObj} menuObj - dagui object to be aligned.
* @param {table} [params] - optional extra paramenters.
  * param.margin {array(2)} - add interval outside of parent.
* @return {string} - align which was applied to menuObj (see ALIGN enum).
*/
let function setPopupMenuPosAndAlign(parentObjOrPos, defAlign, menuObj, params = null) {
  if (!check_obj(menuObj))
    return defAlign

  let guiScene = menuObj.getScene()
  let menuSize = menuObj.getSize()

  local parentPos  = [0, 0]
  local parentSize = [0, 0]
  if (type(parentObjOrPos) == "instance" && check_obj(parentObjOrPos)) {
    parentPos  = parentObjOrPos.getPosRC()
    parentSize = parentObjOrPos.getSize()
  }
  else if ((type(parentObjOrPos) == "array") && parentObjOrPos.len() == 2) {
    parentPos[0] = toPixels(guiScene, parentObjOrPos[0])
    parentPos[1] = toPixels(guiScene, parentObjOrPos[1])
  }
  else if (parentObjOrPos == null) {
    parentPos  = ::get_dagui_mouse_cursor_pos_RC()
  }

  let margin = params?.margin
  if (margin && margin.len() >= 2)
    for (local i = 0; i < 2; i++) {
      parentPos[i] -= margin[i]
      parentSize[i] += 2 * margin[i]
    }

  let screenBorders = params?.screenBorders ?? ["@bw", "@bh"]
  let bw = toPixels(guiScene, screenBorders[0])
  let bh = toPixels(guiScene, screenBorders[1])
  let screenStart = [bw, bh]
  let screenEnd   = [::screen_width().tointeger() - bw, ::screen_height().tointeger() - bh]

  local checkAligns = []
  switch (defAlign) {
    case ALIGN.BOTTOM: checkAligns = [ ALIGN.BOTTOM, ALIGN.TOP, ALIGN.RIGHT, ALIGN.LEFT, ALIGN.BOTTOM ]; break
    case ALIGN.TOP:    checkAligns = [ ALIGN.TOP, ALIGN.BOTTOM, ALIGN.RIGHT, ALIGN.LEFT, ALIGN.TOP ]; break
    case ALIGN.RIGHT:  checkAligns = [ ALIGN.RIGHT, ALIGN.LEFT, ALIGN.BOTTOM, ALIGN.TOP, ALIGN.RIGHT ]; break
    case ALIGN.LEFT:   checkAligns = [ ALIGN.LEFT, ALIGN.RIGHT, ALIGN.BOTTOM, ALIGN.TOP, ALIGN.LEFT ]; break
    default:           checkAligns = [ ALIGN.BOTTOM, ALIGN.RIGHT, ALIGN.TOP, ALIGN.LEFT, ALIGN.BOTTOM ]; break
  }

  foreach (checkIdx, align in checkAligns) {
    let isAlignForced = checkIdx == checkAligns.len() - 1

    local isVertical = true
    local isPositive = true
    switch (align) {
      case ALIGN.TOP:
        isPositive = false
        break
      case ALIGN.RIGHT:
        isVertical = false
        break
      case ALIGN.LEFT:
        isVertical = false
        isPositive = false
        break
    }

    let axis = isVertical ? 1 : 0
    let parentTargetPoint = [0.5, 0.5] //part of parent to target point
    let frameOffset = [0 - menuSize[0] / 2, 0 - menuSize[1] / 2]
    let frameOffsetText = ["-w/2", "-h/2"] //need this for animation

    if (isPositive) {
      parentTargetPoint[axis] = 1.0
      frameOffset[axis] = 0
      frameOffsetText[axis] = ""
    }
    else {
      parentTargetPoint[axis] = 0.0
      frameOffset[axis] = 0 - menuSize[isVertical ? 1 : 0]
      frameOffsetText[axis] = isVertical ? "-h" : "-w"
    }

    let targetPoint = [
      parentPos[0] + (parentSize[0] * (params?.customPosX ?? parentTargetPoint[0])).tointeger()
      parentPos[1] + (parentSize[1] * (params?.customPosY ?? parentTargetPoint[1])).tointeger()
    ]

    let isFits = [true, true]
    let sideSpace = [0, 0]
    foreach (i, _v in sideSpace) {
      if (i == axis)
        sideSpace[i] = isPositive ? screenEnd[i] - targetPoint[i] : targetPoint[i] - screenStart[i]
      else
        sideSpace[i] = screenEnd[i] - screenStart[i]

      isFits[i] = sideSpace[i] >= menuSize[i]
    }

    if ((!isFits[0] || !isFits[1]) && !isAlignForced)
      continue

    let arrowOffset = [0, 0]
    let menuPos = [targetPoint[0] + frameOffset[0], targetPoint[1] + frameOffset[1]]

    foreach (i, _v in menuPos) {
      if (i == axis && isFits[i])
        continue

      if (menuPos[i] < screenStart[i] || !isFits[i]) {
        arrowOffset[i] = menuPos[i] - screenStart[i]
        menuPos[i] = screenStart[i]
      }
      else if (menuPos[i] + menuSize[i] > screenEnd[i]) {
        arrowOffset[i] = menuPos[i] + menuSize[i] - screenEnd[i]
        menuPos[i] = screenEnd[i] - menuSize[i]
      }
    }

    let menuPosText = ["", ""]
    foreach (i, _v in menuPos)
      menuPosText[i] = (menuPos[i] - frameOffset[i]) + frameOffsetText[i]

    menuObj["menu_align"] = align
    menuObj["pos"] = ", ".join(menuPosText, true)

    if (arrowOffset[0] || arrowOffset[1]) {
      let arrowObj = menuObj.findObject("popup_menu_arrow")
      if (check_obj(arrowObj)) {
        guiScene.setUpdatesEnabled(true, true)
        let arrowPos = arrowObj.getPosRC()
        foreach (i, _v in arrowPos)
          arrowPos[i] += arrowOffset[i]
        arrowObj["style"] = "".concat("position:root; pos:", ", ".join(arrowPos, true), ";")
      }
    }

    return align
  }

  return defAlign
}

let textAreaTagsRegexp = [
  regexp2("</?color[^>]*>")
  regexp2("</?link[^>]*>")
  regexp2("</?b>")
]

//remove all textarea tags from @text to made it usable in behaviour:text
let function removeTextareaTags(text) {
  foreach (re in textAreaTagsRegexp)
    text = re.replace("", text)
  return text
}

let function getObjValidIndex(obj) {
  if (!check_obj(obj))
    return -1

  let value = obj.getValue()
  if (value < 0 || value >= obj.childrenCount())
    return -1

  return value
}

let function getObjValue(parentObj, id, defValue = null) {
  if (!check_obj(parentObj))
    return defValue

  let obj = parentObj.findObject(id)
  if (check_obj(obj))
    return obj.getValue()

  return defValue
}

let function show_obj(obj, status) {
  if (!check_obj(obj))
    return null

  obj.enable(status)
  obj.show(status)
  return obj
}

let function setFocusToNextObj(scene, objIdsList, increment) {
  let objectsList = objIdsList.map(@(id) id != null ? scene.findObject(id) : null)
    .filter(@(obj) check_obj(obj) && obj.isVisible() && obj.isEnabled())
  let listLen = objectsList.len()
  if (listLen == 0)
    return
  let curIdx = objectsList.findindex(@(obj) obj.isFocused()) ?? (increment >= 0 ? -1 : listLen)
  let newIdx = wrapIdxInArrayLen(curIdx + increment, listLen)
  objectsList[newIdx].select()
}

let function getSelectedChild(obj) {
  if (!obj?.isValid())
    return null

  let total = obj.childrenCount()
  if (total == 0)
    return null

  let value = clamp(obj.getValue(), 0, total - 1)
  return obj.getChild(value)
}

let function findChild(obj, func) {
  let res = { childIdx = -1, childObj = null }
  if (!obj?.isValid())
    return res

  let total = obj.childrenCount()
  for (local i = 0; i < total; ++i) {
    let childObj = obj.getChild(i)
    if (childObj?.isValid() && func(childObj))
      return { childIdx = i, childObj }
  }
  return res
}

let findChildIndex = @(obj, func) findChild(obj, func).childIdx

let function color4ToDaguiString(color) {
  return format("%02X%02X%02X%02X",
    clamp(255 * color.a, 0, 255),
    clamp(255 * color.r, 0, 255),
    clamp(255 * color.g, 0, 255),
    clamp(255 * color.b, 0, 255))
}

let function daguiStringToColor4(colorStr) {
  let res = Color4()
  if (!colorStr.len())
    return res

  if (colorStr.slice(0, 1) == "#")
    colorStr = colorStr.slice(1)
  if (colorStr.len() != 8 && colorStr.len() != 6)
    return res

  let colorInt = hexStringToInt(colorStr)
  if (colorStr.len() == 8)
    res.a = ((colorInt & 0xFF000000) >> 24).tofloat() / 255
  res.r = ((colorInt & 0xFF0000) >> 16).tofloat() / 255
  res.g = ((colorInt & 0xFF00) >> 8).tofloat() / 255
  res.b = (colorInt & 0xFF).tofloat() / 255
  return res
}

let function multiplyDaguiColorStr(colorStr, multiplier) {
  return color4ToDaguiString(daguiStringToColor4(colorStr) * multiplier)
}

return {
  setFocusToNextObj
  getSelectedChild
  findChildIndex
  findChild
  check_obj
  show_obj
  getObjValue
  getObjValidIndex
  setObjPosition
  setPopupMenuPosAndAlign
  adjustWindowSize
  adjustWindowSizeByConfig
  countSizeInItems
  toPixels
  removeTextareaTags
  color4ToDaguiString
  multiplyDaguiColorStr
}
