import scala.io.Source
import scala.collection.mutable.Stack
import scala.collection.mutable.Set

object TestRead {
  // helper class to handle a target's command and all its dependencies
  class SourceTuple(var _1: String, var _2: Set[String]) {}
  def main(args: Array[String]) {
    val fi = Source.fromFile(if (args.length < 1) "testmakefile" else args(0))
    var tabs, lines = 0
    /*
     * Map: target -> (command, array of dependencies)
     * For each target we store the associated command (or "" if it doesn't
     * exist) and a list of its dependencies as Strings
     */
    var files: Map[String, SourceTuple] = Map()
    var lastTarget = ""
    for (line <- fi.getLines()) {
      if (line.indexOf(':') > 0) { // new target here
        val splitted = line.split(':')
        lastTarget = splitted(0)
        //println("Reading target "+lastTarget)
        if (files contains lastTarget)
          println("WARNING: double reference to "+lastTarget+". Ignoring...")
        else // add the entry with its dependencies (if they exist)
          files += (lastTarget -> new SourceTuple("",
            if (splitted.length > 1) Set(splitted(1).replaceAll("[ \t]", " ").split(' ').filter(_ != "") :_*) else Set()))
      }
      if (line.length > 0 && line(0) == '\t' && lastTarget != "") {
        tabs += 1
        files(lastTarget)._1 = line.replaceAll("^\t+", "") // XXX Support only one command
        println("Reading command for "+lastTarget+":"+files(lastTarget)._1)
      }
      lines += 1
    }

    //for ((key, value) <- files) {
      //println("Target "+key+" has "+value._2.size+" deps before loop");
    //}

    // now expand dependencies
    var check = new Array[String](0)
    for ((key, value) <- files) {
      if (check.indexOf(key) < 0) { // skip if already calculated
        var deps = Stack[String]() // contains every file that need to be checked
        var visited = Stack[String]() // keep trace of visited nodes
        // init stack with already known deps
        for (file <- value._2) {
          deps.push(file)
        }
        while (deps.length > 0) {
          val dep = deps.pop()
          if (visited.indexOf(dep) < 0) {
            visited.push(dep)
            value._2 += dep // store our dependency
            if (files contains dep) { // check for further dependencies
              val dep_deps = files(dep)._2
              for (dep_dep <- dep_deps) {
                if (visited.indexOf(dep_dep) < 0) { // add them if they have not been checked
                  deps.push(dep_dep)
                }
              }
            }
          }
        }
      }
    }

    for ((key, value) <- files) {
      println("Target "+key+" has "+value._2.size+" deps"+ (if (value._2.size > 0) ": "+value._2 else ""));
    }
  }
}
