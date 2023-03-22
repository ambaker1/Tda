source include.tcl

namespace path ::tcl::mathfunc
set x [linsteps 0.01 -10 10]
set y1 [vmap sin $x]
set y2 [vmap cos $x]
plotXY $x $y1 $y2
# Table module
set tableObj [tdatbl new]
$tableObj define data {
    1 {x 3.44 y 7.11 z 8.67}
    2 {x 4.61 y 1.81 z 7.63}
    3 {x 8.25 y 7.56 z 3.84}
    4 {x 5.20 y 6.78 z 1.11}
    5 {x 3.26 y 9.92 z 4.56}
}
viewTable $tableObj
viewMatrix [$tableObj values]
wob::mainLoop
