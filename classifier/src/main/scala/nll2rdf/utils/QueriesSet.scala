package nll2rdf.utils

import scala.collection.mutable.{Map => MMap}

class QueriesSet(val size: Int) {
  val queries: MMap[String, Double] = MMap()

  private def max: Double = queries.values.max

  def checkFit(value: Double): Boolean = if (queries.size < size) true else 0.5 < value && value < max

  def addValue(instanceid: String, value: Double) {
    if (checkFit(value))
      queries += (instanceid -> value)

    if(queries.size > size)
      queries -= queries.maxBy(_._2)._1
  }
}
