//// See LICENSE.SiFive for license details.
//
//package starship.utils.stage
//
//import chisel3.stage.ChiselCircuitAnnotation
//import chisel3.stage.phases.{Convert, Elaborate}
//import firrtl.AnnotationSeq
//import firrtl.options.{Dependency, Phase}
//
//import freechips.rocketchip.util.{ElaborationArtefacts, BlackBoxedROM, ROMGenerator}
//
///** Dumps ROM information into a file */
//class GenerateROMs extends Phase {
//
//  override val prerequisites = Seq(Dependency[Elaborate])
//  override def invalidates(a: Phase) = false
//
//  override def transform(annotations: AnnotationSeq): AnnotationSeq = {
//    annotations.flatMap {
//      case a: ChiselCircuitAnnotation => {
//        val res = new StringBuilder
//        val configs =
//          a.circuit.components flatMap { m =>
//            m.id match {
//              case rom: BlackBoxedROM => Some((rom.name, ROMGenerator.lookup(rom)))
//              case _ => None
//            }
//          }
//        configs foreach { case (name, c) =>
//          res append s"name ${name} depth ${c.depth} width ${c.width}\n"
//        }
//        ElaborationArtefacts.add("rom.conf", res.toString)
//        Some(a)
//      }
//      case a => Some(a)
//    }
//  }
//}
