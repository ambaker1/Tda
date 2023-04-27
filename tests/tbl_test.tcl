# Called from "build.tcl" in parent directory

# Table module
tie tblObj [tbl new]
$tblObj define data {
    1 {x 3.44 y 7.11 z 8.67}
    2 {x 4.61 y 1.81 z 7.63}
    3 {x 8.25 y 7.56 z 3.84}
    4 {x 5.20 y 6.78 z 1.11}
    5 {x 3.26 y 9.92 z 4.56}
}
assert [$tblObj properties] eq {keyname key fieldname field keys {1 2 3 4 5} fields {x y z} data {1 {x 3.44 y 7.11 z 8.67} 2 {x 4.61 y 1.81 z 7.63} 3 {x 8.25 y 7.56 z 3.84} 4 {x 5.20 y 6.78 z 1.11} 5 {x 3.26 y 9.92 z 4.56}}}
tie tblCopy [$tblObj copy]
$tblCopy define keys {1 2} fields x
assert [$tblCopy properties] eq {keyname key fieldname field keys {1 2} fields x data {1 {x 3.44} 2 {x 4.61}}}
assert [$tblCopy] eq {keyname key fieldname field keys {1 2} fields x data {1 {x 3.44} 2 {x 4.61}}}

assert [$tblObj data] eq {1 {x 3.44 y 7.11 z 8.67} 2 {x 4.61 y 1.81 z 7.63} 3 {x 8.25 y 7.56 z 3.84} 4 {x 5.20 y 6.78 z 1.11} 5 {x 3.26 y 9.92 z 4.56}}
assert [$tblObj data 3] eq {x 8.25 y 7.56 z 3.84}

assert [$tblObj values] eq {{3.44 7.11 8.67} {4.61 1.81 7.63} {8.25 7.56 3.84} {5.20 6.78 1.11} {3.26 9.92 4.56}}

assert [$tblObj shape] eq {5 3}
assert [$tblObj height] == 5
assert [$tblObj width] == 3

tie tblCopy [$tblObj copy]
$tblCopy set 1 x 2.00 y 5.00 foo bar
assert [$tblCopy data 1] eq {x 2.00 y 5.00 z 8.67 foo bar}

set a 20.0; # external variable in "with" and "fedit"
tie tblCopy [$tblObj copy]
$tblCopy add fields q
$tblCopy with {
set q [expr {$x*2 + $a}]; # modify field value
}
assert [$tblCopy cget q] eq {26.88 29.22 36.5 30.4 26.52}

# Expr and fedit
tie tblCopy [$tblObj copy]
assert [$tblCopy expr {@x*2 + $a}] eq {26.88 29.22 36.5 30.4 26.52}
$tblCopy fedit q {@x*2 + $a}
assert [$tblCopy cget q] eq {26.88 29.22 36.5 30.4 26.52}

# Query
assert [$tblObj query {@x > 3.0 && @y > 7.0}] eq {1 3 5}

# Filter
tie tblCopy [$tblObj copy]
$tblCopy filter {@x > 3.0 && @y > 7.0}
assert [$tblCopy keys] eq {1 3 5}

tie tblCopy [$tblObj copy]
assert [$tblCopy search -real x 8.25] == 3; # returns first matching key
$tblCopy sort -real x
assert [$tblCopy keys] eq {5 1 2 4 3}
assert [$tblCopy cget x] eq {3.26 3.44 4.61 5.20 8.25}
assert [$tblCopy search -sorted -bisect -real x 5.0] == 2

$tblCopy search -inline -real x 8.25
assert [$tblCopy keys] == 3; # returns first matching key

# Merging
tie newTable [tbl new data {1 {x 5.00 q 6.34}}]
tie tblCopy [$tblObj copy]
# $newTable set 1 x 5.00 q 6.34
$tblCopy merge $newTable
$newTable destroy; # clean up
assert [$tblCopy properties] eq {keyname key fieldname field keys {1 2 3 4 5} fields {x y z q} data {1 {x 5.00 y 7.11 z 8.67 q 6.34} 2 {x 4.61 y 1.81 z 7.63} 3 {x 8.25 y 7.56 z 3.84} 4 {x 5.20 y 6.78 z 1.11} 5 {x 3.26 y 9.92 z 4.56}}}

tie tbl1 [tbl new keys {1 2 3}]
tie tbl2 [tbl new {keys {1 2 3}}]
assert [$tbl1] eq [$tbl2]
