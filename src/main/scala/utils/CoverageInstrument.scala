package starship.utils.transform


import firrtl.Mappers.CircuitMap
import firrtl._
import firrtl.annotations.{ModuleTarget, NoTargetAnnotation}
import firrtl.ir._
import firrtl.PrimOps._
import firrtl.options.Dependency
import firrtl.options.Viewer.view
import firrtl.renamemap.MutableRenameMap
import firrtl.stage.Forms
import firrtl.stage.TransformManager.TransformDependency
import starship.utils.stage.StarshipOptions

import scala.util.Random
import scala.collection.mutable.{ArrayBuffer, ListBuffer}
import scala.collection.{Map, Set, mutable}

class InstrCov(mod: DefModule, mInfo: moduleInfo, extModules: Seq[String], val maxStateSize: Int = 20, val covSumSize: Int=30) {
  private val mName = mod.name

  private val ctrlSrcs = mInfo.ctrlSrcs
  private val muxSrcs = mInfo.muxSrcs
  private val insts = mInfo.insts.filter(x => !extModules.contains(x.module))
  private val vecRegs: Set[Tuple3[Int, String, Set[String]]] = mInfo.vecRegs
  private val dirInRegs: Set[DefRegister] = mInfo.dirInRegs.filter(regWidth(_) > 3)
  // Names of all vector registers (Set[String])
  private val vecRegNames = vecRegs.flatMap(tuple => {
    val idx = tuple._1
    val prefix = tuple._2
    val bodySet = tuple._3
    (0 until idx).toList.flatMap(x => bodySet.map(x.toString + _)).map(prefix + _)
  }).toSet

  private val regStateName = mName + "_covState"
  private val covMapName = mName + "_covMap"
  private val covSumName = mName + "_covSum"

  private val ctrlRegs = ctrlSrcs("DefRegister").map(
    _.node.asInstanceOf[DefRegister]).filter(
    !dirInRegs.contains(_))
  private val largeRegs = ctrlRegs.filter(regWidth(_) >= maxStateSize)
  private val smallRegs = ctrlRegs.filter(regWidth(_) < maxStateSize)
  private val scalaRegs = smallRegs.filter(x => !vecRegNames.contains(x.name))

  // vectorRegisters can also have large width over maxStateSize => filter out
  private val vectorRegs = smallRegs.filter(x => vecRegNames.contains(x.name))

  private var ctrlSigs = Seq[Expression]()
  for (reg <- largeRegs) {
    ctrlSigs = ctrlSigs ++ muxSrcs.filter(tuple => tuple._2.contains(reg.name)).map(tuple => tuple._1.cond)
  }

  private var coveredMuxSrcs = Seq[Expression]()
  for (reg <- smallRegs) {
    coveredMuxSrcs = coveredMuxSrcs ++ muxSrcs.filter(tuple => tuple._2.contains(reg.name)).map(tuple => tuple._1.cond)
  }

  private var optRegs = Seq[DefRegister]()
  for (reg <- scalaRegs) {
    val width = regWidth(reg).toInt
    var sinkMuxes = muxSrcs.filter(tuple => tuple._2.contains(reg.name)).map(tuple => tuple._1.cond).toSet

    if (sinkMuxes.size.toInt >= width) {
      optRegs = optRegs :+ reg
    } else {
      ctrlSigs = ctrlSigs ++ sinkMuxes.toSeq
    }
  }
  ctrlSigs = ctrlSigs.toSet.toSeq
  coveredMuxSrcs = coveredMuxSrcs.toSet.toSeq

  private val unCoveredCtrlSigs = ctrlSigs.filter(m => !coveredMuxSrcs.contains(m))

  // Map of (prefix, maxIdx) -> Set(first elements of vector registers)
  private val firstVecRegs: Map[(String, Int), Set[DefRegister]] = vecRegs.map(tuple => {
    val firstRegs = tuple._3.flatMap(body => {
      vectorRegs.find(_.name == (tuple._2 + "0" + body))
    })
    ((tuple._2, tuple._1), firstRegs)
  }).toMap
  val numOptRegs = (optRegs ++ firstVecRegs.values.toSet.flatten).size

  // Want to set same field in all the vector elements to the same location
  val (totBitWidth, regStateSize, ctrlOffsets) =
    getRegState((optRegs ++ firstVecRegs.values.toSet.flatten).toSeq, unCoveredCtrlSigs)

  private val scalaOffsets = ctrlOffsets.filter(tuple => tuple._1.getClass.getSimpleName match {
    case "DefRegister" => !firstVecRegs.values.toSet.flatten.contains(tuple._1.asInstanceOf[DefRegister])
    case _ => true
  })

  // Set of (first elements of vector registers, offset) (Set[(FirrtlNode, Int)])
  private val firstVecOffsets = (ctrlOffsets.toSet -- scalaOffsets.toSet)

  // Map of (prefix, maxIdx) -> Set[(body name, offset)]
  private val vecRegsOffsets: Map[(String, Int), Set[(String, Int)]] = firstVecRegs.map(tuple => {
    val prefix = tuple._1._1
    val set = tuple._2
    val newSet = set.map(x => {
      val regOffset = firstVecOffsets.find(tup => tup._1 == x).getOrElse(
        throw new Exception("firstVecOffsets should be in firstVecRegs\n")
      )
      val name = regOffset._1.asInstanceOf[DefRegister].name
      val offset = regOffset._2
      (name.substring((prefix + "0").length, name.length), offset)
    })
    (tuple._1, newSet)
  })

