source test.tcl

# Table module
tie tableObj [table new]
$tableObj define data {
    1 {x 3.44 y 7.11 z 8.67}
    2 {x 4.61 y 1.81 z 7.63}
    3 {x 8.25 y 7.56 z 3.84}
    4 {x 5.20 y 6.78 z 1.11}
    5 {x 3.26 y 9.92 z 4.56}
}
assert [$tableObj properties] eq {keyname key fieldname field keys {1 2 3 4 5} fields {x y z} data {1 {x 3.44 y 7.11 z 8.67} 2 {x 4.61 y 1.81 z 7.63} 3 {x 8.25 y 7.56 z 3.84} 4 {x 5.20 y 6.78 z 1.11} 5 {x 3.26 y 9.92 z 4.56}}}
tie tableCopy [$tableObj copy]
$tableCopy define keys {1 2} fields x
assert [$tableCopy properties] eq {keyname key fieldname field keys {1 2} fields x data {1 {x 3.44} 2 {x 4.61}}}
assert [$tableCopy] eq {keyname key fieldname field keys {1 2} fields x data {1 {x 3.44} 2 {x 4.61}}}

assert [$tableObj data] eq {1 {x 3.44 y 7.11 z 8.67} 2 {x 4.61 y 1.81 z 7.63} 3 {x 8.25 y 7.56 z 3.84} 4 {x 5.20 y 6.78 z 1.11} 5 {x 3.26 y 9.92 z 4.56}}
assert [$tableObj data 3] eq {x 8.25 y 7.56 z 3.84}

assert [$tableObj values] eq {{3.44 7.11 8.67} {4.61 1.81 7.63} {8.25 7.56 3.84} {5.20 6.78 1.11} {3.26 9.92 4.56}}

assert [$tableObj shape] eq {5 3}
assert [$tableObj height] == 5
assert [$tableObj width] == 3

tie tableCopy [$tableObj copy]
$tableCopy set 1 x 2.00 y 5.00 foo bar
assert [$tableCopy data 1] eq {x 2.00 y 5.00 z 8.67 foo bar}

set a 20.0; # external variable in "with" and "fedit"
tie tableCopy [$tableObj copy]
$tableCopy add fields q
$tableCopy with {
set q [expr {$x*2 + $a}]; # modify field value
}
assert [$tableCopy cget q] eq {26.88 29.22 36.5 30.4 26.52}

# Expr and fedit
tie tableCopy [$tableObj copy]
assert [$tableCopy expr {@x*2 + $a}] eq {26.88 29.22 36.5 30.4 26.52}
$tableCopy fedit q {@x*2 + $a}
assert [$tableCopy cget q] eq {26.88 29.22 36.5 30.4 26.52}

# Query
assert [$tableObj query {@x > 3.0 && @y > 7.0}] eq {1 3 5}

# Filter
tie tableCopy [$tableObj copy]
$tableCopy filter {@x > 3.0 && @y > 7.0}
assert [$tableCopy keys] eq {1 3 5}

tie tableCopy [$tableObj copy]
assert [$tableCopy search -real x 8.25] == 3; # returns first matching key
$tableCopy sort -real x
assert [$tableCopy keys] eq {5 1 2 4 3}
assert [$tableCopy cget x] eq {3.26 3.44 4.61 5.20 8.25}
assert [$tableCopy search -sorted -bisect -real x 5.0] == 2

$tableCopy search -inline -real x 8.25
assert [$tableCopy keys] == 3; # returns first matching key

# Merging
tie newTable [table new data {1 {x 5.00 q 6.34}}]
tie tableCopy [$tableObj copy]
# $newTable set 1 x 5.00 q 6.34
$tableCopy merge $newTable
$newTable destroy; # clean up
assert [$tableCopy properties] eq {keyname key fieldname field keys {1 2 3 4 5} fields {x y z q} data {1 {x 5.00 y 7.11 z 8.67 q 6.34} 2 {x 4.61 y 1.81 z 7.63} 3 {x 8.25 y 7.56 z 3.84} 4 {x 5.20 y 6.78 z 1.11} 5 {x 3.26 y 9.92 z 4.56}}}

tie table1 [table new keys {1 2 3}]
tie table2 [table new {keys {1 2 3}}]
assert [$table1] eq [$table2]
