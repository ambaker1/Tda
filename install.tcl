package require tin 0.4.2
tin depend wob 0.1
set dir [tin mkdir -force tda 0.1.2]
file copy pkgIndex.tcl ndlist.tcl tbl.tcl io.tcl vis.tcl README.md LICENSE $dir
