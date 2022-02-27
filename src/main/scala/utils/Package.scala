package starship.utils

import firrtl.options._
import firrtl.AnnotationSeq

package object stage {

  implicit object StarshipOptionsView extends OptionsView[StarshipOptions] {

    def view(annotations: AnnotationSeq): StarshipOptions = annotations
      .collect { case a: StarshipOption => a }
      .foldLeft(new StarshipOptions()){ (c, x) =>
        x match {
//          case TestHarnessVerilogAnnotation(a) => c.copy(thVlog = Some(a))
          case TestHarnessModuleAnnotation(a) => c.copy(thName = Some(a))
//          case TestHarnessIncludeAnnotation(a) => c.copy(thInclude = Some(a))
//          case TestHarnessMemConfigAnnotation(a) => c.copy(thMem = Some(a))
          case TopModuleAnnotation(a) => c.copy(topName = Some(a))
//          case TopIncludeAnnotation(a) => c.copy(topInclude = Some(a))
//          case TopMemConfigAnnotation(a) => c.copy(topMem = Some(a))
          case StarshipIncludeAnnotation(a) => c.copy(incOutFile = Some(a))
        }
      }
  }
}