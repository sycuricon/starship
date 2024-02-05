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

import sys.process._

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

class StarshipStateInitConfig extends Config(
  new WithPeripherals ++
  new StarshipBaseConfig().alter((site,here,up) => {
    case DebugModuleKey => None
    case PeripheryBusKey => up(PeripheryBusKey, site).copy(dtsFrequency = Some(site(FrequencyKey).toInt * 1000000))
    /* timebase-frequency = 1 MHz */
    case DTSTimebase => BigInt(1000000L)
    case ExtMem => up(ExtMem, site).map(x => x.copy(master = x.master.copy(size = 0x40000L)))
    case BootROMLocated(x) => up(BootROMLocated(x), site).map { p =>
      val path = System.getProperty("user.dir")
      val gen_loader = s"""python3 firmware/rvsnap/src/generator.py
        --input conf/dummy_state.hjson --format hex,32 --output build/firmware/rvsnap --pmp 4"""
      val make_loader = s"make -C firmware/rvsnap/src/loader ROOT_DIR=${path} img"
      println("[Leaving rocketchip] " + gen_loader)
      require (gen_loader.! == 0, "Failed to build bootrom")
      println("[Leaving rocketchip] " + make_loader)
      require (make_loader.! == 0, "Failed to build bootrom")
      println("[rocketchip Continue]")
      p.copy(hang = 0x10000, contentFileName = s"build/firmware/rvsnap/init.img")
    }
  })
)
