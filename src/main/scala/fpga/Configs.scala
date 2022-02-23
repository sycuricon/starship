package starship.fpga

import starship._

import chisel3._

import freechips.rocketchip.system._
import freechips.rocketchip.config._
import freechips.rocketchip.subsystem._
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.devices.debug._
import freechips.rocketchip.devices.tilelink._

import sifive.fpgashells.shell._
import sifive.fpgashells.clocks._
import sifive.fpgashells.ip.xilinx._
import sifive.fpgashells.shell.xilinx._
import sifive.fpgashells.devices.xilinx.xilinxvc707mig._

import sifive.blocks.devices.spi._
import sifive.blocks.devices.uart._

import sys.process._

case object VCU707DDRSizeKey extends Field[BigInt](0x40000000L) // 1 GB
case object FPGAFrequencyKey extends Field[Double](50)   // 50 MHz

class WithPeripherals extends Config((site, here, up) => {
  case PeripheryUARTKey => List(
    UARTParams(address = BigInt(0x64000000L)))
  case PeripherySPIKey => List(
    SPIParams(rAddress = BigInt(0x64001000L)))
  case MaskROMLocated(x) => List(
    MaskROMParams(BigInt(0x20000L), "StarshipROM")
  )
})

class WithFrequency(MHz: Double) extends Config((site, here, up) => {
  case FPGAFrequencyKey => MHz
})

class With25MHz  extends WithFrequency(25)
class With50MHz  extends WithFrequency(50)
class With100MHz extends WithFrequency(100)
class With150MHz extends WithFrequency(150)

class StarshipFPGAConfig extends Config(
  new WithPeripherals ++
  new WithNBigCores(1) ++
  new StarshipBaseConfig().alter((site,here,up) => {
    case DebugModuleKey => None

    case PeripheryBusKey => up(PeripheryBusKey, site).copy(dtsFrequency = Some(site(FPGAFrequencyKey).toInt * 1000000))

    /* timebase-frequency = 1 MHz */
    case DTSTimebase => BigInt(1000000L)

    /* memory-size = 1 GB */
    case MemoryXilinxDDRKey => XilinxVC707MIGParams(address = Seq(AddressSet(0x80000000L,site(VCU707DDRSizeKey)-1)))
    case ExtMem => up(ExtMem, site).map(x => 
      x.copy(master = x.master.copy(size = site(VCU707DDRSizeKey))))

    case BootROMLocated(x) => up(BootROMLocated(x), site).map { p =>
      // invoke makefile for zero stage boot
      val freqMHz = site(FPGAFrequencyKey).toInt * 1000000
      val path = System.getProperty("user.dir")
      val make = s"make -C firmware/zsbl ROOT_DIR=${path} img"
      println("[Leaving rocketchip] " + make)
      require (make.! == 0, "Failed to build bootrom")
      println("[rocketchip Continue]")
      p.copy(hang = 0x10000, contentFileName = s"build/firmware/zsbl/bootrom.img")
    }
  })
)