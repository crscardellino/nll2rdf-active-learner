package nll2rdf.classifiers

import java.io.{File, PrintWriter}
import java.util.Random

import nll2rdf.utils.SimpleLogisticRegression
import weka.classifiers.Evaluation
import weka.core.Instances
import weka.core.converters.ConverterUtils.DataSource

case class Config(arff_files: File = new File("."), outputdir: File = new File("."))

object AnnotatedClassifier {
  def main(args: Array[String]) {
    val parser = new scopt.OptionParser[Config]("NLL2RDF") {
      head("NLL2RDF", "2.0")
      opt[File]('a', "arff_files") required() action { (t, c) => c.copy(arff_files = t) }
      opt[File]('o', "outputdir") required() action { (o, c) => c.copy(outputdir = o) }
    }

    val config: Config = parser.parse(args, Config()).orNull

    if(config == null) {
      System.exit(0)
    }

    for (file <- config.arff_files.listFiles()) {
      val classname: String = file.getName.split('.')(0).toLowerCase
      Console.err.println(s"Loading data to train classifier for class ${classname.toUpperCase}")
      val datafile: Instances = DataSource.read(file.getCanonicalPath)
      datafile.setClassIndex(datafile.numAttributes - 1)

      Console.err.println("Training classifier")
      val learner: SimpleLogisticRegression = new SimpleLogisticRegression()
      learner.buildClassifier(datafile)

      Console.err.println("10-fold cross-validation evaluation of classifier")
      val eval: Evaluation = new Evaluation(datafile)
      eval.crossValidateModel(learner, datafile, 10, new Random(1))

      Console.err.println("Storing results")

      val results: PrintWriter = new PrintWriter(
        new File(s"${config.outputdir.getCanonicalPath}/results/evaluation.$classname.txt")
      )

      results.write(s"Model:\n${learner.toString}\n")
      results.write(s"Results summary:${eval.toSummaryString}\n")
      results.write(s"Detailed results:\n ${eval.toClassDetailsString}\n")
      results.write(s"Confussion matrix:\n${eval.toMatrixString}")

      results.close()

      val dataresults: PrintWriter = new PrintWriter(
        new File(s"${config.outputdir.getCanonicalPath}/results/data.$classname.txt")
      )

      dataresults.write(f"${eval.numInstances}%.0f ${eval.correct}%.0f ${eval.pctCorrect}%.2f " +
        f"${eval.precision(1)}%.2f ${eval.recall(1)}%.2f ${eval.fMeasure(1)}%.2f\n")

      dataresults.close()

      weka.core.SerializationHelper.write(
        s"${config.outputdir.getCanonicalPath}/models/$classname.model",
        learner
      )

      Console.err.println()
   }
  }
}
