from "%scripts/dagui_library.nut" import *
//checked for explicitness
#no-root-fallback
#explicit-this

let performActionTable = {}
let visibilityByAction = {}

let addPromoAction = function(actionId, actionFunc, visibilityFunc = null) {
  performActionTable[actionId] <- actionFunc
  if (visibilityFunc != null)
    visibilityByAction[actionId] <- visibilityFunc
}

let getPromoAction = @(actionId) performActionTable?[actionId]

let isVisiblePromoByAction = @(actionId, params) visibilityByAction?[actionId](params) ?? true

return {
  addPromoAction
  getPromoAction
  isVisiblePromoByAction
}