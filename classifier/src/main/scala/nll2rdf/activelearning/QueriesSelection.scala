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

import nll2rdf.classifiers.NaiveBayesInfoGain
import weka.core.{DenseInstance, Instances}
import weka.core.converters.ConverterUtils.DataSource
import scala.io.Source

class QueriesSelection(val csv_file: File, arff: File, model: File, queries_size: Int = 5) {
  val dataset: Instances = DataSource.read(arff.getCanonicalPath)
  dataset.setClassIndex(dataset.numAttributes - 1)

  val learner: NaiveBayesInfoGain = weka.core.SerializationHelper.read(
    model.getCanonicalPath
  ).asInstanceOf[NaiveBayesInfoGain]

  val queries: QueriesSet = new QueriesSet(queries_size)

  val instances_count: Double = Source.fromFile(csv_file).getLines.size

  private def print_progress(total: Double, current: Double): Unit = {
    val percentage: Double = current * 100.0 / total

    val totalbars: String = "=" * percentage.toInt
    val totalempties: String = " " * (100 - percentage.toInt)

    Console.err.print(f"\r[${totalbars}$totalempties]$percentage%.0f%%")
  }

  def query(): Unit = {
    Console.err.println("Active learning querying on unlabeled corpus pool")

    print_progress(instances_count, 0)
    var current: Double = 1

    for(line <- Source.fromFile(csv_file).getLines) {
      val instance_data: Array[String] = line.split(",", 2)

      val instance: DenseInstance = new DenseInstance(dataset.numAttributes)
      instance.setDataset(dataset)

      for ((v, i) <- instance_data(1).split(",").zipWithIndex) {
        instance.setValue(i, v.toDouble)
      }

      queries.addValue(instance_data(0).replaceAll("'", ""), learner.distributionForInstance(instance).max)
      print_progress(instances_count, current)
      current += 1
    }

    Console.err.println()
  }
}
