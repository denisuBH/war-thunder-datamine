from "%scripts/dagui_library.nut" import *
//checked for explicitness
#no-root-fallback
#explicit-this

::mission_rules.EnduringConfrontation <- class extends ::mission_rules.Base
{
  function isStayOnRespScreen()
  {
    return false
  }
}