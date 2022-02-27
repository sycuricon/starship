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

case class AddModuleSuffixAnnotation(suffix: String) extends NoTargetAnnotation
class AddModuleSuffix extends Transform with DependencyAPIMigration {

  override def prerequisites:          Seq[TransformDependency] = Forms.LowForm
  override def optionalPrerequisites:  Seq[TransformDependency] = Forms.LowFormOptimized
  override def optionalPrerequisiteOf: Seq[TransformDependency] = Forms.LowEmitters
  override def invalidates(a: Transform): Boolean = false


  def execute(state: CircuitState): CircuitState = {

    val suffix = state.annotations.collectFirst {case AddModuleSuffixAnnotation(s) => s}.get
    val topName = view[StarshipOptions](state.annotations).topName
    val renameSet = Set(state.circuit.main, topName.get) ++
                    state.circuit.modules.collect{case m: ExtModule => m.name}.toSet
    val addSuffix = { (old: String) => if (renameSet(old)) old else old+suffix }

    val renames = MutableRenameMap()
    def onStmt(s: Statement): Statement = s match {
      case m: DefInstance => new DefInstance(m.info, m.name, addSuffix(m.module))
      case other => other.mapStmt(onStmt)
    }

    val reNameModules = state.circuit.modules.map(
      m => {
        renames.record(ModuleTarget(state.circuit.main, m.name), ModuleTarget(state.circuit.main, addSuffix(m.name)))
        m.mapString(addSuffix).mapStmt(onStmt)
      }
    )

    val newCircuit = state.circuit.copy(modules=reNameModules)
    state.copy(circuit = newCircuit, renames = Some(renames.andThen(state.renames.getOrElse(MutableRenameMap()))))
  }
}
