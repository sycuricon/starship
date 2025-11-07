package starship

// import starship.fpga._

import chisel3._

import freechips.rocketchip.system._
import org.chipsalliance.cde.config._
import freechips.rocketchip.subsystem._
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.devices.debug._
import freechips.rocketchip.devices.tilelink._
import freechips.rocketchip.util.SystemFileName


import sifive.blocks.devices.uart._
import sifive.blocks.devices.spi._

import sys.process._

case object FrequencyKey extends Field[Double](50)   // 50 MHz

class WithFrequency(MHz: Double) extends Config((site, here, up) => {
  case FrequencyKey => MHz
})

class With25MHz  extends WithFrequency(25)
class With50MHz  extends WithFrequency(50)
class With100MHz extends WithFrequency(100)
class With150MHz extends WithFrequency(150)

class WithRocketCore extends Config(new freechips.rocketchip.rocket.WithNBigCores(1))
class WithBOOMCore extends Config(new boom.v3.common.WithBoomCommitLogPrintf ++ new boom.v3.common.WithNSmallBooms(1))
class WithCVA6Core extends Config(new starship.cva6.WithNCVA6Cores(1))
class WithXiangShanCore extends Config(new starship.xiangshan.WithNXSCores(1))

class StarshipBaseConfig extends Config(
  // new WithRoccExample ++
  new WithExtMemSize(0x80000000L) ++
  new WithNExtTopInterrupts(0) ++
  new WithDTS("zjv,starship", Nil) ++
  new WithEdgeDataBits(64) ++
  new WithCoherentBusTopology ++
  new WithoutTLMonitors++
  new BaseConfig()
)
