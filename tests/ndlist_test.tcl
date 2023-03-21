source include.tcl

namespace path ::tcl::mathfunc; # Makes all tcl math functions available as commands.
assert [vmap abs {-1 2 -3}] eq {1 2 3}

# Advanced vector access
assert [vget [range 0 20] end:-2:0] eq [range 20 0 -2]

assert [range 3] eq [range 0 2]
assert [range 10 3 -2] eq {10 8 6 4}

# Basic statistics
set a {-5 3 4 0}
assert [max $a] == 4
assert [min $a] == -5
assert [absmax $a] == 5
assert [absmin $a] == 0
assert [sum $a] == 2
assert [product $a] == 0
assert [mean $a] == 0.5
assert [median $a] == 1.5
assert [variance $a] == 16.333333333333332
assert [stdev $a] == 4.041451884327381

# Vector searching (using comparison operators)
assert [find {0 1 0 1 1 0}] eq {1 3 4}
assert [find {0.5 2.3 4.0 2.5 1.6 2.0 1.4 5.6} > 2] eq {1 2 3 7}
assert [find -all {0.5 2.3 4.0 2.5 1.6 2.0 1.4 5.6} > 2] eq {1 2 3 7}
assert [find -last {0.5 2.3 4.0 2.5 1.6 2.0 1.4 5.6} > 2] == 7
assert [find -first {0.5 2.3 4.0 2.5 1.6 2.0 1.4 5.6} > 2] == 1

assert [find -first {0 0 0}] == -1
assert [find -last {0 0 0}] == -1
assert [find -first {0 0 0} == 1] == -1
assert [find -last {0 0 0} == 1] == -1

# Create identity matrix
foreach i [range 3] {
    mset I $i $i 1
}
assert $I eq {{1 0 0} {0 1 0} {0 0 1}}

# Matrix for testing (DO NOT CHANGE)
set testmat {{1 2 3} {4 5 6} {7 8 9}}

assert [vmap max [transpose $testmat]] eq {7 8 9}
assert [cmap max $testmat] eq {7 8 9}
assert [rmap max $testmat] eq {3 6 9}

# Vector generation
assert [range 4] eq {0 1 2 3}
assert [range 0 4] eq {0 1 2 3 4}
assert [range 0 4 2] eq {0 2 4}
assert [linspace 5 0 1] eq {0.0 0.25 0.5 0.75 1.0}
assert [linsteps 0.25 0 1 0] eq {0.0 0.25 0.5 0.75 1.0 0.75 0.5 0.25 0.0}
assert [linterp 0.5 {0 1} {-1 1}] == 0.0

# Matrix manipulation
assert [transpose $testmat] eq {{1 4 7} {2 5 8} {3 6 9}}
assert [stack $testmat {{10 11 12}}] eq {{1 2 3} {4 5 6} {7 8 9} {10 11 12}}
assert [augment $testmat {a b c}] eq {{1 2 3 a} {4 5 6 b} {7 8 9 c}}
assert [flatten $testmat] eq {1 2 3 4 5 6 7 8 9}
assert [reshape {1 2 3 4 5 6} 3 2] eq {{1 2} {3 4} {5 6}}

# Linear algebra
assert [dot {1 2 3} {-2 -4 3}] == -1
assert [cross {1 2 3} {-2 -4 3}] eq {18.0 -9.0 0.0}
assert [norm {1 2 3}] == [expr {sqrt(14)}]
assert [norm {1 2 3} 1] == [sum {1 2 3}]
assert [norm {1 2 3} Inf] == [absmax {1 2 3}]
assert [norm {1 2 3} 4] == [expr {pow(1**4 + 2**4 + 3**4,0.25)}]
assert [norm [normalize {1 2 3}]] == 1
assert [matmul {{2 5 1 3} {4 1 7 9} {6 8 3 2} {7 8 1 4}} {9 3 0 -3}] eq {24.0 12.0 72.0 75.0}
assert [matmul $I {1.0 2.0 3.0}] eq {1.0 2.0 3.0}
assert [catch {matmul $I {{1 2 3}}}] == 1
assert [matmul {{1 2 3}} {-2 -4 3}] eq [dot {1 2 3} {-2 -4 3}]
assert [cartprod {1 2 3} {a b c}] eq {{1 a} {1 b} {1 c} {2 a} {2 b} {2 c} {3 a} {3 b} {3 c}}


