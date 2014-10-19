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

package nll2rdf.utils

import weka.classifiers.AbstractClassifier
import weka.classifiers.bayes.NaiveBayesMultinomial
import weka.core.{Instance, Instances}
import weka.attributeSelection.{InfoGainAttributeEval, Ranker}
import weka.filters.Filter
import weka.filters.supervised.attribute.AttributeSelection
import weka.filters.unsupervised.attribute.MakeIndicator


class NaiveBayesInfoGain extends AbstractClassifier {
  var classifiers: Array[NaiveBayesMultinomial] = null
  var filters: Array[AttributeSelection] = null

  def buildClassifier(instances: Instances) {
    classifiers = new Array(instances.numClasses)
    filters = new Array(instances.numClasses)
    val classFilters: Array[MakeIndicator] = new Array(instances.numClasses)

    /* Create the filters for binary data */
    for(i: Int <- 0 until instances.numClasses) {
      classFilters(i) = new MakeIndicator()
      classFilters(i).setAttributeIndex((instances.classIndex + 1).toString)
      classFilters(i).setValueIndices((i + 1).toString)
      classFilters(i).setNumeric(false)
      classFilters(i).setInputFormat(instances)
      val newInstances: Instances = Filter.useFilter(instances, classFilters(i))

      filters(i) = new AttributeSelection()
      val evaluator: InfoGainAttributeEval = new InfoGainAttributeEval()
      val search: Ranker = new Ranker()

      search.setOptions("-T 0.001 -N -1".split(' '))
      filters(i).setEvaluator(evaluator)
      filters(i).setSearch(search)
      filters(i).setInputFormat(newInstances)

      classifiers(i) = new NaiveBayesMultinomial()

      classifiers(i).buildClassifier(Filter.useFilter(newInstances, filters(i)))
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
}
