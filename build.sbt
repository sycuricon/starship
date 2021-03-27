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
    "-Xsource:2.11"
  )
)

lazy val rocket_chip = RootProject(file("repo/rocket-chip"))

lazy val startship_soc = (project in file("."))
  .dependsOn(rocket_chip)
  .settings(commonSettings: _*)