  // Set of (register name, offset)
  private val vecNameOffsets = vecRegsOffsets.flatMap(tuple => {
    val idx = tuple._1._2
    val prefix = tuple._1._1
    val bodyOffsets = tuple._2
    (0 until idx).toList.flatMap(x => {
      bodyOffsets.map(tup => (x.toString + tup._1, tup._2))
    }).map(tup => (prefix + tup._1, tup._2))
  })

  // Set of (DefRegister, offset)
  private val vectorOffsets = vecNameOffsets.map(tuple => {
    val reg = vectorRegs.find(_.name == tuple._1).getOrElse(
      throw new Exception("vectorOffsets should be in vectorRegs\n")
    )
    (reg, tuple._2)
  })


  private val allOffsets = (scalaOffsets ++ vectorOffsets)

  val covMapSize = if (regStateSize == 0) 0 else Math.pow(2, regStateSize).toInt

  def printLog(): Unit = {
    // val bitOptRegs = optRegs.foldLeft(0)((b, r) => b + regWidth(r).toInt)
    // val bitVecRegs = firstVecRegs.values.toSet.flatten.foldLeft(0)((b, r) => b + regWidth(r).toInt)
    // val bitDirInRegs = dirInRegs.foldLeft(0)((b, r) => b + regWidth(r).toInt)
    // val bitCtrlSigs = ctrlSigs.length
    // val bitUncoveredCtrlSigs = unCoveredCtrlSigs.length
    // val bitLargeRegs = largeRegs.foldLeft(0)((b, r) => b + regWidth(r).toInt)
    // val bitMuxes = muxSrcs.map(_._1.cond.serialize).toSet.size

    print("=============================================\n")
    print(s"${mName}\n")
    print("---------------------------------------------\n")
    print(s"regStateSize: ${regStateSize}, totBitWidth: ${totBitWidth}, numRegs: ${ctrlRegs.size}\n")
    // print(s"[Offsets]\n" + ctrlOffsets.map(tuple => tuple._1 match {
    //   case reg: DefRegister => s"${reg.name}: ${tuple._2}"
    //   case expr => s"${expr.serialize}: ${tuple._2}"
    // }).mkString("\n") + "\n")
    print(s"numOptRegs: ${numOptRegs}\n")

    // print("vectorOffsets\n")
    // vectorOffsets.foreach(tuple => print(s"[${tuple._1.name}] -- [${tuple._2}]\n"))
    // print("\n")

    // print(s"[Widths]\n" +
    //   s"optRegs: ${bitOptRegs}, largeRegs: ${bitLargeRegs}, vecRegs: ${bitVecRegs}\n" +
    //   s"ctrlSigs: ${bitCtrlSigs}, uncoveredCtrlSigs: ${bitUncoveredCtrlSigs}\n" +
    //   s"dirInRegs: ${bitDirInRegs}\n" +
    //   s"totMuxes: ${bitMuxes}\n"
    // )
    print("=============================================\n")
  }

  def instrument(): DefModule = {

    val clockRef = (name: String) => WRef(name, ClockType, PortKind, SourceFlow)
    val initReg = (name: String, width: Int) =>
      WRef(name, UIntType(IntWidth(width)), RegKind, UnknownFlow)
    val defRegister = (name: String, info: String, clock_name: String, width: Int) =>
      DefRegister(FileInfo(StringLit(info)),
        name, UIntType(IntWidth(width)),
        clockRef(clock_name), UIntLiteral(0, IntWidth(1)), initReg(name, width))

    mod match {
      case mod: Module => {
        val stmts = mod.body.asInstanceOf[Block].stmts
        val (clockName, resetName, hasCNR) = hasClockAndReset(mod)
        val metaResetPort = Port(NoInfo, "metaReset", Input, UIntType(IntWidth(1)))
        val metaResetConnections = ListBuffer[Statement]()
        for (inst <- insts) {
          val metaResetCons = Connect(NoInfo, WSubField(WRef(inst), "metaReset"), WRef(metaResetPort))
          metaResetConnections.append(metaResetCons)
        }

        if (regStateSize != 0 && hasCNR) {

          val regState = defRegister(regStateName, s"Register tracking ${mName} state",
            clockName, regStateSize)
          val (covMap, covRef) = defMemory(covMapName, s"Coverage map for ${mName}",
            covMapSize, regStateSize)
          val covSum = defRegister(covSumName, s"Sum of coverage map", clockName, covSumSize)

          val covSumPort = Port(NoInfo, "io_covSum", Output, UIntType(IntWidth(covSumSize)))

          val readSubField = WSubField(covRef, "read")
          val writeSubField = WSubField(covRef, "write")

          val stConnections = stateConnect(regState, allOffsets, regStateSize)
          val rdConnections = readConnect(readSubField, regState, covSum, clockName, regStateSize)
          val wrConnections = writeConnect(writeSubField, regState, clockName, regStateSize)

          val ptConnections = portConnect(insts.toSeq, covSumPort, covSum)

          val ports = mod.ports :+ covSumPort :+ metaResetPort
          val newBlock = Block((stmts :+ regState :+ covMap :+ covSum)
            ++ stConnections ++ rdConnections ++ wrConnections ++ ptConnections ++ metaResetConnections)

          Module(mod.info, mName, ports, newBlock)
        } else {
          val covSum = DefWire(NoInfo, covSumName, UIntType(IntWidth(covSumSize)))
          val zeroCov = Connect(NoInfo, WRef(covSum), UIntLiteral(0, IntWidth(covSumSize)))
          val covSumPort = Port(NoInfo, "io_covSum", Output, UIntType(IntWidth(covSumSize)))
          val ptConnections = portConnect(insts.toSeq, covSumPort, covSum)

          val ports = mod.ports :+ covSumPort :+ metaResetPort
          val newBlock = Block((stmts :+ covSum :+ zeroCov) ++ ptConnections ++ metaResetConnections)
          Module(mod.info, mName, ports, newBlock)
        }
      }
      case ext: ExtModule => ext
      case other => other
    }
  }

