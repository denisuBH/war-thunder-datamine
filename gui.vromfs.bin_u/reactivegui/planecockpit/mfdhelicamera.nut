from "%rGui/globals/ui_library.nut" import *
let { paramsTable, turretAngles, launchDistanceMax, sight, rangeFinder, lockSight, targetSize } = require("%rGui/airHudElems.nut")
let { IsMfdSightHudVisible, MfdSightMask, MfdSightPosSize, SecondaryMask, HudParamColor } = require("%rGui/airState.nut")
let { ceil } = require("%sqstd/math.nut")

let sightSh = @(h) ceil(h * MfdSightPosSize[3] / 100)
let sightSw = @(w) ceil(w * MfdSightPosSize[2] / 100)
let sightHdpx = @(px) ceil(px * MfdSightPosSize[3] / 1024)

let mfdSightParamTablePos = Watched([hdpx(30), hdpx(175)])

let mfdSightParamsTable = paramsTable(MfdSightMask, SecondaryMask,
  hdpx(250), hdpx(28),
  mfdSightParamTablePos,
  hdpx(3))

let function mfdSightHud() {
  return {
    watch = IsMfdSightHudVisible
    children = IsMfdSightHudVisible.value ?
    [
      turretAngles(HudParamColor, sightSw(15), sightHdpx(150), sightSw(50), sightSh(90))
      launchDistanceMax(HudParamColor, sightSw(15), sightHdpx(150), sightSw(50), sightSh(90))
      sight(HudParamColor, sightSw(50), sightSh(50), sightHdpx(500))
      rangeFinder(HudParamColor, sightSw(50), sightSh(58))
      lockSight(HudParamColor, sightHdpx(150), sightHdpx(100), sightSw(50), sightSh(50))
      targetSize(HudParamColor, sightSw(100), sightSh(100))
      mfdSightParamsTable(HudParamColor)
    ]
    : null
  }
}

return mfdSightHud