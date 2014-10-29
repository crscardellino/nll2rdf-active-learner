package controllers

import forms.LearnerForm
import java.io.{PrintWriter, File}
import models._
import nll2rdf.activelearning.{QueriesSelection,FeaturesFeedback}
import nll2rdf.evaluator.Evaluator
import org.apache.commons.io.FileUtils
import play.api.Logger
import play.api.Play
import play.api.Play.current
import play.api.cache.Cache
import play.api.data.Form
import play.api.data.Forms._
import play.api.libs.json._
import play.api.mvc._
import scala.collection.mutable.{Map => MMap}
import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.Future
import scala.io.{BufferedSource, Source}
import scala.sys.process._
import scala.util.Try


object ActiveLearner extends Controller {
  val classes = Map(
    "NO-CLASS" -> "No class",
    "PER-COMMERCIALIZE" -> "Permission to commercialize",
    "PER-DERIVE" -> "Permission to derive",
    "PER-DISTRIBUTE" -> "Permission to distribute",
    "PER-READ" -> "Permission to read",
    "PER-REPRODUCE" -> "Permission to reproduce",
    "PER-SELL" -> "Permission to sell",
    "PRO-COMMERCIALIZE" -> "Prohibition to commercialize",
    "PRO-DERIVE" -> "Prohibition to derive",
    "PRO-DISTRIBUTE" -> "Prohibition to distribute",
    "REQ-ATTACHPOLICY" -> "Requirement to attach policy",
    "REQ-ATTACHSOURCE" -> "Requirement to attach source",
    "REQ-ATTRIBUTE" -> "Requirement to attribute",
    "REQ-SHAREALIKE" -> "Requirement to share alike"
  )
  val learnerForm = Form(
    mapping(
      "queries" -> default(number, 5),
      "tagfilter" -> default(number, 0),
      "untagfilter" -> default(number, 25),
      "typelearning" -> nonEmptyText
    )(LearnerForm.apply)(LearnerForm.unapply)
  )

  val queriesForm = Form(
    "queries" -> list(text)
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

  def annotate(iteration: Int) = Action.async(BodyParsers.parse.json) { request =>
    Future {
      val json: JsValue = request.body
      val settings: JsValue = Json.parse(Source.fromFile("/tmp/nll2rdf.tmp/settings.json").getLines().next)
      val queries: Set[String] = Cache.get("queries").map(_.asInstanceOf[Set[String]]).getOrElse(sys.error("Queries not set"))

      for(query <- queries) {
        val file: File = new File(s"/tmp/nll2rdf.tmp/instances/iteration$iteration/$query.txt")

        for(classname <- (json \ query).as[List[String]]) {
          val newfile: File = new File(s"/tmp/nll2rdf.tmp/instances/iteration$iteration/tagged/$query.$classname.txt")
          FileUtils.copyFile(file, newfile)
        }
      }

      Play.current.configuration.getString("learner.basedir") map { basedir =>
        val filter: Int = (settings \ "tagfilter").as[Int]
        val filteringcmd: String = s"perl $basedir/utils/activelearning/filtering.pl $iteration"
        val oraclecmd: String = s"perl $basedir/utils/activelearning/oracle.pl $iteration mixed $filter"

        runProcess(filteringcmd).flatMap(_ => runProcess(oraclecmd)) map { _ =>
          val featuresFeedback: FeaturesFeedback = new FeaturesFeedback(new File(s"/tmp/nll2rdf.tmp/mixed.arff"))

          featuresFeedback.feedback("/tmp/nll2rdf.tmp/features", iteration)

          Ok("OK")
        } getOrElse {
          InternalServerError("Error processing the annotated examples")
        }
      } getOrElse {
        InternalServerError("The base directory of the learner couldn't be established")
      }
    }
  }

  def makeQueries(iteration: Int) = Action {
    Ok(views.html.query(iteration))
  }

  def queryInstances(iteration: Int) = Action.async {
    Future {
      Play.current.configuration.getString("learner.basedir") map { basedir =>
        val settings: JsValue = Json.parse(Source.fromFile("/tmp/nll2rdf.tmp/settings.json").getLines().next)
        val file: String = s"iteration$iteration"
        val arff: File = new File(s"$basedir/models/$file.arff")
        val model: File = new File(s"$basedir/models/$file.model")
        val filter: Int = (settings \ "untagfilter").as[Int]
        val queries_size: Int = (settings \ "queries_size").as[Int]

        val cmd: String = s"perl $basedir/utils/unannotated/unannotated.pl " +
            s"/tmp/nll2rdf.tmp/untaggedcorpus/conll-corpus ${arff.getCanonicalPath} " +
            s"$iteration $filter"

        runProcess(cmd) map { _ =>
          val csv_file: File = new File(s"/tmp/nll2rdf.tmp/unannotated.csv")

          val queriesSelection = new QueriesSelection(csv_file, arff, model, queries_size)

          queriesSelection.query()

          val queries: MMap[String, String] = MMap()

          Cache.set("queries", queriesSelection.queries.queries.keySet)

          for (query <- queriesSelection.queries.queries.keys) {
            val filename: String = s"/tmp/nll2rdf.tmp/instances/$file/$query.txt"
            val query_value: String = Source.fromFile(filename).getLines.next()

            queries += (query -> query_value)
          }

          Ok(views.html.queryselection(queries.toMap, classes))
        } getOrElse {
          InternalServerError("There was a problem getting the unannotated corpus")
        }
      } getOrElse {
        InternalServerError("The base directory of the learner couldn't be established")
      }
    }
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
        val settingsJson: JsValue = Json.obj(
          "queries_size" -> data.queries,
          "tagfilter" -> data.tagfilter,
          "typelearning" -> data.typelearning,
          "untagfilter" -> data.untagfilter
        )
        val settings: PrintWriter = new PrintWriter(
          new File("/tmp/nll2rdf.tmp/settings.json")
        )
        settings.write(Json.stringify(settingsJson))
        settings.close()

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
    Ok(views.html.query(0))
  }

  def trainAndEvaluateCorpus(iteration: Int) = Action.async { implicit request =>
    Future {
      Play.current.configuration.getString("learner.basedir") map { basedir =>
        val file: String = s"iteration$iteration"
        val filepath = s"$basedir/models/$file.arff"

        Logger.debug("Creating model evaluator")
        val evaluator: Evaluator = Evaluator(filepath)

        Logger.debug("Training model")
        evaluator.trainAndSaveModel(s"$basedir/models/$file.model")

        Logger.debug("Saving model features")
        evaluator.saveModelFeatures(s"/tmp/nll2rdf.tmp/features/", 0)

        Logger.debug("Model evaluation")
        evaluator.evaluate(s"$basedir/results/")

        Logger.debug("Getting evaluation results")
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
}