  def readConnect(readSubField: WSubField, regState: DefRegister, covSum: DefRegister,
                  clockName: String, regStateSize: Int): Seq[Statement] = {
    val rdCons = Seq[Statement]()
    val readAddr = Connect(NoInfo,
      WSubField(readSubField, "addr", UIntType(IntWidth(regStateSize)), SinkFlow),
      WRef(regState))

    val readEn = Connect(NoInfo,
      WSubField(readSubField, "en", UIntType(IntWidth(1)), SinkFlow),
      UIntLiteral(1, IntWidth(1)))

    val readClk = Connect(NoInfo,
      WSubField(readSubField, "clk", ClockType, SinkFlow),
      WRef(clockName, ClockType, PortKind))

    val updateSum = Connect(NoInfo,
      WRef(covSum),
      Mux(
        DoPrim(Or, Seq(WSubField(readSubField, "data", UIntType(IntWidth(1))),
                       WRef("metaReset", UIntType(IntWidth(1)), PortKind)), Seq(), UIntType(IntWidth(1))),
        WRef(covSum),
        DoPrim(Add, Seq(WRef(covSum), UIntLiteral(1, IntWidth(1))), Seq(), UIntType(IntWidth(covSumSize)))
      ))

    (rdCons :+ readAddr :+ readEn :+ readClk :+ updateSum)
  }

  def writeConnect(writeSubField: WSubField, regState: DefRegister,
                   clockName: String, regStateSize: Int): Seq[Statement] = {
    val wrCons = Seq[Statement]()
    val writeAddr = Connect(NoInfo,
      WSubField(writeSubField, "addr", UIntType(IntWidth(regStateSize)), SinkFlow),
      WRef(regState))

    val writeMask = Connect(NoInfo,
      WSubField(writeSubField, "mask", UIntType(IntWidth(1)), SinkFlow),
      UIntLiteral(1, IntWidth(1)))

    val writeEn = Connect(NoInfo,
      WSubField(writeSubField, "en", UIntType(IntWidth(1)), SinkFlow),
      DoPrim(Not, Seq(WRef("metaReset", UIntType(IntWidth(1)), PortKind)), Seq(), UIntType(IntWidth(1))))

    val writeClk = Connect(NoInfo,
      WSubField(writeSubField, "clk", ClockType, SinkFlow),
      WRef(clockName, ClockType, PortKind))

    val updateCov = Connect(NoInfo,
      WSubField(writeSubField, "data", UIntType(IntWidth(1))),
      UIntLiteral(1, IntWidth(1)))

    (wrCons :+ writeAddr :+ writeMask :+ writeEn :+ writeClk :+ updateCov)
  }

  def portConnect(insts: Seq[WDefInstance], port: Port, covSum: Statement): Seq[Statement] = {
    val portCons = Seq[Statement]()
    val covSums = makeSum(insts, port, covSum)

    (portCons ++ covSums)
  }

  def makeSum(insts: Seq[WDefInstance], port: Port, sum: Statement): Seq[Statement] = {
    val sumRef = sum match {
      case defReg: DefRegister => WRef(defReg.asInstanceOf[DefRegister])
      case defWire: DefWire => WRef(defWire.asInstanceOf[DefWire])
      case _ => throw new Exception("Sum of coverages must be wire")
    }

    if (insts.isEmpty) {
      val portCon = Connect(NoInfo, WRef(port), sumRef)
      Seq[Statement](portCon)
    } else {
      val inst = insts.head
      val new_insts = insts.drop(1)

      val instPortName = "io_covSum"
      val sumWire = DefWire(NoInfo, inst.name + "_sum", UIntType(IntWidth(covSumSize)))

      val sumCon = Connect(NoInfo, WRef(sumWire),
        DoPrim(Add, Seq(sumRef, WSubField(WRef(inst), instPortName)),
          Seq(), UIntType(IntWidth(covSumSize))))

      Seq(sumWire, sumCon) ++ makeSum(new_insts, port, sumWire)
    }
  }

  def stateConnect(regState: DefRegister, ctrlOffsets: Seq[(FirrtlNode, Int)],
                   regStateSize: Int): Seq[Statement] = {
    val (padRefs, offsetStmts) = makeOffset(ctrlOffsets, regStateSize)
    val (topXor, xorStmts) = makeXor(padRefs, regStateSize, 0)

    val stConnect = Connect(NoInfo, WRef(regState), topXor)

    offsetStmts ++ xorStmts :+ stConnect
  }

