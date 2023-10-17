//******************************************************************************
// Copyright (c) 2019 - 2019, The Regents of the University of California (Regents).
// All Rights Reserved. See LICENSE and LICENSE.SiFive for license details.
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
// CVA6 Tile Wrapper
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

package starship.cva6

import sys.process._

import chisel3._
import chisel3.util._
import chisel3.experimental.{IntParam, StringParam}

import scala.collection.mutable.{ListBuffer}

import org.chipsalliance.cde.config._
import freechips.rocketchip.subsystem._
import freechips.rocketchip.devices.tilelink._
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.rocket._
import freechips.rocketchip.subsystem.{RocketCrossingParams}
import freechips.rocketchip.tilelink._
import freechips.rocketchip.interrupts._
import freechips.rocketchip.util._
import freechips.rocketchip.tile._
import freechips.rocketchip.amba.axi4._

class CVA6CoreBlackbox(
  traceportEnabled: Boolean,
  traceportSz: Int,
  xLen: Int,
  rasEntries: Int,
  btbEntries: Int,
  bhtEntries: Int,
  execRegAvail: Int = 5,
  exeRegCnt: Int,
  exeRegBase: Seq[BigInt],
  exeRegSz: Seq[BigInt],
  cacheRegAvail: Int = 5,
  cacheRegCnt: Int,
  cacheRegBase: Seq[BigInt],
  cacheRegSz: Seq[BigInt],
  debugBase: BigInt,
  axiAddrWidth: Int,
  axiDataWidth: Int,
  axiUserWidth: Int,
  axiIdWidth: Int,
  pmpEntries: Int)
  extends BlackBox(
    Map(
      "TRACEPORT_SZ" -> IntParam(traceportSz),
      "XLEN" -> IntParam(xLen),
      "RAS_ENTRIES" -> IntParam(rasEntries),
      "BTB_ENTRIES" -> IntParam(btbEntries),
      "BHT_ENTRIES" -> IntParam(bhtEntries),
      "EXEC_REG_CNT" -> IntParam(exeRegCnt),
      "CACHE_REG_CNT" -> IntParam(cacheRegCnt),
      "DEBUG_BASE" -> IntParam(debugBase),
      "AXI_ADDRESS_WIDTH" -> IntParam(axiAddrWidth),
      "AXI_DATA_WIDTH" -> IntParam(axiDataWidth),
      "AXI_USER_WIDTH" -> IntParam(axiUserWidth),
      "AXI_ID_WIDTH" -> IntParam(axiIdWidth),
      "PMP_ENTRIES" -> IntParam(pmpEntries)) ++
    (0 until execRegAvail).map(i => s"EXEC_REG_BASE_$i" -> IntParam(exeRegBase(i))).toMap ++
    (0 until execRegAvail).map(i => s"EXEC_REG_SZ_$i" -> IntParam(exeRegSz(i))).toMap ++
    (0 until cacheRegAvail).map(i => s"CACHE_REG_BASE_$i" -> IntParam(cacheRegBase(i))).toMap ++
    (0 until cacheRegAvail).map(i => s"CACHE_REG_SZ_$i" -> IntParam(cacheRegSz(i))).toMap
  )
  with HasBlackBoxPath
{
  val io = IO(new Bundle {
    val clk_i = Input(Clock())
    val rst_ni = Input(Bool())
    val boot_addr_i = Input(UInt(64.W))
    val hart_id_i = Input(UInt(64.W))
    val irq_i = Input(UInt(2.W))
    val ipi_i = Input(Bool())
    val time_irq_i = Input(Bool())
    val debug_req_i = Input(Bool())
    val trace_o = Output(UInt(traceportSz.W))

    val axi_resp_i_aw_ready      = Input(Bool())
    val axi_req_o_aw_valid       = Output(Bool())
    val axi_req_o_aw_bits_id     = Output(UInt(axiIdWidth.W))
    val axi_req_o_aw_bits_addr   = Output(UInt(axiAddrWidth.W))
    val axi_req_o_aw_bits_len    = Output(UInt(8.W))
    val axi_req_o_aw_bits_size   = Output(UInt(3.W))
    val axi_req_o_aw_bits_burst  = Output(UInt(2.W))
    val axi_req_o_aw_bits_lock   = Output(Bool())
    val axi_req_o_aw_bits_cache  = Output(UInt(4.W))
    val axi_req_o_aw_bits_prot   = Output(UInt(3.W))
    val axi_req_o_aw_bits_qos    = Output(UInt(4.W))
    val axi_req_o_aw_bits_region = Output(UInt(4.W))
    val axi_req_o_aw_bits_atop   = Output(UInt(6.W))
    val axi_req_o_aw_bits_user   = Output(UInt(axiUserWidth.W))

    val axi_resp_i_w_ready    = Input(Bool())
    val axi_req_o_w_valid     = Output(Bool())
    val axi_req_o_w_bits_data = Output(UInt(axiDataWidth.W))
    val axi_req_o_w_bits_strb = Output(UInt((axiDataWidth/8).W))
    val axi_req_o_w_bits_last = Output(Bool())
    val axi_req_o_w_bits_user = Output(UInt(axiUserWidth.W))

    val axi_resp_i_ar_ready      = Input(Bool())
    val axi_req_o_ar_valid       = Output(Bool())
    val axi_req_o_ar_bits_id     = Output(UInt(axiIdWidth.W))
    val axi_req_o_ar_bits_addr   = Output(UInt(axiAddrWidth.W))
    val axi_req_o_ar_bits_len    = Output(UInt(8.W))
    val axi_req_o_ar_bits_size   = Output(UInt(3.W))
    val axi_req_o_ar_bits_burst  = Output(UInt(2.W))
    val axi_req_o_ar_bits_lock   = Output(Bool())
    val axi_req_o_ar_bits_cache  = Output(UInt(4.W))
    val axi_req_o_ar_bits_prot   = Output(UInt(3.W))
    val axi_req_o_ar_bits_qos    = Output(UInt(4.W))
    val axi_req_o_ar_bits_region = Output(UInt(4.W))
    val axi_req_o_ar_bits_user   = Output(UInt(axiUserWidth.W))

    val axi_req_o_b_ready      = Output(Bool())
    val axi_resp_i_b_valid     = Input(Bool())
    val axi_resp_i_b_bits_id   = Input(UInt(axiIdWidth.W))
    val axi_resp_i_b_bits_resp = Input(UInt(2.W))
    val axi_resp_i_b_bits_user = Input(UInt(axiUserWidth.W))

    val axi_req_o_r_ready      = Output(Bool())
    val axi_resp_i_r_valid     = Input(Bool())
    val axi_resp_i_r_bits_id   = Input(UInt(axiIdWidth.W))
    val axi_resp_i_r_bits_data = Input(UInt(axiDataWidth.W))
    val axi_resp_i_r_bits_resp = Input(UInt(2.W))
    val axi_resp_i_r_bits_last = Input(Bool())
    val axi_resp_i_r_bits_user = Input(UInt(axiUserWidth.W))
  })

  require((exeRegCnt <= execRegAvail) && (exeRegBase.length <= execRegAvail) && (exeRegSz.length <= execRegAvail), s"Currently only supports $execRegAvail execution regions")
  require((cacheRegCnt <= cacheRegAvail) && (cacheRegBase.length <= cacheRegAvail) && (cacheRegSz.length <= cacheRegAvail), s"Currently only supports $cacheRegAvail cacheable regions")

  val root = System.getProperty("user.dir")
  addPath(s"$root/src/main/resources/vsrc/CVA6Wrapper.sv")
  addPath(s"$root/src/main/resources/vsrc/CVA6List.f")
}