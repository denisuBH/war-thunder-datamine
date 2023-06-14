//-file:plus-string
from "%scripts/dagui_library.nut" import *


let { handlerType } = require("%sqDagui/framework/handlerType.nut")

::gui_modal_payment <- function gui_modal_payment(params) {
  ::gui_start_modal_wnd(::gui_handlers.PaymentHandler, params)
}

::gui_handlers.PaymentHandler <- class extends ::gui_handlers.BaseGuiHandlerWT {
  wndType         = handlerType.MODAL
  sceneBlkName    = "%gui/payment.blk"
  owner           = null

  items = []
  selItem = null
  cancel_fn = null

  function initScreen() {
    this.initPaymentsList()
  }

  function initPaymentsList() {
    let paymentsObj = this.scene.findObject("content")
    foreach (idx, item in this.items) {
      let payItem = this.guiScene.createElementByObject(paymentsObj, "%gui/paymentItem.blk", "paymentItem", this)
      payItem.id = "payment_" + idx
      payItem.tooltip = loc(getTblValue("name", item, ""))
      payItem.findObject("payIcon")["background-image"] = getTblValue("icon", item, "")
      payItem.findObject("payText").setValue(getTblValue("icon", item, "") == "" ? loc(getTblValue("name", item, "")) : "")
    }
    ::move_mouse_on_child(paymentsObj)
  }

  function onPaymentSelect(obj) {
    if (!obj)
      return
    if (!this.items)
      return
    let item = this.items[(obj.id.slice(8)).tointeger()]
    if ("callback" in item && item.callback)
      if (this.owner)
        item.callback.call(this.owner)
    this.goBack()
  }
}
