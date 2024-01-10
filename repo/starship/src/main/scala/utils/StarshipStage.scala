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
    TestHarnessModuleAnnotation,
    TopModuleAnnotation,
    StarshipIncludeAnnotation
  ).foreach(_.addOptions(parser))
}

class StarshipOptions private[stage] (
  val thName:        Option[String] = None,
  val topName:       Option[String] = None,
  val incOutFile:    Option[String] = None) {

  private[stage] def copy(
    thName:        Option[String] = thName,
    topName:       Option[String] = topName,
    incOutFile:    Option[String] = incOutFile): StarshipOptions = {

    new StarshipOptions (
      thName=thName,
      topName=topName,
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

    val thName = view[StarshipOptions](annotations).thName
    val topName = view[StarshipOptions](annotations).topName
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
          RunFirrtlTransformAnnotation(Dependency[RegisterRecord])
          // RunFirrtlTransformAnnotation(Dependency[CoverageInstrument])
        )
      } else if (topName.isDefined && thName.isDefined) {
        logger.info(s"Generate TestHarness  ${thName}  ${topName}")
        Seq(
          RunFirrtlTransformAnnotation(Dependency[ExtractTestHarness]),
          BlackBoxResourceFileNameAnno(incOutFile.get),
          AddModuleSuffixAnnotation("_tb"),
          RunFirrtlTransformAnnotation(Dependency[AddModuleSuffix]),
          RunFirrtlTransformAnnotation(Dependency[RegisterRecord])
        )
      } else {
        throw new RuntimeException(s"Unexpected Input!")
      }

    pm.transform(annotations ++ starshipAnnotation)
  }
}

object RTLGenerator extends StageMain(new StarshipStage)
