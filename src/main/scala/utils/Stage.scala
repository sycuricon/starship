package starship.utils.stage

import chisel3.stage._
import firrtl.stage._
import firrtl.options._
import firrtl.AnnotationSeq
import firrtl.annotations._
import firrtl.options.Viewer._
import firrtl.options.PhaseManager._
import firrtl.transforms._

import starship.utils.transform._


sealed trait StarshipOption extends Unserializable { this: Annotation => }

//case class TestHarnessVerilogAnnotation(file: String) extends NoTargetAnnotation with StarshipOption
//object TestHarnessVerilogAnnotation extends HasShellOptions {
//  override val options = Seq(
//    new ShellOption[String](
//      longOption = "thn-verilog",
//      shortOption = Some("thv"),
//      helpValueName = Some("<testharness verilog file>"),
//      toAnnotationSeq = s => Seq(TestHarnessVerilogAnnotation(s)),
//      helpText = "testharness output verilog file"
//    )
//  )
//}

case class TestHarnessModuleAnnotation(name: String) extends NoTargetAnnotation with StarshipOption
object TestHarnessModuleAnnotation extends HasShellOptions {
  override val options = Seq(
    new ShellOption[String](
      longOption = "thn-module",
      shortOption = Some("TH"),
      helpValueName = Some("<testharness module name>"),
      toAnnotationSeq = s => Seq(TestHarnessModuleAnnotation(s)),
      helpText = "testharness module name"     
    )
  )
}

//case class TestHarnessIncludeAnnotation(file: String) extends NoTargetAnnotation with StarshipOption
//object TestHarnessIncludeAnnotation extends HasShellOptions {
//  override val options = Seq(
//    new ShellOption[String](
//      longOption = "thn-include",
//      shortOption = Some("thi"),
//      helpValueName = Some("<testharness include file>"),
//      toAnnotationSeq = s => Seq(TestHarnessIncludeAnnotation(s)),
//      helpText = "testharness output include file"
//    )
//  )
//}
//
//case class TestHarnessMemConfigAnnotation(file: String) extends NoTargetAnnotation with StarshipOption
//object TestHarnessMemConfigAnnotation extends HasShellOptions {
//  override val options = Seq(
//    new ShellOption[String](
//      longOption = "thn-mem-config",
//      shortOption = Some("thmc"),
//      helpValueName = Some("<testharness memory config file>"),
//      toAnnotationSeq = s => Seq(TestHarnessMemConfigAnnotation(s)),
//      helpText = "testharness output memory config file"
//    )
//  )
//}

case class TopModuleAnnotation(name: String) extends NoTargetAnnotation with StarshipOption
object TopModuleAnnotation extends HasShellOptions {
  override val options = Seq(
    new ShellOption[String](
      longOption = "top-module",
      shortOption = Some("T"),
      helpValueName = Some("<top module name>"),
      toAnnotationSeq = s => Seq(TopModuleAnnotation(s)),
      helpText = "top module name"     
    )
  )
}

//case class TopIncludeAnnotation(file: String) extends NoTargetAnnotation with StarshipOption
//object TopIncludeAnnotation extends HasShellOptions {
//  override val options = Seq(
//    new ShellOption[String](
//      longOption = "top-include",
//      shortOption = Some("ti"),
//      helpValueName = Some("<top include file>"),
//      toAnnotationSeq = s => Seq(TopIncludeAnnotation(s)),
//      helpText = "top output include file"
//    )
//  )
//}
//
//case class TopMemConfigAnnotation(file: String) extends NoTargetAnnotation with StarshipOption
//object TopMemConfigAnnotation extends HasShellOptions {
//  override val options = Seq(
//    new ShellOption[String](
//      longOption = "top-mem-config",
//      shortOption = Some("tmc"),
//      helpValueName = Some("<top memory config file>"),
//      toAnnotationSeq = s => Seq(TopMemConfigAnnotation(s)),
//      helpText = "top output memory config file"
//    )
//  )
//}

