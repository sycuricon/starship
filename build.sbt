/* 
 * Copyright (C) 2020-2023 by phantom
 * Email: phantom@zju.edu.cn
 * This file is under MIT License, see https://www.phvntom.tech/LICENSE.txt
 */

Global / lintUnusedKeysOnLoad := false

val chiselVersion = "6.7.0"

lazy val commonSettings = Seq(
  organization := "zjv",
  version := "0.2",
  scalaVersion := "2.13.16",
  scalacOptions ++= Seq(
    "-deprecation",
    "-feature",
    "-unchecked",
    "-language:reflectiveCalls",
    "-Ymacro-annotations"
  ),
  addCompilerPlugin("org.chipsalliance" % "chisel-plugin" % chiselVersion cross CrossVersion.full),
  libraryDependencies ++= Seq(
    "com.lihaoyi" %% "sourcecode" % "0.3.1",
    "com.github.scopt" %% "scopt" % "4.1.0",
    "com.lihaoyi" %% "mainargs" % "0.5.4",
    "org.json4s" %% "json4s-jackson" % "4.0.5",
    "org.scala-graph" %% "graph-core" % "1.13.5",
    "org.chipsalliance" %% "chisel" % chiselVersion,
  ),
  resolvers ++=
    Resolver.sonatypeOssRepos("snapshots") ++
    Resolver.sonatypeOssRepos("releases") :+
    Resolver.mavenLocal
)

lazy val cde = (project in file("repo/rocket-chip/dependencies/cde"))
  .settings(
    commonSettings,
    Compile / scalaSource := baseDirectory.value / "cde/src/chipsalliance/rocketchip"
  )

lazy val diplomacy  = (project in file("repo/rocket-chip/dependencies/diplomacy/diplomacy"))
  .dependsOn(cde)
  .settings(commonSettings)
  .settings(Compile / scalaSource := baseDirectory.value / "src/diplomacy")

lazy val ucb_hardfloat = (project in file("repo/rocket-chip/hardfloat/hardfloat"))
  .settings(commonSettings)

lazy val rocket_chip = (project in file("repo/rocket-chip"))
  .dependsOn(cde, diplomacy, ucb_hardfloat)
  .settings(commonSettings)

lazy val peripheral_blocks = (project in file("repo/rocket-chip-blocks"))
  .dependsOn(rocket_chip, cde)
  .settings(commonSettings)

lazy val fpga_shells = (project in file("repo/rocket-chip-fpga-shells"))
  .dependsOn(rocket_chip, peripheral_blocks, cde)
  .settings(
    commonSettings,
    Compile / unmanagedBase := baseDirectory.value,
    Compile / resourceDirectory := baseDirectory.value
  )

lazy val ucb_testchipip = (project in file("repo/testchipip/src"))
  .dependsOn(rocket_chip, peripheral_blocks)
  .settings(
    commonSettings,
    Compile / scalaSource := baseDirectory.value / "main/scala",
    Compile / resourceDirectory := baseDirectory.value / "main/resources"
  )

lazy val ucb_boom = (project in file("repo/riscv-boom/src"))
  .dependsOn(rocket_chip, ucb_testchipip)
  .settings(
    commonSettings,
    Compile / scalaSource := baseDirectory.value / "main/scala",
    Compile / resourceDirectory := baseDirectory.value / "main/resources"
  )

lazy val starship = (project in file("repo/starship"))
  .dependsOn(diplomacy, rocket_chip, cde, peripheral_blocks, fpga_shells, ucb_boom)
  .settings(commonSettings)

lazy val root = (project in file("."))
  .dependsOn(starship)
  .settings(commonSettings)
