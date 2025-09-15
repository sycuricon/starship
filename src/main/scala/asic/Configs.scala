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

import sys.process._

case object SimFrequencyKey extends Field[Double](50)   // 50 MHz

class WithPeripherals extends Config((site, here, up) => {
  case PeripheryUARTKey => List(
    UARTParams(address = BigInt(0x64000000L)))
  case MaskROMLocated(x) => List(
    MaskROMParams(BigInt(0x20000L), "StarshipROM")
  )
})

class WithFrequency(MHz: Double) extends Config((site, here, up) => {
  case SimFrequencyKey => MHz
})

class With25MHz  extends WithFrequency(25)
class With50MHz  extends WithFrequency(50)
class With100MHz extends WithFrequency(100)
class With150MHz extends WithFrequency(150)

class StarshipSimConfig extends Config(
  new WithPeripherals ++
  new WithNBigCores(1) ++
  new StarshipBaseConfig().alter((site,here,up) => {
    case DebugModuleKey => None
    case PeripheryBusKey => up(PeripheryBusKey, site).copy(dtsFrequency = Some(site(SimFrequencyKey).toInt * 1000000))

    /* timebase-frequency = 1 MHz */
    case DTSTimebase => BigInt(1000000L)

    /* memory-size = 1 GB */
    case ExtMem => up(ExtMem, site).map(x => 
      x.copy(master = x.master.copy(size = 0x80000000L)))

    case BootROMLocated(x) => up(BootROMLocated(x), site).map { p =>
      // invoke makefile for zero stage boot
      val freqMHz = site(SimFrequencyKey).toInt * 1000000
      val path = System.getProperty("user.dir")
      val make = s"make -C firmware/zsbl ROOT_DIR=${path} img"
      println("[Leaving Starship] " + make)
      require (make.! == 0, "Failed to build bootrom")
      p.copy(hang = 0x10000, contentFileName = s"build/firmware/zsbl/bootrom.img")
    }
  })
)