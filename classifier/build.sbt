name := "NLL2RDF"

version := "2.0"

scalaVersion := "2.11.2"

libraryDependencies  ++= Seq(
  "com.github.scopt" %% "scopt" % "3.2.0",
  "org.apache.commons" % "commons-math3" % "3.3"
)

resolvers += Resolver.sonatypeRepo("public")