  def makeOffset(ctrlOffsets: Seq[(FirrtlNode, Int)], regStateSize: Int): (Seq[WRef], Seq[Statement]) = {
    var refs = Seq[WRef]()
    var stmts = Seq[Statement]()

    var i = -1
    var tmpWires = mutable.Map[Expression, DefWire]()
    val tmpStmts = ctrlOffsets.foldLeft(Seq[Statement]())(
      (seq, tuple) => tuple._1 match {
        case reg: DefRegister => seq
        case expr => { //TODO through exception when unexpected events
          i = i + 1
          val ctrlTmp = DefWire(NoInfo, s"mux_cond_${i}", UIntType(IntWidth(1)))
          tmpWires(expr.asInstanceOf[Expression]) = ctrlTmp
          seq ++ Seq[Statement](
            ctrlTmp,
            Connect(NoInfo, WRef(ctrlTmp), expr.asInstanceOf[Expression])
          )
        }
      }
    )
    stmts = stmts ++ tmpStmts

    val tmpOffsets = ctrlOffsets.map(tuple => tuple._1 match {
      case reg: DefRegister => (reg, tuple._2)
      case expr => (tmpWires(expr.asInstanceOf[Expression]), tuple._2)
    })

    for ((ctrl, offset) <- tmpOffsets) {
      val ctrlType = ctrl match {
        case reg: DefRegister => reg.tpe
        case wire: DefWire => wire.tpe
        case _ =>
          throw new Exception(s"${ctrl} is not DefRegister/DefWire")
      }

      val ctrlWidth = ctrlType match {
        case utpe: UIntType =>
          utpe.width.asInstanceOf[IntWidth].width.toInt
        case stpe: SIntType =>
          stpe.width.asInstanceOf[IntWidth].width.toInt
        case _ =>
          throw new Exception(s"${ctrl} doesn't have UIntType/SIntType")
      }
      val pad = regStateSize - ctrlWidth - offset
      val shl_wire = DefWire(NoInfo, ctrl.name + "_shl", UIntType(IntWidth(ctrlWidth + offset)))
      val pad_wire = DefWire(NoInfo, ctrl.name + "_pad", UIntType(IntWidth(regStateSize)))

      val ref = ctrl match {
        case reg: DefRegister => WRef(reg)
        case wire: DefWire => WRef(wire)
      }
      val shl_op = DoPrim(Shl, Seq(ref), Seq(offset), UIntType(IntWidth(regStateSize)))
      val shl_connect = Connect(NoInfo, WRef(shl_wire), shl_op)

      val pad_connect = pad match {
        case 0 => Connect(NoInfo, WRef(pad_wire), WRef(shl_wire))
        case pad_size => Connect(NoInfo, WRef(pad_wire),
          DoPrim(Cat, Seq(UIntLiteral(0, IntWidth(pad_size)),
            WRef(shl_wire)), Seq(), UIntType(IntWidth(regStateSize))))
      }

      refs = refs :+ WRef(pad_wire)
      stmts = stmts ++ Seq[Statement](shl_wire, shl_connect, pad_wire, pad_connect)
    }

    (refs, stmts)
  }

  // Recursive and divide and conquer manner Xor wiring
  def makeXor(padRefs: Seq[WRef], regStateSize: Int, id: Int): (WRef, Seq[Statement]) = {
    padRefs.length match {
      case 1 => {
        (padRefs.head, Seq[Statement]())
      }
      case 2 => {
        val xor_wire = DefWire(NoInfo, mName + s"_xor${id}", UIntType(IntWidth(regStateSize)))
        val xor_op = DoPrim(Xor, Seq(padRefs.head, padRefs.last), Seq(), UIntType(IntWidth(regStateSize)))
        val xor_connect = Connect(NoInfo, WRef(xor_wire), xor_op)
        (WRef(xor_wire), Seq[Statement](xor_wire, xor_connect))
      }
      case _ => {
        val (xor1, stmts1) = makeXor(padRefs.splitAt(padRefs.length / 2)._1, regStateSize, 2 * id + 1)
        val (xor2, stmts2) = makeXor(padRefs.splitAt(padRefs.length / 2)._2, regStateSize, 2 * id + 2)
        val xor_wire = DefWire(NoInfo, mName + s"_xor${id}", UIntType(IntWidth(regStateSize)))
        val xor_op = DoPrim(Xor, Seq(xor1, xor2), Seq(), UIntType(IntWidth(regStateSize)))
        val xor_connect = Connect(NoInfo, WRef(xor_wire), xor_op)
        (WRef(xor_wire), stmts1 ++ stmts2 :+ xor_wire :+ xor_connect)
      }
    }
  }

  def defMemory(name: String, info: String, size: Int, width: Int): (DefMemory, WRef) = {
    val mem = DefMemory(FileInfo(StringLit(info)), name,
      UIntType(IntWidth(1)), size, 1, 0,
      Seq("read"), Seq("write"), Seq())
    val ref = WRef(name, BundleType(Seq(
      Field("read", Flip, BundleType(List(
        Field("addr", Default, UIntType(IntWidth(width))),
        Field("en", Default, UIntType(IntWidth(1))),
        Field("clk", Default, ClockType),
        Field("data", Flip, UIntType(IntWidth(1)))
      ))),
      Field("write", Flip, BundleType(List(
        Field("addr", Default, UIntType(IntWidth(width))),
        Field("mask", Default, UIntType(IntWidth(1))),
        Field("en", Default, UIntType(IntWidth(1))),
        Field("clk", Default, ClockType),
        Field("data", Default, UIntType(IntWidth(1)))
      )))
    )),
      MemKind, SourceFlow)

    (mem, ref)
  }

  // Get RegState width and RegOffset values
  def getRegState(regs: Seq[DefRegister], ctrls: Seq[Expression]): (Int, Int, Seq[(FirrtlNode, Int)]) = {
    val totBitWidth = regs.foldLeft[Int](0)((x, reg) => x + regWidth(reg).toInt) + ctrls.size

    val widthSeq = regs.toSeq.map(regWidth(_).toInt) ++ ctrls.map(x => 1)
    val zipWidth = (regs ++ ctrls) zip widthSeq

    totBitWidth match {
      case 0 => (totBitWidth, 0, Seq[(FirrtlNode, Int)]())
      case x if x <= maxStateSize => {
        var sum_offset = 0
        (totBitWidth, x, zipWidth.map(tuple => {
          val offset = sum_offset
          sum_offset = sum_offset + tuple._2
          (tuple._1 , offset)
        }).toSeq)
      }
      case x => {
        val rand = Random
        val offsets = zipWidth.map { case (x, i) => (x, rand.nextInt(maxStateSize - i + 1)) }
        (totBitWidth, maxStateSize, offsets)
      }
    }
  }