# Matrix access
assert [mget $testmat : :] eq $testmat
assert [mget $testmat : 0] eq {1 4 7}
assert [mget $testmat : 0*] eq {1 4 7}
assert [mget $testmat : 0:1] eq {{1 2} {4 5} {7 8}}
assert [mget $testmat : 1:0] eq {{2 1} {5 4} {8 7}}
assert [mget $testmat 0 :] eq {{1 2 3}}
assert [mget $testmat 0 0] eq {1}
assert [mget $testmat 0 0*] eq {1}
assert [mget $testmat 0 0:1] eq {{1 2}}
assert [mget $testmat 0 1:0] eq {{2 1}}
assert [mget $testmat 0* :] eq {1 2 3}
assert [mget $testmat 0* 0] eq {1}
assert [mget $testmat 0* 0*] eq {1}
assert [mget $testmat 0* 0:1] eq {1 2}
assert [mget $testmat 0* 1:0] eq {2 1}
assert [mget $testmat 0:1 :] eq {{1 2 3} {4 5 6}}
assert [mget $testmat 0:1 0] eq {1 4}
assert [mget $testmat 0:1 0*] eq {1 4}
assert [mget $testmat 0:1 0:1] eq {{1 2} {4 5}}
assert [mget $testmat 0:1 1:0] eq {{2 1} {5 4}}
assert [mget $testmat 1:0 :] eq {{4 5 6} {1 2 3}}
assert [mget $testmat 1:0 0] eq {4 1}
assert [mget $testmat 1:0 0*] eq {4 1}
assert [mget $testmat 1:0 0:1] eq {{4 5} {1 2}}
assert [mget $testmat 1:0 1:0] eq {{5 4} {2 1}}
assert [mget $testmat 0:2:end :] eq {{1 2 3} {7 8 9}}

