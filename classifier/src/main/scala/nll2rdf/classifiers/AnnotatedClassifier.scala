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

import java.io.{File, PrintWriter, PrintStream}
import java.util.Random
import nll2rdf.utils.NullOuputStream
import org.apache.commons.math3.stat.descriptive.DescriptiveStatistics
import org.apache.commons.math3.stat.descriptive.moment.Mean
import scala.collection.JavaConversions._
import scala.collection.mutable.ArrayBuffer
import weka.attributeSelection.{BestFirst, CfsSubsetEval}
import weka.classifiers.Evaluation
import weka.classifiers.functions.LibSVM
import weka.core.Instances
import weka.core.converters.ConverterUtils.DataSource
import weka.filters.Filter
import weka.filters.supervised.attribute.AttributeSelection


case class AnnotatedClassifierOptions(arff: File = new File("."),
                                      arff_files: File = new File("."),
                                      outputdir: File = new File("."))

object AnnotatedClassifier extends Classifier {
  val nullOutput: PrintStream = new PrintStream(new NullOuputStream())

  def main(args: Array[String]) {
    val parser = new scopt.OptionParser[AnnotatedClassifierOptions]("NLL2RDF") {
      head("NLL2RDF Annotated Classifier", "2.0")
      opt[File]('t', "arff") required() action  { (t, c) => c.copy(arff = t) }
      opt[File]('a', "arff_files") required() action { (a, c) => c.copy(arff_files = a) }
      opt[File]('o', "outputdir") required() action { (o, c) => c.copy(outputdir = o) }
    }

    val config: AnnotatedClassifierOptions = parser.parse(args, AnnotatedClassifierOptions()).orNull

    if(config == null) {
      System.exit(0)
    }

    Console.err.println("Training classifier")
    val total: Double = config.arff_files.list.length.toDouble
    print_progress(0, total)

    val precisionStats: DescriptiveStatistics = new DescriptiveStatistics()
    val recallStats: DescriptiveStatistics = new DescriptiveStatistics()
    val fmeasureStats: DescriptiveStatistics = new DescriptiveStatistics()
    val weightedmean: Mean = new Mean()
    val weigths: ArrayBuffer[Double] = ArrayBuffer()

    val multiclassInstances: Instances = DataSource.read(config.arff.getCanonicalPath)
    multiclassInstances.setClassIndex(multiclassInstances.numAttributes - 1)

    val out: PrintStream = System.out
    System.setOut(nullOutput)

    val learner: LibSVM = new LibSVM()
    learner.setOptions("-K 0 -B".split(' '))
    learner.buildClassifier(multiclassInstances)

    val eval: Evaluation = new Evaluation(multiclassInstances)
    eval.crossValidateModel(learner, multiclassInstances, 10, new Random(0))

    System.setOut(out)

    val results: PrintWriter = new PrintWriter(
      new File(s"${config.outputdir.getCanonicalPath}/results/evaluationresults.txt")
    )

    results.write(s"${eval.toSummaryString}\n")
    results.write(s"${eval.toClassDetailsString}\n")
    results.write(s"${eval.toMatrixString}")

    results.close()

    weka.core.SerializationHelper.write(
      s"${config.outputdir.getCanonicalPath}/models/learner.model",
      learner
    )

    val generalresults: PrintWriter = new PrintWriter(
      new File(s"${config.outputdir.getCanonicalPath}/results/generalresults.txt")
    )

    generalresults.write("General Results\n")
    generalresults.write("===============\n")
    generalresults.write("PREC\tRECALL\tF-SCORE\tCLASS\n")

    for ((file, idx) <- config.arff_files.listFiles().sortBy(_.getName).zipWithIndex) {
      val classname: String = file.getName.split('.')(0)
      val classindex: Int = multiclassInstances.classAttribute.indexOfValue(classname)

      val instances: Instances = DataSource.read(file.getCanonicalPath)
      instances.setClassIndex(instances.numAttributes - 1)

      val selection: AttributeSelection = new AttributeSelection()
      val selectionEval: CfsSubsetEval = new CfsSubsetEval()
      val selectionSearch: BestFirst = new BestFirst()

      selectionEval.setOptions("-P 1 -E 1".split(" "))
      selectionSearch.setOptions("-D 1 -E 1".split(" "))
      selection.setEvaluator(selectionEval)
      selection.setSearch(selectionSearch)
      selection.setInputFormat(instances)

      val filteredInstances: Instances = Filter.useFilter(instances, selection)

      precisionStats.addValue(eval.precision(classindex))
      recallStats.addValue(eval.recall(classindex))
      fmeasureStats.addValue(eval.fMeasure(classindex))
      weigths += instances.attributeStats(instances.classIndex()).nominalCounts(1).toDouble

      generalresults.write(f"${eval.precision(classindex)}%.2f\t${eval.recall(classindex)}%.2f\t" +
          f"${eval.fMeasure(classindex)}%.2f\t$classname\n")

      /* We search for every selected attribute */
      val selectedFeatures: PrintWriter = new PrintWriter(
        new File(s"${config.outputdir.getCanonicalPath}/features/features.$classname.txt")
      )

      for(feature <- filteredInstances.enumerateAttributes) selectedFeatures.write(s"${feature.name}\n")

      selectedFeatures.close()

      print_progress(idx + 1, total)
    }

    generalresults.write("\nGeneral Results Statistics\n")
    generalresults.write("==========================\n")
    generalresults.write("PREC\tRECALL\tF-SCORE\tSTAT\n")

    /* Weighted means */
    generalresults.write(f"${weightedmean.evaluate(precisionStats.getValues, weigths.toArray)}%.2f\t")
    generalresults.write(f"${weightedmean.evaluate(recallStats.getValues, weigths.toArray)}%.2f\t")
    generalresults.write(f"${weightedmean.evaluate(fmeasureStats.getValues, weigths.toArray)}%.2f\t")
    generalresults.write("WEIGHTED MEAN\n")

    /* Median */
    generalresults.write(f"${precisionStats.getPercentile(50)}%.2f\t")
    generalresults.write(f"${recallStats.getPercentile(50)}%.2f\t")
    generalresults.write(f"${fmeasureStats.getPercentile(50)}%.2f\t")
    generalresults.write("MEDIAN\n")

    /* Mean */
    generalresults.write(f"${precisionStats.getMean}%.2f\t")
    generalresults.write(f"${recallStats.getMean}%.2f\t")
    generalresults.write(f"${fmeasureStats.getMean}%.2f\t")
    generalresults.write("MEAN\n")

    /* Standard Deviation */
    generalresults.write(f"${precisionStats.getStandardDeviation}%.2f\t")
    generalresults.write(f"${recallStats.getStandardDeviation}%.2f\t")
    generalresults.write(f"${fmeasureStats.getStandardDeviation}%.2f\t")
    generalresults.write("STANDARD DEVIATION\n")

    generalresults.write(f"ACCURACY: ${eval.pctCorrect}%.2f\n")
    generalresults.write(f"KAPPA: ${eval.kappa}%.2f\n")
    generalresults.close()

    Console.err.println()
  }
}
