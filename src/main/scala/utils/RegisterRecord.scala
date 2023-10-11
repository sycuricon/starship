package starship.utils.transform

import firrtl.{TargetDirAnnotation, _}
import firrtl.analyses.InstanceKeyGraph
import firrtl.annotations._
import firrtl.ir._
import firrtl.options.Dependency
import firrtl.stage.Forms
import firrtl.stage.TransformManager.TransformDependency
import firrtl.passes.memlib._
import firrtl.options.Viewer._
import firrtl.renamemap.MutableRenameMap
import starship.utils.stage._
import firrtl.passes._
import java.io.File
import scala.collection.mutable.LinkedHashMap

class RegisterRecord extends Transform with DependencyAPIMigration {

  override def prerequisites:          Seq[TransformDependency] = Seq(Dependency[firrtl.transforms.VerilogRename])
  override def optionalPrerequisites:  Seq[TransformDependency] = Seq.empty
  override def optionalPrerequisiteOf: Seq[TransformDependency] = Forms.LowEmitters ++ Seq(Dependency(firrtl.passes.VerilogPrep))
  override def invalidates(a: Transform): Boolean = false


  def execute(state: CircuitState): CircuitState = {
    val output_dir = state.annotations.collectFirst {case TargetDirAnnotation(d) => d}.get
    if (!new File(output_dir).exists()) {
      FileUtils.makeDirectory(output_dir)
    }

    val outputcircuitFile = new java.io.PrintWriter(output_dir + "/" + state.circuit.main + ".fir")
    outputcircuitFile.write(state.circuit.serialize)
    outputcircuitFile.close()

    val iGraph = InstanceKeyGraph(state.circuit)
    val pathMap = new LinkedHashMap[String, Seq[String]]
    iGraph.fullHierarchy.foreach {
      case (instKey, pathSeq) =>
        pathSeq.foreach(path =>
          pathMap.update(instKey.module, pathMap.getOrElse(instKey.module, Seq.empty) :+ path.map(_.name).mkString("."))
        )
    }
    def isNum = (c: Char) => c <= '9' && c >= '0'
    val regMap = new LinkedHashMap[String, Seq[(String,String)]]
    def scanStatement(module: String)(s: Statement): Unit = s match {
      case reg: DefRegister =>
        regMap.update(module, regMap.getOrElse(module, Seq.empty) :+ (reg.name, reg.tpe.toString.filter(_.isDigit)))
      case mem: DefMemory =>
        regMap.update(module, regMap.getOrElse(module, Seq.empty) :+ (mem.name, mem.dataType.toString.filter(_.isDigit) + "," + mem.depth.toString))
      case other => other.foreachStmt(scanStatement(module))
    }
    state.circuit.modules.foreach(m =>
      m.foreachStmt(scanStatement(m.name))
    )

    var total_size = BigInt(0)
    val regList = regMap.flatMap(regKey =>
      regKey._2.flatMap(regPair =>
        pathMap(regKey._1).map(path => {
          val regORmem = regPair._2.split(",").map(BigInt(_))
          total_size += regORmem.foldLeft(BigInt(1)){_ * _}

          val width = regORmem(0) - 1
          val depth = regORmem.applyOrElse(1, Seq.fill(2)(BigInt(0))) - 1
          val suffix_depth = if (depth == -1) "0:-1" else s"0:${depth.toString}"
          val suffix_width = s"${width.toString}:0"
          path + "." + regPair._1 + "@" + suffix_depth + "@" + suffix_width
        }))).toSeq.mkString("\n")

    val outputListFile = new java.io.PrintWriter(output_dir + "/" + state.circuit.main + ".reglist")
    outputListFile.write(s"; // Total length is ${total_size}\n")
    outputListFile.write(regList)
    outputListFile.close()

    state
  }
}
