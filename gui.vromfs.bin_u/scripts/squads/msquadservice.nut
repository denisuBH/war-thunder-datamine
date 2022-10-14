from "%scripts/dagui_library.nut" import *
//-file:undefined-const
//-file:undefined-variable
//checked for explicitness
#no-root-fallback
#implicit-this

global enum msquadErrorId
{
  ALREADY_IN_SQUAD = "ALREADY_IN_SQUAD"
  NOT_SQUAD_LEADER = "NOT_SQUAD_LEADER"
  NOT_SQUAD_MEMBER = "NOT_SQUAD_MEMBER"
  SQUAD_FULL = "SQUAD_FULL"
  SQUAD_NOT_INVITED = "SQUAD_NOT_INVITED"
}

::msquad <- {
  function create(successCallback = null, errorCallback = null, requestOptions = null)
  {
    ::request_matching("msquad.create_squad", successCallback, errorCallback, null, requestOptions)
  }

  function disband(successCallback = null, errorCallback = null, requestOptions = null)
  {
    ::request_matching("msquad.disband_squad", successCallback, errorCallback, null, requestOptions)
  }

  function requestInfo(successCallback = null, errorCallback = null, requestOptions = null)
  {
    ::request_matching("msquad.get_info", successCallback, errorCallback, null, requestOptions)
  }

  function leave(successCallback = null, errorCallback = null, requestOptions = null)
  {
    ::request_matching("msquad.leave_squad", successCallback, errorCallback, null, requestOptions)
  }

  function invitePlayer(uid, successCallback = null, errorCallback = null, requestOptions = null)
  {
    ::request_matching("msquad.invite_player", successCallback, errorCallback, {userId = _convertIdToInt(uid)}, requestOptions)
  }

  function dismissMember(uid, successCallback = null, errorCallback = null, requestOptions = null)
  {
    ::request_matching("msquad.dismiss_member", successCallback, errorCallback, {userId = _convertIdToInt(uid)}, requestOptions)
  }

  function transferLeadership(uid, successCallback = null, errorCallback = null, requestOptions = null)
  {
    ::request_matching("msquad.transfer_squad", successCallback, errorCallback, {userId = _convertIdToInt(uid)}, requestOptions)
  }

  function acceptInvite(sid, successCallback = null, errorCallback = null, requestOptions = null)
  {
    ::request_matching("msquad.accept_invite", successCallback, errorCallback, {squadId = _convertIdToInt(sid)}, requestOptions)
  }

  function rejectInvite(sid, successCallback = null, errorCallback = null, requestOptions = null)
  {
    ::request_matching("msquad.reject_invite", successCallback, errorCallback, {squadId = _convertIdToInt(sid)}, requestOptions)
  }

  function revokeInvite(uid, successCallback = null, errorCallback = null, requestOptions = null)
  {
    ::request_matching("msquad.revoke_invite", successCallback, errorCallback, {userId = _convertIdToInt(uid)}, requestOptions)
  }

  function setData(data, successCallback = null, errorCallback = null, requestOptions = null)
  {
    ::request_matching("msquad.set_squad_data", successCallback, errorCallback, data, requestOptions)
  }

  function setMyMemberData(uid, data, successCallback = null, errorCallback = null, requestOptions = null)
  {
    local params = {
      userId = _convertIdToInt(uid)
      data = data
    }

    ::request_matching("msquad.set_member_data", successCallback, errorCallback, params, requestOptions)
  }

  function requestMemberData(uid, successCallback = null, errorCallback = null, requestOptions = null)
  {
    ::request_matching("msquad.get_member_data", successCallback, errorCallback, {userId = _convertIdToInt(uid)}, requestOptions)
  }

  function inviteToWWBattle(data, successCallback = null, errorCallback = null, requestOptions = null)
  {
    ::request_matching("msquad.request_action", successCallback, errorCallback, data, requestOptions)
  }

  function _convertIdToInt(id)
  {
    if (::u.isString(id))
      id = id.tointeger()

    return id
  }
}
