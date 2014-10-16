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

import java.io.{PrintWriter, File}
import nll2rdf.utils.QueriesSet
import scala.collection.JavaConversions._
import scala.io.Source
import weka.classifiers.functions.LibSVM
import weka.core.{DenseInstance, Instances, Instance}
import weka.core.converters.ConverterUtils.DataSource
import weka.filters.supervised.attribute.AttributeSelection

case class UnannotatedClassifierOptions(csv_file: File = new File("."), models_dir: File = new File("."),
                                        outputdir: File = new File("."), old_arff: File = new File("."),
                                        instance_count: Double = 0.0, queries_size: Int = 5)

object UnannotatedClassifier extends Classifier {
  def main(args: Array[String]) {
    val parser = new scopt.OptionParser[UnannotatedClassifierOptions]("NLL2RDF") {
      head("NLL2RDF Unannotated Classifier", "2.0")
      opt[File]('c', "csv-file") required() action { (a, c) => c.copy(csv_file = a) }
      opt[File]('m', "modelsdir") required() action { (m, c) => c.copy(models_dir = m) }
      opt[File]('o', "outputdir") required() action { (o, c) => c.copy(outputdir = o) }
      opt[File]('a', "old-arff") required() action { (f, c) => c.copy(old_arff = f) }
      opt[Double]('i', "instance-count") action { (i, c) => c.copy(instance_count = i)}
      opt[Int]('q', "queries-size") action { (q, c) => c.copy(queries_size = q)}
    }

    val config: UnannotatedClassifierOptions = parser.parse(args, UnannotatedClassifierOptions()).orNull

    if(config == null) {
      System.exit(0)
    }

    Console.err.println("Active learning querying on unlabeled corpus pool")

    val dataset: Instances = DataSource.read(config.old_arff.getCanonicalPath)
    dataset.setClassIndex(dataset.numAttributes - 1)

    val models: Map[String, LibSVM] =
      (for (file <- config.models_dir.listFiles if file.getName.endsWith(".model")) yield {
        (file.getName.split('.')(0), weka.core.SerializationHelper.read(file.getAbsolutePath).asInstanceOf[LibSVM])
      }).toMap

    val filters: Map[String, AttributeSelection] =
      (for (file <- config.models_dir.listFiles if file.getName.endsWith(".filter")) yield {
        (file.getName.split('.')(0), weka.core.SerializationHelper.read(file.getAbsolutePath).asInstanceOf[AttributeSelection])
      }).toMap

    val queries: QueriesSet = new QueriesSet(config.queries_size)

    print_progress(0, config.instance_count)
    var current: Double = 1.0

    for(line <- Source.fromFile(config.csv_file).getLines) {
      print_progress(current, config.instance_count)
      current += 1
      val instance_data: Array[String] = line.split(",", 2)

      val instance: DenseInstance = new DenseInstance(dataset.numAttributes)
      instance.setDataset(dataset)

      for((v, i) <- instance_data(1).split(",").zipWithIndex) instance.setValue(i, v.toDouble)

      val classification: Array[Double] = (for((model, learner) <- models) yield {
//        filters(model).input(instance)
//        val filteredInstance: Instance = filters(model).output

        Math.abs(learner.distributionForInstance(instance)(1) - 0.5)
      }).toArray
//      val uncertainty: Double = classification.sum / classification.length
      val min: Double = classification.min

      queries.addValue(instance_data(0), min)
    }

    Console.err.println()

    val attrdata: PrintWriter = new PrintWriter(
      new File(s"${config.outputdir.getCanonicalPath}/data/queries.txt")
    )

    for((instanceid, value) <- queries.queries)
      attrdata.write(f"$instanceid,$value%.2f\n")

    attrdata.close()
  }
}
