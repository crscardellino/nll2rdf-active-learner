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

package nll2rdf.evaluator

import java.io.{File, PrintWriter}
import java.util.Random
import nll2rdf.classifiers.NaiveBayesInfoGain
import org.apache.commons.math3.stat.descriptive.DescriptiveStatistics
import org.apache.commons.math3.stat.descriptive.moment.Mean
import scala.collection.JavaConversions._
import scala.collection.mutable.ArrayBuffer
import weka.classifiers.Evaluation
import weka.core.Instances
import weka.core.converters.ConverterUtils.DataSource


class Evaluator(val learner: NaiveBayesInfoGain, val instances: Instances) {
  instances.setClassIndex(instances.numAttributes - 1)
  val evaluation: Evaluation = new Evaluation(instances)

  def trainAndSaveModel(filepath: String): Unit = {
    learner.buildClassifier(instances)

    weka.core.SerializationHelper.write(filepath, learner)
  }

  def saveModelFeatures(path: String, iteration: Int): Unit = {
    /* This should only be called after trainAndSaveModel
       and has the precondition that the learner features
       array is non null
     */
    assert(learner.features != null)

    // Saving the whole features set
    val features: PrintWriter = new PrintWriter(
      new File(s"$path/features.$iteration.txt")
    )

    features.write(
      learner.getAllFilteredFeaturesSet.mkString("\n")
    )

    features.close()

    for (classname <- learner.classes) {
      val classfeatures: PrintWriter = new PrintWriter(
        new File(s"$path/features.$classname.$iteration.txt")
      )
      val idx: Int = learner.classes.indexOf(classname)

      classfeatures.write(
        learner.features(idx).mkString("\n")
      )

      classfeatures.close()
    }
  }

  def evaluate(path: String, iteration: Int): Unit = {
    evaluation.crossValidateModel(learner, instances, 10, new Random(0))

    val results: PrintWriter = new PrintWriter(
      new File(s"$path/evaluationresults.$iteration.txt")
    )

    results.write(s"${evaluation.toSummaryString}\n")
    results.write(s"${evaluation.toClassDetailsString}\n")
    results.write(s"${evaluation.toMatrixString}")

    results.close()

    val precisionStats: DescriptiveStatistics = new DescriptiveStatistics()
    val recallStats: DescriptiveStatistics = new DescriptiveStatistics()
    val fmeasureStats: DescriptiveStatistics = new DescriptiveStatistics()
    val weightedmean: Mean = new Mean()
    val weigths: ArrayBuffer[Double] = ArrayBuffer()

    val accuracyandkappa: PrintWriter = new PrintWriter(
      new File(s"$path/accuracyandkappa.$iteration.txt")
    )

    accuracyandkappa.write(f"${evaluation.pctCorrect}%.2f,")
    accuracyandkappa.write(f"${evaluation.kappa}%.2f\n")

    accuracyandkappa.close()

    val generalresults: PrintWriter = new PrintWriter(
      new File(s"$path/generalresults.$iteration.txt")
    )

    for (classobject <- instances.classAttribute.enumerateValues) {
      val classname: String = classobject.asInstanceOf[String]
      val classindex: Int = instances.classAttribute.indexOfValue(classname)

      precisionStats.addValue(evaluation.precision(classindex))
      recallStats.addValue(evaluation.recall(classindex))
      fmeasureStats.addValue(evaluation.fMeasure(classindex))
      weigths += instances.attributeStats(instances.classIndex()).nominalCounts(1).toDouble

      generalresults.write(
        f"${evaluation.precision(classindex)}%.2f," +
        f"${evaluation.recall(classindex)}%.2f," +
        f"${evaluation.fMeasure(classindex)}%.2f," +
        f"$classname\n"
      )
    }

    generalresults.close()

    val statresults: PrintWriter = new PrintWriter(
      new File(s"$path/statisticalresults.$iteration.txt")
    )

    /* Weighted means */
    statresults.write(f"${weightedmean.evaluate(precisionStats.getValues, weigths.toArray)}%.2f,")
    statresults.write(f"${weightedmean.evaluate(recallStats.getValues, weigths.toArray)}%.2f,")
    statresults.write(f"${weightedmean.evaluate(fmeasureStats.getValues, weigths.toArray)}%.2f,")
    statresults.write("WEIGHTED MEAN\n")

    /* Median */
    statresults.write(f"${precisionStats.getPercentile(50)}%.2f,")
    statresults.write(f"${recallStats.getPercentile(50)}%.2f,")
    statresults.write(f"${fmeasureStats.getPercentile(50)}%.2f,")
    statresults.write("MEDIAN\n")

    /* Mean */
    statresults.write(f"${precisionStats.getMean}%.2f,")
    statresults.write(f"${recallStats.getMean}%.2f,")
    statresults.write(f"${fmeasureStats.getMean}%.2f,")
    statresults.write("MEAN\n")

    /* Standard Deviation */
    statresults.write(f"${precisionStats.getStandardDeviation}%.2f,")
    statresults.write(f"${recallStats.getStandardDeviation}%.2f,")
    statresults.write(f"${fmeasureStats.getStandardDeviation}%.2f,")
    statresults.write("STANDARD DEVIATION\n")

    statresults.close()
  }
}

/* Evaluator Factory */
object Evaluator {
  def apply(filepath: String): Evaluator = {
    val instances = DataSource.read(filepath)
    instances.setClassIndex(instances.numAttributes - 1)
    new Evaluator(new NaiveBayesInfoGain(instances.numClasses), instances)
  }

  def main(args: Array[String]) {
    val arff_file: String = args(0)
    val model: String = args(1)
    val results: String = args(2)
    val iteration: Int = args(3).toInt

    val evaluator: Evaluator = Evaluator(arff_file)

    Console.err.println("Saving model")
    evaluator.trainAndSaveModel(model)

    Console.err.println("Evaluation results")
    evaluator.evaluate(results, iteration)
  }
}