package require tin 1.0
tin depend wob 1.0
set dir [tin mkdir -force tda 0.1.3]
file copy pkgIndex.tcl ndlist.tcl tbl.tcl io.tcl vis.tcl README.md LICENSE $dir
