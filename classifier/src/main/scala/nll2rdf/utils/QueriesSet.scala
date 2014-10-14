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
  val queries: MMap[String, (Double, Int)] = MMap()

  private def max: Double = queries.maxBy(_._2._1)._2._1

  private def maxQuery: String = queries.maxBy(_._2._1)._1

  private def checkFit(value: Double, candidates: Int): Boolean =
    if (queries.size < size) true else value < max || (value == max && candidates < queries(maxQuery)._2)

  def addValue(instanceid: String, value: Double, candidates: Int) {
    if (checkFit(value, candidates))
      queries += (instanceid -> (value, candidates))

    if(queries.size > size)
      queries -= maxQuery
  }
}