case class StarshipIncludeAnnotation(file: String) extends NoTargetAnnotation with StarshipOption
object StarshipIncludeAnnotation extends HasShellOptions {
  override val options = Seq(
    new ShellOption[String](
      longOption = "out-include-file",
      shortOption = Some("oinc"),
      helpValueName = Some("<include file>"),
      toAnnotationSeq = s => Seq(StarshipIncludeAnnotation(s)),
      helpText = "output include file"
    )
  )
}

trait StarshipCli { this: Shell =>

  parser.note("Starship Options")
  Seq(
//    TestHarnessVerilogAnnotation,
    TestHarnessModuleAnnotation,
//    TestHarnessIncludeAnnotation,
//    TestHarnessMemConfigAnnotation,
    TopModuleAnnotation,
//    TopIncludeAnnotation,
//    TopMemConfigAnnotation,
    StarshipIncludeAnnotation
  ).foreach(_.addOptions(parser))
}

// Now we can use following to referrence options
// val thVlog = view[StarshipOptions](annotations).thVlog
class StarshipOptions private[stage] (
//  val thVlog:        Option[String] = None,
  val thName:        Option[String] = None,
//  val thInclude:     Option[String] = None,
//  val thMem:         Option[String] = None,
  val topName:       Option[String] = None,
//  val topInclude:    Option[String] = None,
//  val topMem:        Option[String] = None,
  val incOutFile:    Option[String] = None) {

  private[stage] def copy(
//    thVlog:        Option[String] = thVlog,
    thName:        Option[String] = thName,
//    thInclude:     Option[String] = thInclude,
//    thMem:         Option[String] = thMem,
    topName:       Option[String] = topName,
//    topInclude:    Option[String] = topInclude,
//    topMem:        Option[String] = topMem,
    incOutFile:    Option[String] = incOutFile): StarshipOptions = {

    new StarshipOptions (
//      thVlog=thVlog,
      thName=thName,
//      thInclude=thInclude,
//      thMem=thMem,
      topName=topName,
//      topInclude=topInclude,
//      topMem=topMem,
      incOutFile=incOutFile
    )
  }
}

class StarshipStage extends Stage {

  override val shell = new Shell("starship") with StarshipCli with ChiselCli with FirrtlCli
  val targets: Seq[PhaseDependency] = Seq(
    Dependency[firrtl.stage.phases.Compiler]
  )

  private val pm = new PhaseManager(targets)

  override def run(annotations: AnnotationSeq): AnnotationSeq = {

//    val thVlog = view[StarshipOptions](annotations).thVlog
    val thName = view[StarshipOptions](annotations).thName
//    val thInclude = view[StarshipOptions](annotations).thInclude
//    val thMem = view[StarshipOptions](annotations).thMem
    val topName = view[StarshipOptions](annotations).topName
//    val topInclude = view[StarshipOptions](annotations).topInclude
//    val topMem = view[StarshipOptions](annotations).topMem
    val incOutFile = view[StarshipOptions](annotations).incOutFile

    if (topName.isEmpty && thName.isEmpty) {
      throw new RuntimeException(s"Provide at least one of the top module or testharness module!")
    } else if (topName.isEmpty && thName.isDefined) {
      throw new RuntimeException(s"Invalid Top when TestHarness assert! ")
    }


    val starshipAnnotation =
    if (topName.isDefined && thName.isEmpty) {
      logger.info(s"Generate Top         ${thName}  ${topName}")
      Seq(
        RunFirrtlTransformAnnotation(Dependency[ExtractTop]),
        BlackBoxResourceFileNameAnno(incOutFile.get),
        RunFirrtlTransformAnnotation(Dependency[RegisterRecord]),
        RunFirrtlTransformAnnotation(Dependency[CoverageInstrument])
      )
    } else { // (topName.isDefined && thName.isDefined)
      logger.info(s"Generate TestHarness  ${thName}  ${topName}")
      Seq(
        RunFirrtlTransformAnnotation(Dependency[ExtractTestHarness]),
        BlackBoxResourceFileNameAnno(incOutFile.get),
        AddModuleSuffixAnnotation("_tb"),
        RunFirrtlTransformAnnotation(Dependency[AddModuleSuffix]),
        RunFirrtlTransformAnnotation(Dependency[RegisterRecord])
      )
    } 

    pm.transform(annotations ++ starshipAnnotation)
  }
}

object Generator extends StageMain(new StarshipStage)
