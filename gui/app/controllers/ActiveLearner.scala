package controllers

import forms.LearnerForm
import java.io.File
import models._
import nll2rdf.evaluator.Evaluator
import org.apache.commons.io.FileUtils
import play.api.cache.Cache
import play.api.data.Form
import play.api.data.Forms._
import play.api.Logger
import play.api.Play
import play.api.Play.current
import play.api.mvc._
import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.Future
import scala.io.{BufferedSource, Source}
import scala.sys.process._
import scala.util.Try


object ActiveLearner extends Controller {
  val learnerForm = Form(
    mapping(
      "queries" -> default(number, 5),
      "tagfilter" -> default(number, 0),
      "untagfilter" -> default(number, 25),
      "typelearning" -> nonEmptyText
    )(LearnerForm.apply)(LearnerForm.unapply)
  )

  private def runProcess(command: String): Try[Unit] = Try {
    assert(command.! == 0)
  }

  private def getResults(filepath: String): Array[EvaluationResults] = {
    val file: BufferedSource = Source.fromFile(filepath)

    (for(line <- file.getLines()) yield {
      val data: Array[String] = line.split(',')

      EvaluationResults(data(3), data(0).toDouble, data(1).toDouble, data(2).toDouble)
    }).toArray
  }

  private def getAccuracyAndKappa(filepath: String): AccuracyAndKappa = {
    val data: Array[String] = Source.fromFile(filepath).getLines().next().split(',')

    AccuracyAndKappa(data(0).toDouble, data(1).toDouble)
  }

  def startTrainer = Action(parse.multipartFormData) { implicit request =>
    (for {
        taggedcorpus <- request.body.file("taggedcorpus")
        untaggedcorpus <- request.body.file("untaggedcorpus")
      } yield (taggedcorpus, untaggedcorpus)) map {
      case (taggedcorpus, untaggedcorpus) =>
        taggedcorpus.ref.moveTo(new File("/tmp/nll2rdf.tmp/taggedcorpus.tar.xz"))
        untaggedcorpus.ref.moveTo(new File("/tmp/nll2rdf.tmp/untaggedcorpus.tar.xz"))

        val data = learnerForm.bindFromRequest.get
        Cache.set("queries", data.queries)
        Cache.set("untagfilter", data.untagfilter)
        Cache.set("typelearning", data.typelearning)

        Play.current.configuration.getString("learner.basedir") map { basedir =>
          val setupcmd: String = s"perl $basedir/utils/config/setupcorpus.pl"
          val annotatedcmd: String = s"perl $basedir/utils/annotated/annotated.pl " +
              s"/tmp/nll2rdf.tmp/taggedcorpus/licenses-conll-format/ ${data.tagfilter}"

          Logger.debug("Creating annotated corpus arff file")

          runProcess(setupcmd).flatMap(_ => runProcess(annotatedcmd)) map { _ =>
            Logger.debug("Saving annotated corpus arff file")
            FileUtils.copyFile(new File("/tmp/nll2rdf.tmp/annotated.arff"), new File(s"$basedir/models/iteration0.arff"))

            Ok(views.html.results(0))
          } getOrElse {
            InternalServerError(s"There was a problem processing the corpus")
          }
        } getOrElse {
          InternalServerError("The base directory of the learner couldn't be established")
        }
    } getOrElse {
      Forbidden("You have to provide valid corpus files")
    }
  }

  def test = Action {
    Ok(views.html.results(0))
  }

  def trainAndEvaluateCorpus(iteration: Int) = Action.async { implicit request =>
    Future {
      Play.current.configuration.getString("learner.basedir") map { basedir =>
        val file: String = s"iteration$iteration"
        val filepath = s"$basedir/models/$file.arff"

        Logger.debug("Creating Model Evaluator")
        val evaluator: Evaluator = new Evaluator(filepath)

        Logger.debug("Training Model")
        evaluator.trainAndSaveModel(s"$basedir/models/$file.model")

        Logger.debug("Model Evaluation")
        evaluator.evaluate(s"$basedir/results/")

        Logger.debug("Getting Evaluation Results")
        val results: Array[EvaluationResults] = getResults(s"$basedir/results/generalresults.$iteration.txt")
        val oldResults: Array[EvaluationResults] =
          if (iteration > 0) getResults(s"$basedir/results/generalresults.${iteration-1}.txt")
          else Array()

        val statResults: Array[EvaluationResults] = getResults(s"$basedir/results/statisticalresults.$iteration.txt")
        val oldStatResults: Array[EvaluationResults] =
          if (iteration > 0) getResults(s"$basedir/results/statisticalresults.${iteration-1}.txt")
          else Array()

        val accAndKappa: AccuracyAndKappa = getAccuracyAndKappa(s"$basedir/results/accuracyandkappa.$iteration.txt")
        val oldAccAndKappa: AccuracyAndKappa =
          if (iteration > 0) getAccuracyAndKappa(s"$basedir/results/accuracyandkappa.${iteration-1}.txt")
          else null

        Ok(views.html.resultstable(results, statResults, accAndKappa, oldResults, oldStatResults, oldAccAndKappa))
      } getOrElse {
        InternalServerError("The base directory of the learner couldn't be established")
      }
    }
  }

  def queryInstances(iteration: Int) = Action.async {
    Future { Ok }
  }
}
