package starship.utils.stage

import mainargs._
import chisel3.RawModule
import chisel3.stage.ChiselGeneratorAnnotation
import firrtl.options.{Dependency, PhaseManager, TargetDirAnnotation}
import freechips.rocketchip.diplomacy.LazyModule
import org.chipsalliance.cde.config.{Config, Parameters}


object FIRRTLGenerator {
  @main def elaborate(
    @arg(name = "dir", doc = "output directory") dir: String,
    @arg(name = "top", doc = "top Module or LazyModule fullpath") top: String,
    @arg(name = "config", doc = "CDE configs") config: String,
    @arg(name = "name", doc = "output base name") name: Option[String]
  ) = {
    var outputName: String = name.getOrElse(s"${top}_$config")
    val gen = () => 
      Class
        .forName(top)
        .getConstructor(classOf[Parameters])
        .newInstance(new Config(config.split(',').foldRight(Parameters.empty) {
          case (currentName, config) =>
            val currentConfig = Class.forName(currentName).newInstance.asInstanceOf[Config]
            currentConfig ++ config
        })) match {
          case m: RawModule => m
          case lm: LazyModule => LazyModule(lm).module
        }

    val pm = new PhaseManager(
      Seq(
        Dependency[chisel3.stage.phases.Elaborate],
        Dependency[starship.utils.stage.GenerateROMs],
        Dependency[chisel3.stage.phases.Convert]
      )
    )

    val annos = pm.transform(Seq(
      TargetDirAnnotation(dir),
      ChiselGeneratorAnnotation(() => gen())
    )).flatMap {
        case firrtl.stage.FirrtlCircuitAnnotation(circuit) =>
          os.write.over(os.Path(dir) / s"$outputName.fir", circuit.serialize)
          None
        case _: chisel3.stage.ChiselCircuitAnnotation => None
        case _: chisel3.stage.DesignAnnotation[_] => None
        case a => Some(a)
      }
    os.write.over(os.Path(dir) / s"$outputName.anno.json", firrtl.annotations.JsonProtocol.serialize(annos))
    freechips.rocketchip.util.ElaborationArtefacts.files.foreach {
      case (ext, contents) => os.write.over(os.Path(dir) / s"$outputName.$ext", contents())
    }
  }

  def main(args: Array[String]): Unit = ParserForMethods(this).runOrExit(args)
}

