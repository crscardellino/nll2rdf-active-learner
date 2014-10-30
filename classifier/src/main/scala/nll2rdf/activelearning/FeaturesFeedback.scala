/*
 * NLL2RDF Active Learner
 * Copyright (C) 2014 Cristian A. Cardellino
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

package nll2rdf.activelearning

import java.io.{File, PrintWriter}
import weka.filters.supervised.attribute.AttributeSelection

import scala.collection.JavaConversions._
import weka.attributeSelection.{InfoGainAttributeEval, Ranker}
import weka.core.Instances
import weka.core.converters.ConverterUtils.DataSource
import weka.filters.Filter
import weka.filters.unsupervised.attribute.MakeIndicator


class FeaturesFeedback(_instances: File, _rankerSize: Int = 50, _threshold: Double = 0.01) {
  val instances: Instances = DataSource.read(_instances.getCanonicalPath)
  instances.setClassIndex(instances.numAttributes - 1)
  val rankerSize: Int = _rankerSize
  val threshold: Double = _threshold

  def feedback(path: String, iteration: Int): Unit = {
    for(classobject <- instances.classAttribute.enumerateValues) {
      val classname: String = classobject.asInstanceOf[String]
      val i: Int = instances.classAttribute.indexOfValue(classname)

      val classFilter = new MakeIndicator()
      classFilter.setAttributeIndex((instances.classIndex + 1).toString)
      classFilter.setValueIndices((i + 1).toString)
      classFilter.setNumeric(false)
      classFilter.setInputFormat(instances)
      val newInstances: Instances = Filter.useFilter(instances, classFilter)

      val filter = new AttributeSelection()
      val evaluator: InfoGainAttributeEval = new InfoGainAttributeEval()
      val search: Ranker = new Ranker()

      search.setOptions(s"-T $threshold -N -1".split(' '))
      filter.setEvaluator(evaluator)
      filter.setSearch(search)
      filter.setInputFormat(newInstances)

      val filteredInstances: Instances = Filter.useFilter(newInstances, filter)

      val featureFeedback: PrintWriter = new PrintWriter(
        new File(s"$path/feedback.$classname.$iteration.txt")
      )

      for ((feature, idx) <- filteredInstances.enumerateAttributes().zipWithIndex if idx < rankerSize) {
        featureFeedback.write(s"${feature.name}\n")
      }

      featureFeedback.close()
    }
  }
}
