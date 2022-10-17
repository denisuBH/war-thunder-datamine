from "%scripts/dagui_library.nut" import *
//checked for explicitness
#no-root-fallback
#explicit-this

let { addListenersWithoutEnv } = require("%sqStdLibs/helpers/subscriptions.nut")
let { set_restricted_downloads_mode } = require("hangarEventCommand")

addListenersWithoutEnv({
  BeforeJoinQueue = @(p) set_restricted_downloads_mode(true)
  QueueChangeState = @(p) !::SessionLobby.isInJoiningGame() ? set_restricted_downloads_mode(::queues.isAnyQueuesActive()) : null
})