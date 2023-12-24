package starship.axi4

import starship._

import chisel3._

import freechips.rocketchip.system._
import org.chipsalliance.cde.config._
import freechips.rocketchip.subsystem._
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.devices.debug._
import freechips.rocketchip.devices.tilelink._


class WithPeripherals extends Config((site, here, up) => {
  case MaskROMLocated(x) => List(
    MaskROMParams(BigInt(0x20000L), "StarshipROM")
  )
})

class StarshipAxi4DebugConfig extends Config(
  new WithPeripherals ++
  new WithJtagDTM ++
  new WithClockGateModel() ++
  new StarshipBaseConfig().alter((site,here,up) => {
    case PeripheryBusKey => up(PeripheryBusKey, site).copy(dtsFrequency = Some(site(FrequencyKey).toInt * 1000000))
    /* timebase-frequency = 1 MHz */
    case DTSTimebase => BigInt(1000000L)
  })
)
