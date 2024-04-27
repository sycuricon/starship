package starship.asic

import starship._

import chisel3._

import freechips.rocketchip.system._
import org.chipsalliance.cde.config._
import freechips.rocketchip.subsystem._
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.devices.debug._
import freechips.rocketchip.devices.tilelink._

import sifive.blocks.devices.uart._


class WithPeripherals extends Config((site, here, up) => {
  case PeripheryUARTKey => List(
    UARTParams(address = BigInt(0x64000000L)))
  case MaskROMLocated(x) => List(
    MaskROMParams(BigInt(0x20000L), "StarshipROM")
  )
  case MagicKey => up(DebugModuleKey) match {
      case None => Some(MagicParams(baseAddress = 0))
      case _ => None
  }
  case ResetManagerKey => Some(ResetManagerParams())
})

class StarshipSimConfig extends Config(
  new WithPeripherals ++
  new StarshipBaseConfig().alter((site,here,up) => {
    case DebugModuleKey => None
    case PeripheryBusKey => up(PeripheryBusKey, site).copy(dtsFrequency = Some(site(FrequencyKey).toInt * 1000000))
    /* timebase-frequency = 1 MHz */
    case DTSTimebase => BigInt(1000000L)
  })
)

class StarshipSimDebugConfig extends Config(
  new WithPeripherals ++
  new WithJtagDTM ++
  new WithClockGateModel() ++
  new StarshipBaseConfig().alter((site,here,up) => {
    case PeripheryBusKey => up(PeripheryBusKey, site).copy(dtsFrequency = Some(site(FrequencyKey).toInt * 1000000))
    /* timebase-frequency = 1 MHz */
    case DTSTimebase => BigInt(1000000L)
  })
)

class StarshipSimMiniConfig extends Config(
  new StarshipBaseConfig().alter((site,here,up) => {
    case DebugModuleKey => None
    case PeripheryBusKey => up(PeripheryBusKey, site).copy(dtsFrequency = Some(site(FrequencyKey).toInt * 1000000))
    /* timebase-frequency = 1 MHz */
    case DTSTimebase => BigInt(1000000L)
  })
)
