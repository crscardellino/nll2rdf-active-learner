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

import java.io.{File, PrintWriter}
import java.util.Random

import nll2rdf.utils.SimpleLogisticRegression
import weka.classifiers.Evaluation
import weka.core.Instances
import weka.core.converters.ConverterUtils.DataSource

case class AnnotatedClassifierOptions(arff_files: File = new File("."), outputdir: File = new File("."))

object AnnotatedClassifier extends Classifier {
  def main(args: Array[String]) {
    val parser = new scopt.OptionParser[AnnotatedClassifierOptions]("NLL2RDF") {
      head("NLL2RDF Annotated Classifier", "2.0")
      opt[File]('a', "arff_files") required() action { (a, c) => c.copy(arff_files = a) }
      opt[File]('o', "outputdir") required() action { (o, c) => c.copy(outputdir = o) }
    }

    val config: AnnotatedClassifierOptions = parser.parse(args, AnnotatedClassifierOptions()).orNull

    if(config == null) {
      System.exit(0)
    }

    Console.err.println("Training classifiers")
    val total: Double = config.arff_files.list.length.toDouble
    print_progress(0, total)

    for ((file, idx) <- config.arff_files.listFiles().zipWithIndex) {
      val classname: String = file.getName.split('.')(0).toLowerCase

      val datafile: Instances = DataSource.read(file.getCanonicalPath)
      datafile.setClassIndex(datafile.numAttributes - 1)

      val learner: SimpleLogisticRegression = new SimpleLogisticRegression()
      learner.buildClassifier(datafile)

      val eval: Evaluation = new Evaluation(datafile)
      eval.crossValidateModel(learner, datafile, 10, new Random(1))

      val results: PrintWriter = new PrintWriter(
        new File(s"${config.outputdir.getCanonicalPath}/results/evaluation.$classname.txt")
      )

      results.write(s"Model:\n${learner.toString}\n")
      results.write(s"Results summary:\n${eval.toSummaryString}\n")
      results.write(s"Detailed results:\n ${eval.toClassDetailsString}\n")
      results.write(s"Confussion matrix:\n${eval.toMatrixString}")

      results.close()

      val dataresults: PrintWriter = new PrintWriter(
        new File(s"${config.outputdir.getCanonicalPath}/results/data.$classname.txt")
      )

      val weight: Int = datafile.attributeStats(datafile.classIndex()).nominalCounts(1)

      dataresults.write(f"${eval.kappa}%.2f ${eval.precision(1)}%.2f " +
        f"${eval.recall(1)}%.2f ${eval.fMeasure(1)}%.2f $weight\n")

      dataresults.close()

      weka.core.SerializationHelper.write(
        s"${config.outputdir.getCanonicalPath}/models/$classname.model",
        learner
      )

      /* We search for every selected attribute */

      val attrdata: PrintWriter = new PrintWriter(
        new File(s"${config.outputdir.getCanonicalPath}/features/features.$classname.txt")
      )

      for(attr <- learner.getUsedAttributes(1)) attrdata.write(s"${datafile.attribute(attr).name}\n")

      attrdata.close()

      print_progress(idx + 1, total)
    }

    Console.err.println()
  }
}