  def regWidth(reg: DefRegister): Int = {
    val width = reg.tpe match {
      case UIntType(iw) => iw
      case SIntType(iw) => iw
      case _ => throw new Exception("Reg not UIntType or SIntType")
    }
    width match {
      case IntWidth(len) => len.toInt
      case _ => throw new Exception("Reg type width not IntWidth")
    }
  }

  def hasClockAndReset(mod: Module): (String, String, Boolean) = {
    val ports = mod.ports
    val (clockName, resetName) = ports.foldLeft[(String, String)](("None", "None"))(
      (tuple, p) => {
        if (p.name == "clock" || p.name == "gated_clock") (p.name, tuple._2)
        else if (p.name contains "reset") (tuple._1, p.name)
        else tuple
      })
    val hasClockAndReset = (clockName != "None") // && (resetName != "None")

    (clockName, resetName, hasClockAndReset)
  }
}


object moduleInfo {
  def apply(mod: DefModule, gLedger: graphLedger): moduleInfo = {
    val ctrlSrcs = gLedger.findMuxSrcs
    val muxSrcs = gLedger.getMuxSrcs
    val insts = gLedger.getInstances
    val regs = gLedger.findRegs
    val vecRegs = gLedger.findVecRegs
    val dirInRegs = gLedger.findDirInRegs

    new moduleInfo(mod.name, ctrlSrcs, muxSrcs, insts, regs, vecRegs, dirInRegs)
  }
}

class moduleInfo(val mName: String,
                 val ctrlSrcs: Map[String, Set[Node]],
                 val muxSrcs: Map[Mux, Set[String]],
                 val insts: Set[WDefInstance],
                 val regs: Set[DefRegister],
                 val vecRegs: Set[Tuple3[Int, String, Set[String]]],
                 val dirInRegs: Set[DefRegister]) {

  var covSize: Int = 0
  var regNum: Int = 0
  var ctrlRegNum: Int = 0
  var muxNum: Int = 0
  var muxCtrlNum: Int = 0
  var regBitWidth: Int = 0
  var ctrlRegBitWidth: Int = 0
  var ctrlBitWidth: Int = 0
  var assertReg: Option[DefRegister] = None

  def printInfo(): Unit = {
    print(s"${mName} Information\n")
  }

  def saveCovResult(instrCov: InstrCov): Unit = {
    covSize = instrCov.covMapSize
    regNum = regs.size
    ctrlRegNum = ctrlSrcs("DefRegister").size
    regBitWidth = regs.toSeq.map(reg => reg.tpe match {
      case utpe: UIntType => utpe.width.asInstanceOf[IntWidth].width.toInt
      case stpe: SIntType => stpe.width.asInstanceOf[IntWidth].width.toInt
      case _ => throw new Exception(s"${reg.name} does not have IntType\n")
    }).sum

    ctrlRegBitWidth = ctrlSrcs("DefRegister").toSeq.map(reg => {
      reg.node.asInstanceOf[DefRegister].tpe match {
        case utpe: UIntType => utpe.width.asInstanceOf[IntWidth].width.toInt
        case stpe: SIntType => stpe.width.asInstanceOf[IntWidth].width.toInt
        case _ => throw new Exception(s"${reg.name} does not have IntType\n")
      }
    }).sum

    ctrlBitWidth = instrCov.totBitWidth
    muxNum = muxSrcs.size
    muxCtrlNum = muxSrcs.map(_._1.cond.serialize).toSet.size
  }
}

// graphLedger sweeps fir file, build graphs of elements
object Node {
  val types = Set("Port", "DefWire", "DefRegister", "DefNode", "DefMemory", "DefInstance", "WDefInstance")

  def apply(node: FirrtlNode): Node = {
    assert(Node.types.contains(node.getClass.getSimpleName),
      s"${node.serialize} is not an instance of Port/DefStatement\n")

    val name = node match {
      case port: Port => port.name
      case wire: DefWire => wire.name
      case reg: DefRegister => reg.name
      case nod: DefNode => nod.name
      case mem: DefMemory => mem.name
      case inst: DefInstance => inst.name
      case winst: WDefInstance => winst.name
      case _ =>
        throw new Exception(s"${node.serialize} does not have name")
    }
    new Node(node, name)
  }

  def findName(expr: Expression): String = expr match {
    case WRef(refName, _, _, _) => refName
    case WSubField(e, _, _, _) => findName(e)
    case WSubIndex(e, _, _, _) => findName(e)
    case WSubAccess(e, _, _, _) => findName(e)
    case Reference(refName, _, _, _) => refName
    case SubField(e, _, _, _) => findName(e)
    case SubIndex(e, _, _, _) => findName(e)
    case SubAccess(e, _, _, _) => findName(e)
    case _ => // Mux, DoPrim, etc
      throw new Exception(s"${expr.serialize} does not have statement")
  }

