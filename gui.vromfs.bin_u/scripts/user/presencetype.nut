from "%scripts/dagui_library.nut" import *
//-file:undefined-const
//-file:undefined-variable
//checked for explicitness
#no-root-fallback
#implicit-this

let enums = require("%sqStdLibs/helpers/enums.nut")
let QUEUE_TYPE_BIT = require("%scripts/queue/queueTypeBit.nut")
let { profileCountrySq } = require("%scripts/user/playerCountry.nut")

enum presenceCheckOrder {
  IN_GAME_WW
  IN_GAME
  IN_QUEUE
  IN_WW_BATTLE_PREPARE
  IDLE
}

::g_presence_type <- {
  types = []
}

::g_presence_type.template <- {
  typeName = "" //Generic from type.
  checkOrder = presenceCheckOrder.IDLE
  locId = ""
  isInBattle = false
  isMatch = @() false
  getParams = function() {
    let params = { presenceId = typeName }
    updateParams(params)
    return params
  }
  updateParams = @(params) params
  getLocText = @(presenceParams) loc(locId)
  canInviteToWWBattle = true
}

enums.addTypesByGlobalName("g_presence_type", {
  IDLE = {
    checkOrder = presenceCheckOrder.IDLE
    locId = "status/idle"
    isMatch = @() true
  }

  IN_QUEUE = {
    checkOrder = presenceCheckOrder.IN_QUEUE
    locId = "status/in_queue"
    queueTypeMask = QUEUE_TYPE_BIT.EVENT | QUEUE_TYPE_BIT.DOMINATION | QUEUE_TYPE_BIT.NEWBIE
    isMatch = @() ::queues.isAnyQueuesActive(queueTypeMask)
    updateParams = function(params) {
      let queue = ::queues.getActiveQueueWithType(queueTypeMask)
      params.eventName <- ::events.getEventEconomicName(::queues.getQueueEvent(queue))
      params.country <- ::queues.getQueueCountry(queue)
    }
    getLocText = @(presenceParams) loc(locId, {
      gameMode = ::events.getNameByEconomicName(presenceParams?.eventName ?? "")
      country = loc(presenceParams?.country ?? "")
    })
  }

  IN_GAME = {
    checkOrder = presenceCheckOrder.IN_GAME
    locId = "status/in_game"
    isInBattle = true
    isMatch = @() ((::is_in_flight() && !::g_mis_custom_state.getCurMissionRules().isWorldWar)
                    || ::SessionLobby.isInRoom())
    canInviteToWWBattle = false
    updateParams = function(params) {
      params.gameMod <- ::get_game_mode()
      params.eventName <- ::events.getEventEconomicName(::SessionLobby.getRoomEvent())
      params.country <- profileCountrySq.value
    }
    getLocText = function (presenceParams) {
      let eventName = presenceParams?.eventName ?? ""
      return loc(locId,
        { gameMode = eventName == "" ? ::get_game_mode_loc_name(presenceParams?.gameMod)
          : ::events.getNameByEconomicName(presenceParams?.eventName)
          country = loc(presenceParams?.country ?? "")
        })
    }
  }

  IN_QUEUE_WW = {
    checkOrder = presenceCheckOrder.IN_QUEUE
    locId = "status/in_queue_ww"
    queueTypeMask = QUEUE_TYPE_BIT.WW_BATTLE
    isMatch = @() ::is_worldwar_enabled() && ::queues.isAnyQueuesActive(queueTypeMask)
    updateParams = function(params) {
      let queue = ::queues.getActiveQueueWithType(queueTypeMask)
      let operationId = ::queues.getQueueOperationId(queue)
      let battleId = queue instanceof ::queue_classes.WwBattle ? queue.getQueueWwBattleId() : ""
      let operation = ::g_ww_global_status_actions.getOperationById(operationId)
      if (!operation)
        return
      params.operationId <- operationId
      params.battleId <- battleId
      params.mapId <- operation.getMapId()
      params.country <- ::queues.getQueueCountry(queue)
    }
    getLocText = function(presenceParams) {
      let map = ::g_ww_global_status_actions.getMapByName(presenceParams?.mapId)
      return loc(locId,
        { operationName = map
            ? ::WwOperation.getNameTextByIdAndMapName(presenceParams?.operationId, map.getNameText())
            : ""
          country = loc(presenceParams?.country ?? "")
        })
    }
  }

  IN_GAME_WW = {
    checkOrder = presenceCheckOrder.IN_GAME_WW
    locId = "status/in_game_ww"
    isInBattle = true
    isMatch = @() ::is_worldwar_enabled() && ::is_in_flight() && ::g_mis_custom_state.getCurMissionRules().isWorldWar
    canInviteToWWBattle = false
    updateParams = function(params) {
      let operationId = ::SessionLobby.getOperationId()
      let operation = ::g_ww_global_status_actions.getOperationById(operationId)
      if (!operation)
        return
      params.operationId <- operationId
      params.battleId <- ::SessionLobby.getWwBattleId()
      params.mapId <- operation.getMapId()
      params.country <- operation.getMyClanCountry() || profileCountrySq.value
    }
    getLocText = function(presenceParams) {
      let map = ::g_ww_global_status_actions.getMapByName(presenceParams?.mapId)
      return loc(locId,
        { operationName = map
            ? ::WwOperation.getNameTextByIdAndMapName(presenceParams?.operationId ?? "", map.getNameText())
            : ""
          country = loc(presenceParams?.country ?? "")
        })
    }
  }

  IN_WW_BATTLE_PREPARE = {
    checkOrder = presenceCheckOrder.IN_WW_BATTLE_PREPARE
    locId = "status/in_prepare_ww"
    isMatch = @() ::is_worldwar_enabled() && ::g_squad_manager.getWwOperationBattle() != null
    updateParams = function(params) {
      params.operationId <- ::g_squad_manager.getWwOperationId()
      params.battleId <- ::g_squad_manager.getWwOperationBattle()
      params.country <- ::g_squad_manager.getWwOperationCountry()
    }
    getLocText = function(presenceParams) {
      let operationId = presenceParams?.operationId
      let operation = ::g_ww_global_status_actions.getOperationById(operationId)
      if (!operation)
        return ""

      let map = ::g_ww_global_status_actions.getMapByName(operation.getMapId())
      let text = loc(locId,
        { operationName = map
            ? ::WwOperation.getNameTextByIdAndMapName(operationId, map.getNameText()) : ""
          country = loc(presenceParams?.country ?? "")
        })
      return text
    }
  }
}, null, "typeName")

::g_presence_type.types.sort(@(a, b) a.checkOrder <=> b.checkOrder)

::g_presence_type.getCurrent <- function getCurrent()
{
  foreach(presenceType in types)
    if (presenceType.isMatch())
      return presenceType
  return IDLE
}

::g_presence_type.getByPresenceParams <- function getByPresenceParams(presenceParams)
{
  return this?[presenceParams?.presenceId] ?? IDLE
}
