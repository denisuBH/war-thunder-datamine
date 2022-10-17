from "%scripts/dagui_library.nut" import *
//-file:undefined-const
//-file:undefined-variable
//checked for explicitness
#no-root-fallback
#implicit-this

let avatars = require("%scripts/user/avatars.nut")
let { setTimeout, clearTimer } = require("dagor.workcycle")

/**
  client api:
      requestInfo(users, successCb = null, errorCb = null)
                  - users - array of userId's string

  server api:
      "cln_get_users_terse_info" - char action returns DataBlock: {
                                                                      uid = {
                                                                        nick="string",
                                                                        pilotId="integer"
                                                                      }
                                                                      uid {...}
                                                                    }
**/

enum userInfoEventName
{
  UPDATED = "UserInfoManagerDataUpdated"
}

let MIN_TIME_BETWEEN_SAME_REQUESTS_MSEC = 300000
let MAX_REQUESTED_UID_NUM = 4
let usersInfo = {}
let usersForRequest = {}
local haveRequest = false

let function _getResponseWidthoutRequest(users)
{
  local fastResponse = {}
  let currentTime = ::dagor.getCurTime()
  foreach (userId in users)
  {
    let curUserInfo = usersInfo?[userId]
    if (curUserInfo == null ||
        currentTime - curUserInfo.updatingLastTime > MIN_TIME_BETWEEN_SAME_REQUESTS_MSEC)
    {
      fastResponse = null
      break
    }
    fastResponse[userId] <- curUserInfo
  }

  return fastResponse
}

let function _requestDataCommonSuccessCallback(response)
{
  local isUpdated = false
  foreach(uid, newUserInfo in response)
  {
    local curUserInfo = usersInfo?[uid]
    if (curUserInfo != null)
    {
      foreach(key, value in newUserInfo)
        if (newUserInfo[key] != curUserInfo?[key])
        {
          curUserInfo[key] <- newUserInfo[key]
          isUpdated = true
        }
    }
    else
    {
      curUserInfo = {}
      foreach(key, value in newUserInfo)
        curUserInfo[key] <- value
      isUpdated = true
    }

    curUserInfo.updatingLastTime <- ::dagor.getCurTime()
    usersInfo[uid] <- curUserInfo
  }

  if (isUpdated)
    ::broadcastEvent(userInfoEventName.UPDATED, { usersInfo = response })
}

let function _convertServerResponse(response)
{
  let res = {}
  foreach(uid, userInfo in response)
  {
    let pilotId = userInfo?.pilotId ?? ""
    let convertedData = {
      uid = uid
      name = userInfo?.nick ?? ""
      pilotIcon = avatars.getIconById(pilotId)
      title = userInfo?.title ?? ""
      clanTag =  userInfo?.clanTag ?? ""
      clanName =  userInfo?.clanName ?? ""
    }

    res[uid] <- convertedData
  }

  return res
}

let function clearRequestArray(users)
{
  foreach(uid,_ in users)
    if(uid in usersForRequest)
      usersForRequest.rawdelete(uid)
}

let function getUserListRequest(users = {})
{
  let reqList = []

  foreach(uid,_ in users)
  {
    reqList.append(uid)

    if(reqList.len() == MAX_REQUESTED_UID_NUM)
      return reqList
  }
  return reqList
}

let function requestUsersInfo(users, successCb = null, errorCb = null)
{
  if(haveRequest)
    return

  let fastResponse = _getResponseWidthoutRequest(users)
  if(fastResponse != null && successCb != null)
    return successCb(fastResponse)

  let usersList = ::g_string.implode(users, ";")

  let requestBlk = ::DataBlock()
  requestBlk.setStr("usersList", usersList)

  let function fullSuccessCb(response) {
    let parsedResponse = _convertServerResponse(response)
    _requestDataCommonSuccessCallback(parsedResponse)
    clearRequestArray(parsedResponse)
    if (successCb != null)
      successCb(parsedResponse)
    haveRequest = false
  }

  let function fullErrorCb(response) {
    errorCb?(response)
    haveRequest = false
  }

  haveRequest = true
  ::g_tasker.charRequestBlk("cln_get_users_terse_info", requestBlk, { showErrorMessageBox = false }, fullSuccessCb, fullErrorCb)
}

let function updateUsersInfo()
{
  clearTimer(updateUsersInfo)
  let updateUsersInfo_ = callee()
  let function errorCb(_) {
    clearTimer(updateUsersInfo_)
    setTimeout(MIN_TIME_BETWEEN_SAME_REQUESTS_MSEC, updateUsersInfo_)
  }

  let userListForRequestgetUser = getUserListRequest(usersForRequest)

  if(userListForRequestgetUser.len() == 0)
    return

  requestUsersInfo(userListForRequestgetUser, null, errorCb)
}

let function requestUserInfoData(userId)
{
  clearTimer(updateUsersInfo)

  if ((userId not in usersForRequest) && (userId not in usersInfo))
    usersForRequest[userId] <- true

  if(usersForRequest.len() == 0)
    return

  setTimeout(0.3, updateUsersInfo)
}

return {
  requestUserInfoData
  requestUsersInfo
}