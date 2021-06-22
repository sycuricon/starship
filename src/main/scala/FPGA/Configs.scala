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
import sifive.fpgashells.devices.xilinx.digilentnexysa7mig._

import sifive.blocks.devices.spi._
import sifive.blocks.devices.uart._

import sys.process._

case object FPGAExtDDRSizeKey extends Field[BigInt](0x40000000L) // 1 GB
case object FPGAFrequencyKey extends Field[Double](50)   // 50 MHz
case object BoardNameKey extends Field[String]("vc707")  // VC707

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

class WithExtDDRSize(MB: BigInt) extends Config((site, here, up) => {
  case FPGAExtDDRSizeKey => BigInt(MB.toInt * 1024 * 1024)
})

class WithBoard(name: String) extends Config((site, here, up) => {
  case BoardNameKey => name
})

class With25MHz  extends WithFrequency(25)
class With32MHz  extends WithFrequency(32)
class With50MHz  extends WithFrequency(50)
class With60MHz  extends WithFrequency(60)
class With100MHz extends WithFrequency(100)
class With150MHz extends WithFrequency(150)

class With128MB  extends WithExtDDRSize(128)
class With1024MB extends WithExtDDRSize(1024)

class WithVC707  extends WithBoard("vc707")
class WithA7     extends WithBoard("a7")

class StarshipFPGAConfig extends Config(
  new WithPeripherals ++
  new WithNBigCores(1) ++
  new StarshipBaseConfig().alter((site,here,up) => {
    case DebugModuleKey => None

    /* cpu-frequency = 100 MHz by default */
    case PeripheryBusKey => up(PeripheryBusKey, site).copy(dtsFrequency = Some(site(FPGAFrequencyKey).toInt * 1000000))

    /* timebase-frequency = 1 MHz always */
    case DTSTimebase => BigInt(1000000L)

    /* memory-size = 1 GB by default */
    /* Different boards have different MIG Configs and are not unified yet */
    case MemoryDigilentDDRKey => DigilentNexysA7MIGParams(address = Seq(AddressSet(0x80000000L,site(FPGAExtDDRSizeKey)-1)))
    case MemoryXilinxDDRKey => XilinxVC707MIGParams(address = Seq(AddressSet(0x80000000L,site(FPGAExtDDRSizeKey)-1)))
    case ExtMem => up(ExtMem, site).map(x => 
      x.copy(master = x.master.copy(size = site(FPGAExtDDRSizeKey))))

    case BootROMLocated(x) => up(BootROMLocated(x), site).map { p =>
      // invoke makefile for zero stage boot
      val freqMHz = site(FPGAFrequencyKey).toInt * 1000000
      val path = System.getProperty("user.dir")
      val make = s"make -C firmware/zsbl TARGET_FPGA=" + site(BoardNameKey) + s" ROOT_DIR=${path} img"
      println("[Leaving Starship] " + make)
      require (make.! == 0, "Failed to build bootrom")
      p.copy(hang = 0x10000, contentFileName = s"build/" + site(BoardNameKey) + s"/firmware/zsbl/bootrom.img")
    }
  })
)