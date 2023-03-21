if {![package vsatisfies [package provide Tcl] 8.6]} {return}
package ifneeded tda 0.1.0 [list source [file join $dir tda.tcl]]
package ifneeded tda::ndlist 0.1.0 [list source [file join $dir ndlist.tcl]]
package ifneeded tda::table 0.1.0 [list source [file join $dir table.tcl]]
