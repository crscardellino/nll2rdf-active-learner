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

import scala.collection.mutable.{Map => MMap}

class QueriesSet(val size: Int) {
  val queries: MMap[String, Double] = MMap()

  private def min: Double = queries.minBy(_._2)._2

  private def minQuery: String = queries.minBy(_._2)._1

  private def checkFit(value: Double): Boolean =
    queries.size < size || value > min

  def addValue(instanceid: String, value: Double) {
    if (checkFit(value)) {
      if (queries.size + 1 > size)
        queries -= minQuery

      queries += instanceid -> value
    }
  }
}
