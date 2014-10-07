package nll2rdf.utils

import weka.classifiers.functions.SimpleLogistic

/**
 * Created by crscardellino
 */
class SimpleLogisticRegression extends SimpleLogistic {
  def getUsedAttributes: Array[Array[Int]] = m_boostedModel.getUsedAttributes
}
