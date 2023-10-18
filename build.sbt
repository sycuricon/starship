/* 
 * Copyright (C) 2020-2023 by phantom
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
  resolvers ++= Seq(
    Resolver.sonatypeRepo("snapshots"),
    Resolver.sonatypeRepo("releases"),
    Resolver.mavenLocal
  )
)

lazy val cde = (project in file("repo/rocket-chip/cde"))
  .settings(
    commonSettings,
    Compile / scalaSource := baseDirectory.value / "cde/src/chipsalliance/rocketchip"
  )

lazy val rocket_macros  = (project in file("repo/rocket-chip/macros"))
  .settings(
    commonSettings,
    libraryDependencies ++= Seq(
      "org.json4s" %% "json4s-jackson" % "4.0.6",
    )
  )

lazy val ucb_hardfloat = Project("hardfloat", file("repo/rocket-chip/hardfloat/hardfloat"))
  .settings(commonSettings)

lazy val rocket_chip = (project in file("repo/rocket-chip"))
  .dependsOn(cde, rocket_macros, ucb_hardfloat)
  .settings(commonSettings)

lazy val peripheral_blocks = (project in file("repo/rocket-chip-blocks"))
  .dependsOn(rocket_chip, cde)
  .settings(commonSettings)

lazy val fpga_shells = Project("fpga_shells", file("repo/rocket-chip-fpga-shells"))
  .dependsOn(rocket_chip, peripheral_blocks, cde)
  .settings(
    commonSettings,
    Compile / unmanagedBase := baseDirectory.value
  )

lazy val ucb_testchipip = Project("testchipip", file("repo/testchipip/src"))
  .dependsOn(rocket_chip, peripheral_blocks)
  .settings(
    commonSettings,
    Compile / scalaSource := baseDirectory.value / "main/scala",
    Compile / resourceDirectory := baseDirectory.value / "main/resources"
  )

lazy val ucb_boom = Project("boom", file("repo/riscv-boom/src"))
  .dependsOn(rocket_chip, ucb_testchipip)
  .settings(
    commonSettings,
    Compile / scalaSource := baseDirectory.value / "main/scala",
    Compile / resourceDirectory := baseDirectory.value / "main/resources"
  )

lazy val starship = (project in file("repo/starship"))
  .dependsOn(rocket_chip, cde, peripheral_blocks, fpga_shells, ucb_boom)
  .settings(commonSettings)

lazy val root = (project in file("."))
  .dependsOn(starship)
  .settings(commonSettings)
