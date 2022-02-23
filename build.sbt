/* 
 * Copyright (C) 2021 by phantom
 * Email: phantom@zju.edu.cn
 * This file is under MIT License, see https://www.phvntom.tech/LICENSE.txt
 */

Global / lintUnusedKeysOnLoad := false

lazy val commonSettings = Seq(
  organization := "zjv",
  version := "0.1",
  scalaVersion := "2.12.10",
  scalacOptions ++= Seq(
    "-deprecation",
    "-feature",
    "-unchecked",
    "-Xsource:2.11",
    "-language:reflectiveCalls"
  ),
  addCompilerPlugin(
    "edu.berkeley.cs" % "chisel3-plugin" % "3.5.0" cross CrossVersion.full
  ),
  libraryDependencies ++= Seq(
    "com.github.scopt" %% "scopt" % "3.7.1",
    // "edu.berkeley.cs" %% "chisel3" % "3.5.0",
    // "edu.berkeley.cs" %% "chiseltest" % "0.5.0" % "test"
  )
)

lazy val rocket_chip = RootProject(file("repo/rocket-chip"))

lazy val startship_soc = (project in file("."))
  .dependsOn(rocket_chip, sifive_blocks, fpga_shells)
  .settings(commonSettings: _*)

lazy val sifive_blocks = (project in file("repo/sifive-blocks"))
  .dependsOn(rocket_chip)
  .settings(commonSettings: _*)

lazy val fpga_shells = (project in file("repo/fpga-shells"))
  .dependsOn(rocket_chip, sifive_blocks)
  .settings(commonSettings: _*)