package require tin 0.4.4
tin import vutil; # For tie
tin import flytrap; # For assert
tin import wob; # For mainLoop

# Define build configuration
set config ""
dict set config VERSION 0.1.2
dict set config VERSION_NDLIST 0.1.0
dict set config VERSION_TBL 0.1.0
dict set config VERSION_IO 0.1.0
dict set config VERSION_VIS 0.1.1
# Bake the source files
foreach inFile [glob -directory src *.tin] {
    set outFile [file join build [file rootname [file tail $inFile]].tcl]
    tin bake $inFile $outFile $config
}

set dir build
source build/pkgIndex.tcl
tin import tda

# Run test files (uses "assert", will throw an error if any fail)
source tests/ndlist_test.tcl
source tests/tbl_test.tcl
source tests/io_test.tcl
source tests/vis_test.tcl

# Everything ok?
puts "Update main files and install? (Y/N)"
set result [gets stdin]
if {$result eq "Y"} {
    file copy -force {*}[glob -directory build *] [pwd]
    tin bake doc/template/version.tin doc/template/version.tex $config
    source install.tcl
}
