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


trait Classifier {
  def print_progress(current: Double, total: Double) {
    val percentage: Double = current * 100.0 / total

    val totalbars: String = "=" * percentage.toInt
    val totalempties: String = " " * (100 - percentage.toInt)

    Console.err.print(f"\r[${totalbars}$totalempties]$percentage%.2f%%")
  }
}