assert [mreplace $testmat : : ""] eq ""
assert [mreplace $testmat : : a] eq {{a a a} {a a a} {a a a}}
assert [mreplace $testmat : : {a b c}] eq {{a a a} {b b b} {c c c}}
assert [mreplace $testmat : : {{a b c}}] eq {{a b c} {a b c} {a b c}}
assert [mreplace $testmat : : {{a b c} {d e f} {g h i}}] eq {{a b c} {d e f} {g h i}}
assert [mreplace $testmat : 0 ""] eq {{2 3} {5 6} {8 9}}
assert [mreplace $testmat : 0 a] eq {{a 2 3} {a 5 6} {a 8 9}}
assert [mreplace $testmat : 0 {a b c}] eq {{a 2 3} {b 5 6} {c 8 9}}
assert [mreplace $testmat : 0* ""] eq {{2 3} {5 6} {8 9}}
assert [mreplace $testmat : 0* a] eq {{a 2 3} {a 5 6} {a 8 9}}
assert [mreplace $testmat : 0* {a b c}] eq {{a 2 3} {b 5 6} {c 8 9}}
assert [mreplace $testmat : 0:1 ""] eq {3 6 9}
assert [mreplace $testmat : 0:1 a] eq {{a a 3} {a a 6} {a a 9}}
assert [mreplace $testmat : 0:1 {a b c}] eq {{a a 3} {b b 6} {c c 9}}
assert [mreplace $testmat : 0:1 {{a b}}] eq {{a b 3} {a b 6} {a b 9}}
assert [mreplace $testmat : 0:1 {{a b} {c d} {e f}}] eq {{a b 3} {c d 6} {e f 9}}
assert [mreplace $testmat : 1:0 ""] eq {3 6 9}
assert [mreplace $testmat : 1:0 a] eq {{a a 3} {a a 6} {a a 9}}
assert [mreplace $testmat : 1:0 {a b c}] eq {{a a 3} {b b 6} {c c 9}}
assert [mreplace $testmat : 1:0 {{a b}}] eq {{b a 3} {b a 6} {b a 9}}
assert [mreplace $testmat : 1:0 {{a b} {c d} {e f}}] eq {{b a 3} {d c 6} {f e 9}}
assert [mreplace $testmat 0 : ""] eq {{4 5 6} {7 8 9}}
assert [mreplace $testmat 0 : a] eq {{a a a} {4 5 6} {7 8 9}}
assert [mreplace $testmat 0 : {{a b c}}] eq {{a b c} {4 5 6} {7 8 9}}
assert [catch {mreplace $testmat 0 0 ""}] == 1; # do not allow for non-axis deletion
assert [mreplace $testmat 0 0 a] eq {{a 2 3} {4 5 6} {7 8 9}}
assert [mreplace $testmat 0 0* a] eq {{a 2 3} {4 5 6} {7 8 9}}
assert [mreplace $testmat 0 0:1 a] eq {{a a 3} {4 5 6} {7 8 9}}
assert [mreplace $testmat 0 0:1 {{a b}}] eq {{a b 3} {4 5 6} {7 8 9}}
assert [mreplace $testmat 0 1:0 a] eq {{a a 3} {4 5 6} {7 8 9}}
assert [mreplace $testmat 0 1:0 {{a b}}] eq {{b a 3} {4 5 6} {7 8 9}}
assert [mreplace $testmat 0* : ""] eq {{4 5 6} {7 8 9}}
assert [mreplace $testmat 0* : a] eq {{a a a} {4 5 6} {7 8 9}}
assert [mreplace $testmat 0* : {a b c}] eq {{a b c} {4 5 6} {7 8 9}}
assert [mreplace $testmat 0* 0 a] eq {{a 2 3} {4 5 6} {7 8 9}}
assert [mreplace $testmat 0* 0* {hello world}] eq {{{hello world} 2 3} {4 5 6} {7 8 9}}
assert [mreplace $testmat 0* 0:1 a] eq {{a a 3} {4 5 6} {7 8 9}}
assert [mreplace $testmat 0* 0:1 {a b}] eq {{a b 3} {4 5 6} {7 8 9}}
assert [mreplace $testmat 0* 1:0 a] eq {{a a 3} {4 5 6} {7 8 9}}
assert [mreplace $testmat 0* 1:0 {a b}] eq {{b a 3} {4 5 6} {7 8 9}}
assert [mreplace $testmat 0:1 : ""] eq {{7 8 9}}
assert [mreplace $testmat 0:1 : a] eq {{a a a} {a a a} {7 8 9}}
assert [mreplace $testmat 0:1 : {{a b c}}] eq {{a b c} {a b c} {7 8 9}}
assert [mreplace $testmat 0:1 : {a b}] eq {{a a a} {b b b} {7 8 9}}
assert [mreplace $testmat 0:1 : {{a b c} {d e f}}] eq {{a b c} {d e f} {7 8 9}}
assert [mreplace $testmat 0:1 0 a] eq {{a 2 3} {a 5 6} {7 8 9}}
assert [mreplace $testmat 0:1 0 {a b}] eq {{a 2 3} {b 5 6} {7 8 9}}
assert [mreplace $testmat 0:1 0* a] eq {{a 2 3} {a 5 6} {7 8 9}}
assert [mreplace $testmat 0:1 0* {{hello world} {foo bar}}] eq {{{hello world} 2 3} {{foo bar} 5 6} {7 8 9}}
assert [mreplace $testmat 0:1 0:1 a] eq {{a a 3} {a a 6} {7 8 9}}
assert [mreplace $testmat 0:1 0:1 {a b}] eq {{a a 3} {b b 6} {7 8 9}}
assert [mreplace $testmat 0:1 0:1 {{a b}}] eq {{a b 3} {a b 6} {7 8 9}}
assert [mreplace $testmat 0:1 0:1 {{a b} {c d}}] eq {{a b 3} {c d 6} {7 8 9}}
assert [mreplace $testmat 0:1 1:0 a] eq {{a a 3} {a a 6} {7 8 9}}
assert [mreplace $testmat 0:1 1:0 {a b}] eq {{a a 3} {b b 6} {7 8 9}}
assert [mreplace $testmat 0:1 1:0 {{a b}}] eq {{b a 3} {b a 6} {7 8 9}}
assert [mreplace $testmat 0:1 1:0 {{a b} {c d}}] eq {{b a 3} {d c 6} {7 8 9}}
assert [mreplace $testmat 1:0 : ""] eq {{7 8 9}}
assert [mreplace $testmat 1:0 : a] eq {{a a a} {a a a} {7 8 9}}
assert [mreplace $testmat 1:0 : {{a b c}}] eq {{a b c} {a b c} {7 8 9}}
assert [mreplace $testmat 1:0 : {a b}] eq {{b b b} {a a a} {7 8 9}}
assert [mreplace $testmat 1:0 : {{a b c} {d e f}}] eq {{d e f} {a b c} {7 8 9}}
assert [mreplace $testmat 1:0 0 a] eq {{a 2 3} {a 5 6} {7 8 9}}
assert [mreplace $testmat 1:0 0 {a b}] eq {{b 2 3} {a 5 6} {7 8 9}}
assert [mreplace $testmat 1:0 0* a] eq {{a 2 3} {a 5 6} {7 8 9}}
assert [mreplace $testmat 1:0 0* {{hello world} {foo bar}}] eq {{{foo bar} 2 3} {{hello world} 5 6} {7 8 9}}
assert [mreplace $testmat 1:0 0:1 a] eq {{a a 3} {a a 6} {7 8 9}}
assert [mreplace $testmat 1:0 0:1 {a b}] eq {{b b 3} {a a 6} {7 8 9}}
assert [mreplace $testmat 1:0 0:1 {{a b}}] eq {{a b 3} {a b 6} {7 8 9}}
assert [mreplace $testmat 1:0 0:1 {{a b} {c d}}] eq {{c d 3} {a b 6} {7 8 9}}
assert [mreplace $testmat 1:0 1:0 a] eq {{a a 3} {a a 6} {7 8 9}}
assert [mreplace $testmat 1:0 1:0 {a b}] eq {{b b 3} {a a 6} {7 8 9}}
assert [mreplace $testmat 1:0 1:0 {{a b}}] eq {{b a 3} {b a 6} {7 8 9}}
assert [mreplace $testmat 1:0 1:0 {{a b} {c d}}] eq {{d c 3} {b a 6} {7 8 9}}


