package nll2rdf.utils

import weka.classifiers.functions.SimpleLogistic

/**
 * SimpleLogictic class with a method to access
 * the used attributes (needed for the work)
 */
class SimpleLogisticRegression extends SimpleLogistic {
  def getUsedAttributes: Array[Array[Int]] = m_boostedModel.getUsedAttributes
}
