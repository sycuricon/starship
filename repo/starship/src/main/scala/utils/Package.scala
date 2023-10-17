package starship.utils

import firrtl.options._
import firrtl.AnnotationSeq

package object stage {

  implicit object StarshipOptionsView extends OptionsView[StarshipOptions] {

    def view(annotations: AnnotationSeq): StarshipOptions = annotations
      .collect { case a: StarshipOption => a }
      .foldLeft(new StarshipOptions()){ (c, x) =>
        x match {
          case TestHarnessModuleAnnotation(a) => c.copy(thName = Some(a))
          case TopModuleAnnotation(a) => c.copy(topName = Some(a))
          case StarshipIncludeAnnotation(a) => c.copy(incOutFile = Some(a))
        }
      }
  }
}