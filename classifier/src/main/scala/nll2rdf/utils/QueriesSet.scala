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

import scala.collection.mutable.{Map => MMap}

class QueriesSet(val size: Int) {
  val queries: MMap[String, Double] = MMap()
  val candidates: MMap[String, Int] = MMap()

  private def maxValue: Double = queries.values.max

  private def getMaxQuery: String = {
    val possibles: List[String] = queries.filter(_._2 == maxValue).map(_._1).toList

    candidates.filter(x => possibles.contains(x._1)).maxBy(_._2)._1
  }

  private def checkFit(value: Double, candidatesNumber: Int): Boolean = {
    if (queries.size < size)
      true
    else
      value < maxValue || (value == maxValue && candidatesNumber < candidates(getMaxQuery))
  }

  def addValue(instanceid: String, value: Double, candidatesNumber: Int) {
    if (checkFit(value, candidatesNumber)) {
      if (queries.size + 1 > size) {
        val maxQuery: String = getMaxQuery
        queries -= maxQuery
        candidates -= maxQuery
      }

      queries += instanceid -> value
      candidates += instanceid -> candidatesNumber
    }
  }
}
