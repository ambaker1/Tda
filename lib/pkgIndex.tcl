if {![package vsatisfies [package provide Tcl] 8.6]} {return}
package ifneeded tda 0.1.0 {
    package require tda::io 0.1.0
    package require tda::ndlist 0.1.0
    package require tda::table 0.1.0
    package require tda::plot 0.1.0
    package provide tda 0.1.0
}
package ifneeded tda::io 0.1.0 [list source [file join $dir io.tcl]]
package ifneeded tda::ndlist 0.1.0 [list source [file join $dir ndlist.tcl]]
package ifneeded tda::table 0.1.0 [list source [file join $dir table.tcl]]
package ifneeded tda::plot 0.1.0 [list source [file join $dir plot.tcl]]