  def findNames(expr: Expression): ListBuffer[String] = expr match {
    case WRef(refName, _, _, _) => ListBuffer(refName)
    case WSubField(e, _, _, _) => findNames(e)
    case WSubIndex(e, _, _, _) => findNames(e)
    case WSubAccess(e, _, _, _) => findNames(e)
    case Reference(refName, _, _, _) => ListBuffer(refName)
    case SubField(e, _, _, _) => findNames(e)
    case SubIndex(e, _, _, _) => findNames(e)
    case SubAccess(e, _, _, _) => findNames(e)
    case Mux(_, tval, fval, _) => findNames(tval) ++ findNames(fval)
    case DoPrim(_, args, _, _) => {
      var list = ListBuffer[String]()
      for (arg <- args) {
        list = list ++ findNames(arg)
      }
      list
    }
    case _ => ListBuffer[String]()
  }

}

class Node(val node: FirrtlNode, val name: String) {

  def serialize: String = this.node.serialize

  def isUsed(expr: Expression): Boolean = expr match {
    case WRef(refName, _, _, _) => refName == name
    case WSubField(e, _, _, _) => isUsed(e)
    case WSubIndex(e, _, _, _) => isUsed(e) // Actually, it is not used in loFirrtl
    case WSubAccess(e, _, _, _) => isUsed(e) // This too
    case Reference(refName, _, _, _) => refName == name
    case SubField(e, _, _, _) => isUsed(e)
    case SubIndex(e, _, _, _) => isUsed(e)
    case SubAccess(e, _, _, _) => isUsed(e)
    case Mux(_, tval, fval, _) => (isUsed(tval) || isUsed(fval))
    case DoPrim(_, args, _, _) => {
      var used = false
      for (arg <- args) {
        used = used | isUsed(arg)
      }
      used
    }
    case _ => false
  }
}


// graphLeger
// 1) Generate graph which consists of Statements (DefRegister, DefNode, DefMemory, DefInstance,
// WDefInstance, Port)
// 2) Find all muxes and statements related to mux control signals
class graphLedger(val module: DefModule) {
  val mName = module.name
  private var defInstances = ListBuffer[FirrtlNode]()

  private val graphMap = mutable.Map[String, Tuple2[Node, Set[String]]]()
  private val reverseMap = mutable.Map[String, Tuple2[Node, Set[String]]]()
  private val Muxes = ListBuffer[Mux]()
  private val muxSrcs = mutable.Map[Mux, Set[String]]()
  private val ctrlSrcs = Map[String, ListBuffer[Node]](
    "DefRegister" -> ListBuffer[Node](), "DefMemory" -> ListBuffer[Node](),
    "DefInstance" -> ListBuffer[Node](), "WDefInstance" -> ListBuffer[Node](),
    "Port" -> ListBuffer[Node]())

  /* Variables for Optimization
  infoToVec: Identify vector registers utilizing Info annotation
  */
  private val portNames = module.ports.map(_.name).toSet
  private val infoToVec = mutable.Map[Info, Tuple3[Int, String, Set[String]]]()

  private var numRegs = 0
  private var numCtrlRegs = 0
  private var numMuxes = 0

  def printLog(): Unit = {
    print("=============================================\n")
    print(s"${mName}\n")
    print("---------------------------------------------\n")
    print(s"numRegs: ${numRegs}, numCtrlRegs: ${numCtrlRegs}, numMuxes: ${numMuxes}\n")
    print("=============================================\n")

    // print("reverseMap\n")
    // for ((n, tuple) <- reverseMap) {
    //   print(s"[$n] -- {${tuple._2.mkString(", ")}}\n")
    // }

    // print("muxes\n")
    // for ((mux, list) <- muxSrcs) {
    //   print(s"${mux.serialize} -- {${list.mkString(", ")}}\n")
    // }

    // ctrlSrcs.foreach(tuple => {
    //   val list = tuple._2.toSet
    //   print(s"${tuple._1} -- {${list.map(i => i.name).mkString(", ")}}\n")
    // })

    // print("infoToVec\n")
    // infoToVec.foreach(tuple => {
    //   print(s"${tuple._1.serialize} -- [${tuple._2._1}][${tuple._2._2}]\n" +
    //     s"{${tuple._2._3.mkString(", ")}}\n")
    // })

    // print("\n\n")

    // print("Instances: \n")
    // defInstances.foreach(x => print(s"${x.asInstanceOf[WDefInstance].name}\n"))
  }

  def parseModule: Unit = {
    this.module match {
      case ext: ExtModule =>
        print(s"$mName is external module\n")
      case mod: Module =>
        buildMap
    }
  }

  def buildMap: Unit = {
    this.module foreachPort findNode
    this.module foreachStmt findNode


    for ((n, tuple) <- graphMap) {
      if (tuple._1.node.getClass.getSimpleName == "DefRegister")
        numRegs = numRegs + 1

      var sinks = ListBuffer[String]()
      this.module foreachStmt findEdge(tuple._1, sinks)
      graphMap(n) = (tuple._1, sinks.toSet)
    }

  }

  def findNode(s: FirrtlNode): Unit = {
    if (Node.types.contains(s.getClass.getSimpleName)) {
      val n = Node(s)
      graphMap(n.name) = (n, Set[String]())
    }

    // Additionally, find instances
    if (Set("WDefInstance", "DefInstance").contains(s.getClass.getSimpleName))
      defInstances.append(s)

    s match {
      case stmt: Statement =>
        stmt foreachStmt findNode
      case other => ()
    }
  }

  def findEdge(n: Node, sinks: ListBuffer[String])(s: Statement): Unit = {
    s match {
      case reg: DefRegister =>
        if (n.isUsed(reg.reset)) {
          sinks.append(reg.name)
        }
      case node: DefNode =>
        if (n.isUsed(node.value)) {
          sinks.append(node.name)
        }
      case Connect(_, loc, expr) =>
        if (n.isUsed(expr)) {
          sinks.append(Node.findName(loc))
        }
      case _ => () // Port, DefWire, DefMemory, DefInstance, WDefInstance
    }
    s foreachStmt findEdge(n, sinks)
  }

