package starship.playyard.cde

import chisel3._

import freechips.rocketchip.config.{Config, Field, Parameters}

case object TestKey1 extends Field[Int](-1)
case object TestKey2 extends Field[Int]
case object TestKey3 extends Field[Int](-3)
case object TestKey4 extends Field[Int]

class TestConfig extends Config((site, here, up) => {
  case TestKey1 => 0
})


object CDETest {
    def main(args: Array[String]): Unit = {

        // Empty config
        var p: Parameters = Parameters.empty

        // Parameter Access
        assert(p(TestKey1) == p.apply(TestKey1))
        assert(p(TestKey1) == p.lift(TestKey1).get)

        // Default Value
        assert(p(TestKey1) == -1)
        try { p(TestKey4) }
        catch {
            case e: java.lang.IllegalArgumentException => println(s"TestKey4 == ${p.lift(TestKey4)}")
        }

        // Alter
        p = Parameters((site, here, up) => {
            case TestKey1 => 1
        })
        p = p.alter((site, here, up) => {
            case TestKey2 => 2
        })
        p = p.alterPartial({
            case TestKey3 => 3
        })
        p = p.alterMap(Map(
            TestKey4 -> 4
        ))
        assert(p(TestKey1) == 1)
        assert(p(TestKey2) == 2)
        assert(p(TestKey3) == 3)
        assert(p(TestKey4) == 4)

        // site, here, up
        p = Parameters((site, here, up) => {
            case TestKey1 => 0
        }) ++ Parameters((site, here, up) => {
            case TestKey1 => 1
            case TestKey2 => here(TestKey1, site) + 1
            case TestKey3 => up(TestKey4, site) - 1
        }) ++ Parameters((site, here, up) => {
            case TestKey4 => site(TestKey1, site) + 4
        })
        assert(p(TestKey1) == 0)
        assert(p(TestKey2) == 2)
        assert(p(TestKey3) == 3)
        assert(p(TestKey4) == 4)

        print("[CDETest] SUCCESS\n")
    }
}
