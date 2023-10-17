package starship.utils.transform

import firrtl._
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

class ExtractTestHarness extends Transform with DependencyAPIMigration {

  override def prerequisites:         Seq[TransformDependency] = Forms.HighForm
  override def optionalPrerequisites: Seq[TransformDependency] = Seq.empty
  override def optionalPrerequisiteOf: Seq[TransformDependency] = {
    Forms.HighEmitters :+ Dependency[ReplSeqMem]
  }
  override def invalidates(a: Transform): Boolean = false

  def execute(state: CircuitState): CircuitState = {
    val topName = view[StarshipOptions](state.annotations).topName.map(_.split("\\.").last)
    val renames = MutableRenameMap()

    val iGraph = InstanceKeyGraph(state.circuit)
    val moduleDep = iGraph.getChildInstances.map { case (k, v) => k -> v.map(_.module) }.toMap

    def checkDepency(node: String): Set[String] = moduleDep(node).map {m => if (m != topName.get) checkDepency(m) else Set()}.foldLeft(Set(node))(_ ++ _)
    val usedModule = checkDepency(state.circuit.main) + topName.get

    state.circuit.modules.filterNot {m => usedModule.contains(m.name)}.foreach {
      unusedModule => renames.delete(ModuleTarget(state.circuit.main, unusedModule.name))
    }

    val extractModules = state.circuit.modules.filter {m => usedModule.contains(m.name)}.map {
      case m: ExtModule => m
      case m: Module =>
        if (m.name == topName.get) ExtModule(m.info, m.name, m.ports, m.name, Seq.empty) else m
    }

    val newCircuit = state.circuit.copy(modules=extractModules)
    state.copy(circuit = newCircuit, renames = Some(renames.andThen(state.renames.getOrElse(MutableRenameMap()))))
  }
}