  def findMuxSrcs: Map[String, Set[Node]] = {
    this.module foreachStmt findMuxes
    reverseEdge

    val muxCtrls = Muxes.map(mux => Node.findNames(mux.cond)).toSet
    val ctrlMuxesMap = muxCtrls.map(_.toString).zip(
      Seq.fill[ListBuffer[Mux]](muxCtrls.size)(ListBuffer[Mux]())).toMap
    for (mux <- Muxes) {
      ctrlMuxesMap(Node.findNames(mux.cond).toString).append(mux)
    }

    for (ctrls <- muxCtrls) {

      var srcs = ListBuffer[String]()
      for (ctrl <- ctrls) {
        srcs = srcs ++ findSrcs(ctrl, ListBuffer[String]())
      }

      for (mux <- ctrlMuxesMap(ctrls.toString)) {
        muxSrcs(mux) = srcs.toSet
      }
    }

    val allSrcs = muxSrcs.flatMap(tuple => tuple._2)
    for (src <- allSrcs) {
      graphMap(src)._1.node.getClass.getSimpleName match {
        case "DefRegister" => ctrlSrcs("DefRegister").append(graphMap(src)._1)
        case "DefMemory" => ctrlSrcs("DefMemory").append(graphMap(src)._1)
        case "DefInstance" => ctrlSrcs("DefInstance").append(graphMap(src)._1)
        case "WDefInstance" => ctrlSrcs("WDefInstance").append(graphMap(src)._1)
        case "Port" => ctrlSrcs("Port").append(graphMap(src)._1)
        case _ =>
          throw new Exception(s"${src} not in ctrl type")
      }
//      printf(s"${graphMap(src)._1.node.serialize}@${graphMap(src)._1.node.getClass.getSimpleName}\n")
    }

    numMuxes = muxSrcs.size
    numCtrlRegs = ctrlSrcs("DefRegister").toSet.size
    ctrlSrcs.map(tuple => (tuple._1, tuple._2.toSet))
  }

  // Find registers which get input directly from input ports
  def findDirInRegs: Set[DefRegister] = {
    if (reverseMap.size == 0)
      return Set[DefRegister]()

    val ctrlRegs = ctrlSrcs("DefRegister").
      map(_.node.asInstanceOf[DefRegister]).toSet

    val ctrlRegSrcs = ctrlRegs.map(reg =>
      (reg, reverseMap(reg.name)._2.map(src =>
        findSrcs(src, ListBuffer[String]())).flatten)
    ).map(tuple => (tuple._1, tuple._2.filter(src => src != tuple._1.name))
    )

    val firstInRegs = ctrlRegSrcs.filter(tuple => tuple._2.diff(portNames).isEmpty).map(_._1)

    ctrlRegSrcs.filter(tuple =>
      tuple._2.diff(portNames.union(firstInRegs.map(_.name))).isEmpty
    ).map(_._1)
  }

  // Find vector registers using the feature of Chisel.
  // Vertor registers in Chisel leave Source information
  def findVecRegs: Set[Tuple3[Int, String, Set[String]]] = {
    if (reverseMap.size == 0)
      return Set[Tuple3[Int, String, Set[String]]]()

    val ctrlRegs = ctrlSrcs("DefRegister").map(_.node).toSet

    val infoRegMap: Map[Info, ListBuffer[String]] = {
      ctrlRegs.foldLeft(ListBuffer[Info]())((list, reg) => {
        if (list.contains(reg.asInstanceOf[DefRegister].info)) list
        else list :+ reg.asInstanceOf[DefRegister].info
      }).map(info => (info, ListBuffer[String]())).toMap
    }

    for (reg <- ctrlRegs) {
      infoRegMap(reg.asInstanceOf[DefRegister].info).append(reg.asInstanceOf[DefRegister].name)
    }

    // DefRegisters which have same Info must be
    // 1) a definition of a vector, 2) a definition of a bundle, 3) multiple call of a definition
    val MINVECSIZE = 2
    val sortedInfoRegMap = infoRegMap.map(tuple =>
      (tuple._1, tuple._2.sorted)).filter(tuple =>
      (tuple._1.getClass.getSimpleName != "NoInfo" && tuple._2.length >= MINVECSIZE)
    )

    for((info, regs) <- sortedInfoRegMap) {
      val prefix = regs.foldLeft(regs.head.inits.toSet)((set, reg) => {
        reg.inits.toSet.intersect(set)
      }).maxBy(_.length)

      prefix.length match {
        case 0 => ()
        case n => {
          val bodies = regs.map(x => {
            x.substring(n, x.length)
          })

          // If body does not start with a number, then it is a bundle
          // print(s"Info: ${info}, prefix: ${prefix}\n")
          if (bodies.forall(body => (body.length > 0 && body(0).isDigit))) {
            val vElements = bodies.foldLeft(Map[Int, ListBuffer[String]]())((map, body) => {
              val idx = body.substring(0, if (body.contains('_')) body.indexOf('_') else body.length).toInt
              map + (idx -> (map.getOrElse(idx, ListBuffer[String]()) :+ body.substring(idx.toString.length, body.length)))
            })

            // Indices of vector elements should be continuous and starting from 0
            if ((vElements.keySet.toSeq.sorted.sliding(2).count(keys => {
              keys(0) + 1 == keys(1) }) == (vElements.keySet.size - 1)) &&
              vElements.keySet.toSeq.head == 0 &&
              vElements.forall(_._2.toSet == vElements.head._2.toSet)) {

              infoToVec(info) = (vElements.size, prefix, vElements.head._2.toSet)
            }
          }
        }
      }
    }

    infoToVec.toSet.map((tuple: (Info, Tuple3[Int, String, Set[String]])) => tuple._2)
  }

