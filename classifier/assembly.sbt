import AssemblyKeys._ // put this at the top of the file

assemblySettings

jarName in assembly := "nll2rdf.jar"

test in assembly := {}

mainClass in assembly := None

excludedJars in assembly <<= (fullClasspath in assembly) map { cp =>
  cp filter {_.data.getName == "weka-src.jar"}
}