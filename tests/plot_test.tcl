source test.tcl

# Perform material test
namespace path ::tcl::mathfunc
set x [linsteps 0.01 -10 10]
set y [vmap sin $x]

set fig [figure new]
$fig plot $x $y
mainLoop break