# nexpr stuff
# Equivalence of nexpr and nop
assert [nexpr 1D x {1 2 3} {-$x}] eq [nop 1D - {1 2 3}]
# Filter a column out
assert [mexpr x $testmat {[j] == 2 ? [continue] : $x}] eq [mreplace $testmat : 2 ""]
# Flip signs
assert [mexpr x $testmat {$x*([i]%2 + [j]%2 == 1?-1:1)}] eq {{1 -2 3} {-4 5 -6} {7 -8 9}}
# Truncation
assert [vexpr x $testmat {[i] > 0 ? [break] : $x}] eq {{1 2 3}}
# Basic operations
assert [mexpr x $testmat {-$x}] eq {{-1 -2 -3} {-4 -5 -6} {-7 -8 -9}}
assert [mop - $testmat] eq {{-1 -2 -3} {-4 -5 -6} {-7 -8 -9}}

assert [mexpr x $testmat {$x / 2.0}] eq {{0.5 1.0 1.5} {2.0 2.5 3.0} {3.5 4.0 4.5}}
assert [mop $testmat / 2.0] eq {{0.5 1.0 1.5} {2.0 2.5 3.0} {3.5 4.0 4.5}}
assert [mexpr x $testmat y {.1 .2 .3} {$x + $y}] eq {{1.1 2.1 3.1} {4.2 5.2 6.2} {7.3 8.3 9.3}}
assert [mop $testmat .+ {.1 .2 .3}] eq {{1.1 2.1 3.1} {4.2 5.2 6.2} {7.3 8.3 9.3}}
assert [mexpr x $testmat y {{.1 .2 .3}} {$x + $y}] eq {{1.1 2.2 3.3} {4.1 5.2 6.3} {7.1 8.2 9.3}}
assert [mop $testmat .+ {{.1 .2 .3}}] eq {{1.1 2.2 3.3} {4.1 5.2 6.3} {7.1 8.2 9.3}}
assert [mexpr x $testmat y {{.1 .2 .3} {.4 .5 .6} {.7 .8 .9}} {$x + $y}] eq {{1.1 2.2 3.3} {4.4 5.5 6.6} {7.7 8.8 9.9}}
assert [mop $testmat .+ {{.1 .2 .3} {.4 .5 .6} {.7 .8 .9}}] eq {{1.1 2.2 3.3} {4.4 5.5 6.6} {7.7 8.8 9.9}}

