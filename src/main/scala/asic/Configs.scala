package starship.asic

import starship._

import chisel3._

import freechips.rocketchip.system._
import freechips.rocketchip.config._
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
})

class StarshipSimConfig extends Config(
  new WithPeripherals ++
  // new WithNBigCores(1) ++
  new starship.cva6.WithNCVA6Cores(1) ++
  new StarshipBaseConfig().alter((site,here,up) => {
    case DebugModuleKey => None

    case PeripheryBusKey => up(PeripheryBusKey, site).copy(dtsFrequency = Some(site(FrequencyKey).toInt * 1000000))

    /* timebase-frequency = 1 MHz */
    case DTSTimebase => BigInt(1000000L)
  })
)