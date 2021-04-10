package starship


import freechips.rocketchip.system._
import freechips.rocketchip.subsystem._
import freechips.rocketchip.config.Config

class DefaultConfig extends Config(
  new WithNBigCores(1) ++ 
  new WithCoherentBusTopology ++ 
  new BaseConfig
)