assert [mexpr x $testmat {double($x)}] eq {{1.0 2.0 3.0} {4.0 5.0 6.0} {7.0 8.0 9.0}}
assert [mmap {::tcl::mathfunc::double} $testmat] eq {{1.0 2.0 3.0} {4.0 5.0 6.0} {7.0 8.0 9.0}}
assert [vmap max $testmat] eq {3 6 9}
assert [nmap 1D {format %.2f} {1 2 3}] eq {1.00 2.00 3.00}
assert [cmap max $testmat] eq [vmap max [transpose $testmat]]
set cutoff 3
assert [nexpr 1D x {1 2 3 4 5 6} {$x > $cutoff ? [continue] : $x}] eq {1 2 3}
assert [vget {1 2 3 4 5 6} [find [vop {1 2 3 4 5 6} <= $cutoff]]] eq {1 2 3}

set a {{1 2} {3 4} {5 6}}
nset a {1 0} : [nget $a {0 1} :]
assert $a eq {{3 4} {1 2} {5 6}}
assert [nop 1D  - {1 2 3}] eq {-1 -2 -3}
assert [nop 1D {1 2 3} + 1] eq {2 3 4}
assert [nop 1D {1 2 3} .+ {3 2 1}] eq {4 4 4}

# Higher dimension stuff
assert [nrepeat 2 2 2 0] eq {{{0 0} {0 0}} {{0 0} {0 0}}}
set a ""
assert [nset a 1 1 1 foo] eq {{{0 0} {0 0}} {{0 0} {0 foo}}}; # fills with zeros
set ::tda::ndlist::filler bar; # custom filler
set a ""
assert [nset a 1 1 1 foo] eq {{{bar bar} {bar bar}} {{bar bar} {bar foo}}}; # fills with bar
set ::tda::ndlist::filler 0; # reset to default

# ND for loop testing
set count 0
vfor x {1 2 3} {
    incr count
}
assert $count == 3
set count 0
mfor {10 10} {
    incr count
}
assert $count == 100

# Cartgrid
dict set params x {1 2 3}
dict set params {y z} {a b c d}
assert [cartgrid $params] eq {{x 1 y a z b} {x 1 y c z d} {x 2 y a z b} {x 2 y c z d} {x 3 y a z b} {x 3 y c z d}}
assert [cartgrid $params] eq [cartgrid {*}$params]
