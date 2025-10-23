// package starship.utils.transform

// import firrtl._
// import firrtl.analyses.InstanceKeyGraph
// import firrtl.annotations._
// import firrtl.ir._
// import firrtl.options.Dependency
// import firrtl.stage.Forms
// import firrtl.stage.TransformManager.TransformDependency
// import firrtl.passes.memlib._
// import firrtl.options.Viewer._
// import firrtl.renamemap.MutableRenameMap
// import starship.utils.stage._

// //import scala.collection.mutable.Set

// class ExtractTop extends Transform with DependencyAPIMigration {

//   override def prerequisites:         Seq[TransformDependency] = Forms.HighForm
//   override def optionalPrerequisites: Seq[TransformDependency] = Seq.empty
//   override def optionalPrerequisiteOf: Seq[TransformDependency] = {
//     Forms.HighEmitters :+ Dependency[ReplSeqMem]
//   }
//   override def invalidates(a: Transform): Boolean = false

//   def execute(state: CircuitState): CircuitState = {
//     val topName = view[StarshipOptions](state.annotations).topName.map(_.split("\\.").last)
//     val renames = MutableRenameMap()
//     renames.record(CircuitTarget(state.circuit.main), CircuitTarget(topName.get))

//     val iGraph = InstanceKeyGraph(state.circuit)
//     val moduleDep = iGraph.getChildInstances.map { case (k, v) => k -> v.map(_.module) }.toMap

//     def checkDepency(node: String): Set[String] = moduleDep(node).map {m => checkDepency(m)}.foldLeft(Set(node))(_ ++ _)
//     val usedModule = checkDepency(topName.get)
//     state.circuit.modules.filterNot {m => usedModule.contains(m.name)}.foreach {
//       unusedModule => renames.record(ModuleTarget(state.circuit.main, unusedModule.name), Nil)
//     }

//     val newCircuit = Circuit(
//       info=state.circuit.info,
//       modules=state.circuit.modules.filter {m => usedModule.contains(m.name)},
//       main=topName.get)
//     state.copy(circuit = newCircuit, renames = Some(renames.andThen(state.renames.getOrElse(MutableRenameMap()))))

//   }
// }
