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

package nll2rdf.classifiers

import scala.collection.JavaConversions._
import weka.attributeSelection.{InfoGainAttributeEval, Ranker}
import weka.classifiers.AbstractClassifier
import weka.classifiers.bayes.NaiveBayesMultinomial
import weka.core.{Instance, Instances}
import weka.filters.Filter
import weka.filters.supervised.attribute.AttributeSelection
import weka.filters.unsupervised.attribute.MakeIndicator


class NaiveBayesInfoGain(numClasses: Int, _rankerSize: Int = 100) extends AbstractClassifier {
  val classes: Array[String] = new Array(numClasses)
  val classifiers: Array[NaiveBayesMultinomial] = new Array(numClasses)
  val filters: Array[AttributeSelection] = new Array(numClasses)
  val features: Array[Array[String]] = new Array(numClasses)
  val rankerSize: Int = _rankerSize

  def buildClassifier(instances: Instances) {
    val classFilters: Array[MakeIndicator] = new Array(instances.numClasses)

    /* Create the filters for binary data */
    for(classobject <- instances.classAttribute.enumerateValues) {
      val i: Int = instances.classAttribute.indexOfValue(classobject.asInstanceOf[String])
      classes(i) = classobject.asInstanceOf[String]

      classFilters(i) = new MakeIndicator()
      classFilters(i).setAttributeIndex((instances.classIndex + 1).toString)
      classFilters(i).setValueIndices((i + 1).toString)
      classFilters(i).setNumeric(false)
      classFilters(i).setInputFormat(instances)
      val newInstances: Instances = Filter.useFilter(instances, classFilters(i))

      filters(i) = new AttributeSelection()
      val evaluator: InfoGainAttributeEval = new InfoGainAttributeEval()
      val search: Ranker = new Ranker()

      search.setOptions(s"-T 0.001 -N -1".split(' '))
      filters(i).setEvaluator(evaluator)
      filters(i).setSearch(search)
      filters(i).setInputFormat(newInstances)

      classifiers(i) = new NaiveBayesMultinomial()

      val filtered: Instances = Filter.useFilter(newInstances, filters(i))

      classifiers(i).buildClassifier(filtered)

      features(i) =
          (for ((feature, idx) <- filtered.enumerateAttributes().zipWithIndex if idx < rankerSize)
          yield feature.name()).toArray
    }
  }

  override def distributionForInstance(instance: Instance): Array[Double] = {
    for ((classifier, idx) <- classifiers.zipWithIndex) yield {
      filters(idx).input(instance)
      val filteredInstance: Instance = filters(idx).output()
      classifier.distributionForInstance(filteredInstance)(1)
    }
  }

  override def classifyInstance(instance: Instance): Double = {
    distributionForInstance(instance).zipWithIndex.maxBy(_._1)._2
  }

  def getAllFilteredFeaturesSet: Set[String] =
    (for (featSet <- features) yield {
      for(feature <- featSet) yield feature
    }).flatMap(x => x).toSet
}
