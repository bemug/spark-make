import scala.collection.mutable.ListBuffer
import scala.io.Source
import scala.collection.mutable.Stack
import scala.collection.mutable.Set
import scala.sys.process._
import org.apache.spark.SparkContext
import org.apache.spark.SparkContext._
import org.apache.spark.SparkConf
import java.nio.file.{Paths, Files}


object TestRead {
  /**
   * Helper class to handle a target's command and all its dependencies
   * @member name Actual target name
   * @member deps List of target dependencies
   * @member cmds List of commands that need to be executed. They are in
   * reverse order. You should pop the back of it
   */
  class SourceTuple(var name: String, var deps: Set[String], var cmds:
    List[String], var fileDeps: Set[String], var godCmd : String) extends java.io.Serializable {}
  def main(args: Array[String]) {

    val conf = new SparkConf().setAppName(if (args.length < 1) "testmakefile" else args(0))
    val sc = new SparkContext(conf)

    val master = args(1)

    val fi = Source.fromFile(if (args.length < 1) "testmakefile" else args(0))
    var tabs, lines = 0
    /*
     * Map: target -> (command, array of dependencies)
     * For each target we store the associated command (or "" if it doesn't
     * exist) and a list of its dependencies as Strings
     */
    var files: Map[String, SourceTuple] = Map()
    val baseDirPattern = "^.*/".r
    val reg = baseDirPattern findFirstIn args(0)
    val makeDir =
      if (reg == None)
        Paths.get("./").toAbsolutePath()
      else
        Paths.get(reg.get).toAbsolutePath()

    println("THE DIR IS "+makeDir)

    var lastTarget = ""
    for (line <- fi.getLines()) {
      if (line.indexOf(':') > 0) { // new target here
        val splitted = line.split(':')
        lastTarget = splitted(0).trim
        //println("Reading target "+lastTarget)
        if (files contains lastTarget)
          println("WARNING: double reference to "+lastTarget+". Ignoring...")
        else { // add the entry with its dependencies (if they exist)
          val s =
            if (splitted.length > 1)
              Set(splitted(1).replaceAll("[ \t]+", " ").split(' ') :_*)
            else
              Set[String]()
          files += (lastTarget -> new SourceTuple(lastTarget,
            s.filterNot((f: String) =>  Files.exists(Paths.get(makeDir+"/"+f)) || f == ""),
            List[String](),
            s.filter((f: String) =>  Files.exists(Paths.get(makeDir+"/"+f)) && f != ""),
            ""
            ))
        }
      }
      if (line.length > 0 && line(0) == '\t' && lastTarget != "") {
        tabs += 1
        files(lastTarget).cmds = line.replaceAll("^\t+", "") :: files(lastTarget).cmds // XXX Support only one command
      }
      // else comment or useless line
      lines += 1
    }

    def genScpCmd(file: String, toLocal: Boolean) : String = {
      if (toLocal) {
        return "scp -B " + master + ":" + makeDir + "/" + file + " ."
      } else {
        return "scp -B " + file + " " + master + ":" + makeDir
      }
    }

    def genMultiScpCmd(files: Set[String], toLocal: Boolean) : String = {
      var s = "scp -B "
      if (toLocal)
        s += master + ":\""
      else
        s += "\""
      for (f <- files) {
        if (toLocal)
          s += makeDir + "/"
        s += f +" "
      }
      s += "\" "
      if (toLocal) {
        s += "."
      } else {
        s += master + ":" + makeDir
      }
      return s
    }

    for ((key, value) <- files) {
      println("Target "+key+" has "+value.deps.size+" deps before loop");
      println(value.deps);
      println(value.fileDeps);
      val deps = value.fileDeps ++ value.deps
      value.godCmd += genMultiScpCmd(deps, true) + ";"
      for (cmd <- value.cmds.reverse) {
        value.godCmd += cmd + ";"
        println("ADDED TO THE COMMAND"+ cmd)
      }
      value.godCmd += genScpCmd(value.name, false) + ";"
      value.godCmd = value.godCmd.replace(";;", ";")
      println("THE CMD OF GODS: "+ value.godCmd)
    }

    // TODO Check for files that exists and remove them from dependencies or
    // add a special attribute to say that it is a exisiting file

    // now expand dependencies
    //var check = new Array[String](0)
    //for ((key, value) <- files) {
      //if (check.indexOf(key) < 0) { // skip if already calculated
        //var deps = Stack[String]() // contains every file that need to be checked
        //var visited = Stack[String]() // keep trace of visited nodes
        //// init stack with already known deps
        //for (file <- value.deps) {
          //deps.push(file)
        //}
        //while (deps.length > 0) {
          //val dep = deps.pop()
          //if (visited.indexOf(dep) < 0) {
            //visited.push(dep)
            //value.deps += dep // store our dependency
            //if (files contains dep) { // check for further dependencies
              //val dep_deps = files(dep).deps
              //for (dep_dep <- dep_deps) {
                //if (visited.indexOf(dep_dep) < 0) { // add them if they have not been checked
                  //deps.push(dep_dep)
                //}
              //}
            //}
          //}
        //}
      //}
    //}

    /* Put them in the right order */
    print("\nSorting..")
    var mm = collection.mutable.Map[String, SourceTuple]() ++= files //clone
    var orderedFile : ListBuffer[ListBuffer[String]] = ListBuffer()
    var inserted : Set[String] = Set()
    var previouslyInserted : Set[String] = Set()
    var nbPass = 0
    while (!files.isEmpty) {
      orderedFile += ListBuffer()
      for ((key, value) <- files) {
        /* Remove already inserted rules */
        value.deps --= previouslyInserted
        /* Adds them to orderedFile if no more dependencies required */
        if (value.deps.isEmpty) {
          orderedFile(nbPass) += key
          inserted += key
          // and removes them
          files -= key
        }
      }
      previouslyInserted = inserted.clone
      inserted.clear()
      nbPass+=1
    }
    println(" Done!")
    println("Will compile in this order:\n"+orderedFile+"\n")


    /* Compile */
    println("Compiling..")
    for (keyList <- orderedFile) {
      println("Starting a new layer.")
      val distKeyList = sc.parallelize(keyList, keyList.size)
      for (key <- distKeyList) {
        var value = mm(key)
        println("Target "+key+" has "+value.deps.size + " deps" + (if (value.deps.size > 0) ": "+value.deps else ""));
        println(value.cmds.length + " commands to execute: "+value.cmds)
        //Using full call to not mess up with pipes and others
        sys.process.stringSeqToProcess(Seq("/bin/bash", "-c", value.godCmd))!
      }
    }
  }
}
