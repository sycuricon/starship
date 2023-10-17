/* 
 * Copyright (C) 2021 by phantom
 * Email: phantom@zju.edu.cn
 * This file is under MIT License, see https://www.phvntom.tech/LICENSE.txt
 */

Global / lintUnusedKeysOnLoad := false

val chiselVersion = "3.6.0"

lazy val commonSettings = Seq(
  organization := "zjv",
  version := "0.2",
  scalaVersion := "2.13.10",
  scalacOptions ++= Seq(
    "-deprecation",
    "-feature",
    "-unchecked",
    "-language:reflectiveCalls",
    "-Ymacro-annotations"
  ),
  addCompilerPlugin("edu.berkeley.cs" % "chisel3-plugin" % chiselVersion cross CrossVersion.full),
  libraryDependencies ++= Seq(
    "com.github.scopt" %% "scopt" % "3.7.1",
    "edu.berkeley.cs" %% "chisel3" % chiselVersion,
    "com.lihaoyi" %% "mainargs" % "0.5.4",
  ),
  allDependencies := {
    val dropDeps = Seq(("edu.berkeley.cs", "rocketchip"))
    allDependencies.value.filterNot { dep =>
      dropDeps.contains((dep.organization, dep.name))
    }
  },
  resolvers ++= Seq(
    Resolver.sonatypeRepo("snapshots"),
    Resolver.sonatypeRepo("releases"),
    Resolver.mavenLocal
  )
)

lazy val cde = (project in file("repo/rocket-chip/cde"))
  .settings(commonSettings)
  .settings(Compile / scalaSource := baseDirectory.value / "cde/src/chipsalliance/rocketchip")

lazy val rocket_macros  = (project in file("repo/rocket-chip/macros"))
  .settings(commonSettings)
  .settings(
    libraryDependencies ++= Seq(
      "org.json4s" %% "json4s-jackson" % "4.0.6",
    )
  )

lazy val ucb_hardfloat = Project("hardfloat", file("repo/rocket-chip/hardfloat/hardfloat"))
  .settings(commonSettings)

lazy val rocket_chip = (project in file("repo/rocket-chip"))
  .dependsOn(cde, rocket_macros, ucb_hardfloat)
  .settings(commonSettings: _*)

lazy val peripheral_blocks = (project in file("repo/rocket-chip-blocks"))
  .dependsOn(rocket_chip, cde)
  .settings(commonSettings: _*)

lazy val fpga_shells = (project in file("repo/rocket-chip-fpga-shells"))
  .dependsOn(rocket_chip, peripheral_blocks, cde)
  .settings(commonSettings: _*)

lazy val ucb_testchipip = (project in file("repo/testchipip"))
  .dependsOn(rocket_chip, peripheral_blocks)
  .settings(commonSettings: _*)

lazy val ucb_boom = Project("boom", file("repo/riscv-boom/src"))
    .settings(
      Compile / scalaSource := baseDirectory.value / "main/scala",
      Compile / resourceDirectory := baseDirectory.value / "main/resources"
    )
    .dependsOn(rocket_chip, ucb_testchipip)
    .settings(commonSettings: _*)

lazy val startship_soc = (project in file("."))
  .dependsOn(rocket_chip, cde, peripheral_blocks, fpga_shells, ucb_boom)
  .settings(commonSettings: _*)
