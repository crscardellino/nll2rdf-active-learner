package nll2rdf.classifiers


trait Classifier {
  def print_progress(current: Double, total: Double) {
    val percentage: Double = current * 100.0 / total

    val totalbars: String = "=" * percentage.toInt
    val totalempties: String = " " * (100 - percentage.toInt)

    Console.err.print(f"\r[${totalbars}$totalempties]$percentage%.2f%%")
  }
}