  //Find first sinks (DefRegister).
  def findSinks(src: String): ListBuffer[String] = {
    assert(graphMap.keySet.contains(src),
      s"graphMap does not contain $src")
    val tuple = graphMap(src)

    tuple._2.foldLeft(tuple._1.node match {
      case port: Port => ListBuffer[String]()
      case reg: DefRegister => ListBuffer(src)
      case wire: DefWire => ListBuffer[String]()
      case mem: DefMemory => ListBuffer[String]()
      case inst: DefInstance => ListBuffer[String]()
      case winst: WDefInstance => ListBuffer[String]() //TODO Queue registers can start from instance
      case _ => ListBuffer[String]() // DefNode (nodes must not make loop)
    }) ((list, str) => if (Set("DefWire", "DefNode", "Port").contains(tuple._1.node.getClass.getSimpleName)) {
      list ++ findSinks(str)
    } else {
      list
    })
  }

  def findMuxes(e: FirrtlNode): Unit = {
    e match {
      case stmt: Statement =>
        stmt foreachStmt findMuxes
        stmt foreachExpr findMuxes
      case expr: Expression =>
        if (expr.getClass.getSimpleName == "Mux") {
          Muxes.append(expr.asInstanceOf[Mux])
//          printf(s"${expr.serialize}@${expr.getClass.getSimpleName}\n")
        }
        expr foreachExpr findMuxes
      case _ =>
        throw new Exception("Statement should have only Statement/Expression")
    }
  }

  def findRegs: Set[DefRegister] = {
    graphMap.filter(tuple => {
      tuple._2._1.node.getClass.getSimpleName == "DefRegister"
    }).map(tuple => tuple._2._1.node.asInstanceOf[DefRegister]).toSet
  }

  def reverseEdge: Unit = {
    for ((n, tuple) <- graphMap) {
      reverseMap(n) = (tuple._1, Set[String]())
    }

    for ((n, tuple) <- reverseMap) {
      var sources = ListBuffer[String]()
      for ((m, tup) <- graphMap) {
        if (tup._2.contains(n)) {
          sources.append(m)
        }
      }
      reverseMap(n) = (tuple._1, sources.toSet)
    }
  }

  //Find first sources (Port, DefRegister, DefMemory, DefInstance, WDefInstance).
  def findSrcs(sink: String, visited: ListBuffer[String]): ListBuffer[String] = {
    assert(reverseMap.keySet.contains(sink),
      s"reverseMap does not contain $sink")

    if (visited.contains(sink))
      return ListBuffer[String]()

    visited.append(sink)
    val tuple = reverseMap(sink)

    tuple._2.foldLeft(tuple._1.node match {
      case port: Port => ListBuffer(sink)
      case reg: DefRegister => ListBuffer(sink)
      case mem: DefMemory => ListBuffer(sink)
      case inst: DefInstance => ListBuffer(sink)
      case winst: WDefInstance => ListBuffer(sink)
      case _ => ListBuffer[String]() // DefNode (nodes must not make loop), DefWire
    }) ((list, str) => if (Set("DefNode", "DefWire").contains(tuple._1.node.getClass.getSimpleName)) {
      list ++ findSrcs(str, visited)
    } else {
      list
    })
  }

  def getInstances: Set[WDefInstance] = {
    for (inst <- defInstances) {
      if (inst.getClass.getSimpleName != "WDefInstance" && inst.getClass.getSimpleName != "DefInstance")
        throw new Exception(s"${inst.serialize}@${inst.getClass.getSimpleName} is not WDefInstance/DefInstance class\n")
    }
    defInstances.map(_.asInstanceOf[WDefInstance]).toSet
  }

  def getMuxSrcs: Map[Mux, Set[String]] = {
    muxSrcs
  }
}



class CoverageInstrument extends Transform with DependencyAPIMigration {

  override def prerequisites:          Seq[TransformDependency] = Seq(Dependency[firrtl.transforms.VerilogRename])
  override def optionalPrerequisites:  Seq[TransformDependency] = Seq(Dependency[RegisterRecord])
  override def optionalPrerequisiteOf: Seq[TransformDependency] = Forms.LowEmitters ++ Seq(Dependency(firrtl.passes.VerilogPrep))
  override def invalidates(a: Transform): Boolean = false

  val moduleInfos = mutable.Map[String, moduleInfo]()
  var totNumOptRegs = 0

  def execute(state: CircuitState): CircuitState = {

    val circuit = state.circuit

    print("==================== Finding Control Registers ====================\n")
    for (m <- circuit.modules) {
      val gLedger = new graphLedger(m)

      gLedger.parseModule
      moduleInfos(m.name) = moduleInfo(m, gLedger)
      gLedger.printLog()
    }

    print("===================================================================\n")

    print("====================== Instrumenting Coverage =====================\n")

    val extModules = circuit.modules.filter(_.isInstanceOf[ExtModule]).map(_.name)
    val instrCircuit = circuit map { m: DefModule =>
      val instrCov = new InstrCov(m, moduleInfos(m.name), extModules)
      val mod = instrCov.instrument()
      totNumOptRegs = totNumOptRegs + instrCov.numOptRegs
      instrCov.printLog()

      moduleInfos(m.name).saveCovResult(instrCov)
      mod
    }

    print("===================================================================\n")


//    state
    state.copy(instrCircuit)
  }
}



