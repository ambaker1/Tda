if {![package vsatisfies [package provide Tcl] 8.6]} {return}
package ifneeded tda 0.1.3 {
    package require tda::ndlist 0.1.0
    package require tda::tbl 0.1.0
    package require tda::io 0.1.0
    package require tda::vis 0.1.2
    package provide tda 0.1.3
}
package ifneeded tda::ndlist 0.1.0 [list source [file join $dir ndlist.tcl]]
package ifneeded tda::tbl 0.1.0 [list source [file join $dir tbl.tcl]]
package ifneeded tda::io 0.1.0 [list source [file join $dir io.tcl]]
package ifneeded tda::vis 0.1.2 [list source [file join $dir vis.tcl]]
