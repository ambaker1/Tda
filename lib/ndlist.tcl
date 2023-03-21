# ndlist.tcl
################################################################################
# Vectors, matrices, and higher-dimension lists

# Copyright (C) 2023 Alex Baker, ambaker1@mtu.edu
# All rights reserved. 

# See the file "LICENSE" in the top level directory for information on usage, 
# redistribution, and for a DISCLAIMER OF ALL WARRANTIES.
################################################################################

# Define namespace
namespace eval ::tda::ndlist {
    # Internal variables
    variable nfor_i; # nfor index array
    array set nfor_i ""
    variable nfor_break; # nfor break passer
    variable filler 0; # Filler for nreplace
    
    # Vector generation
    namespace export range; # Generate integer range
    namespace export linsteps; # Walk between target values at constant step.
    namespace export linspace; # Generate equally spaced list.
    namespace export linterp; # Linear 1D interpolation
    namespace export find; # Find non-zero indices in boolean list.
    
    # Matrix manipulation
    namespace export flatten reshape; # flatten a matrix to list, or vice versa
    namespace export stack augment; # Combine matrices, row or column-wise
    namespace export transpose; # Transpose a matrix
    
    # Basic linear algebra
    namespace export dot; # Dot product of two vectors
    namespace export cross; # Cross product of two 3D vectors
    namespace export norm; # Get norm of a vector
    namespace export normalize; # Normalize a vector to have norm of 1.0
    namespace export matmul; # Multiply matrices
    
    # Iteration tools
    namespace export cartprod; # Cartesian product of vectors
    namespace export cartgrid; # Cartesian product of dictionary
    
    # Basic statistics
    namespace export max min; # Extreme values
    namespace export absmax absmin; # Absolute extremes
    namespace export sum product; # Sum or product
    namespace export mean median; # Average statistics
    namespace export variance stdev; # Variance statistics
    
    # N-dimensional list access and mapping
    namespace export nrepeat mrepeat vrepeat; # Create ndlist with one value
    namespace export nshape mshape vshape; # Get dimensions of ndlist
    namespace export nget mget vget; # Get values in ndlist
    namespace export nset mset vset; # Set values in ndlist
    namespace export nreplace mreplace vreplace; # Replace values in-place
    namespace export rget rset rreplace; # Modify matrix rows
    namespace export cget cset creplace; # Modify matrix columns
    namespace export nmap mmap vmap rmap cmap; # Functional map over ndlists
    namespace export nfor mfor vfor; # ndlist looping and iteration
    namespace export i j k; # Index access commands
    namespace export nexpr mexpr vexpr; # Expression mapping over ndlists
    namespace export nop mop vop; # Map math operations over ndlists
}

# range --
#
# Generate integer range
# 
# range $n
# range $start $stop
# range $start $stop $step
#
# Arguments:
# n:        Number of integers
# start:    Start of resultant range.
# stop:     End limit of resultant range.
# step:     Step size. Default 1 or -1, depending on direction.

proc ::tda::ndlist::range {args} {
    # Switch for arity
    if {[llength $args] == 1} {
        # Basic case
        set n [lindex $args 0]
        if {![string is integer -strict $n] || $n < 0} {
            return -code error "n must be integer >= 0"
        }
        set start 0
        set stop [expr {$n - 1}]
        set step 1
    } elseif {[llength $args] == 2} {
        lassign $args start stop
        if {![string is integer -strict $start]} {
            return -code error "start must be integer"
        }
        if {![string is integer -strict $stop]} {
            return -code error "stop must be integer"
        }
        set step [expr {$stop > $start ? 1 : -1}]
    } elseif {[llength $args] == 3} {
        lassign $args start stop step
        if {![string is integer -strict $start]} {
            return -code error "start must be integer"
        }
        if {![string is integer -strict $stop]} {
            return -code error "stop must be integer"
        }
        if {![string is integer -strict $step]} {
            return -code error "step must be integer"
        }
    } else {
        return -code error "wrong # args: should be \"range n\", \"range start\
                stop\", or \"range start stop step\""
    }
    return [Range $start $stop $step]
}

# Range --
#
# Private handler to generate an integer range

proc ::tda::ndlist::Range {start stop step} {
    # Avoid divide by zero
    if {$step == 0} {
        return ""
    }
    # Get range length
    set n [expr {($stop - $start)/$step + 1}]
    # Basic cases
    if {$n <= 0} {
        return ""
    }
    if {$n == 1} {
        return $start
    }
    # General case (generate list)
    set i [expr {$start - $step}]
    lmap x [lrepeat $n {}] {incr i $step}
}

# linsteps --
# 
# Generate list that walks between targets, with a maximum step size.
# 
# Arguments:
# stepSize:     Magnitude of step size (must be > 0.0)
# start:        Starting value
# args:         Targets to walk through

proc ::tda::ndlist::linsteps {stepSize start args} {
    # Interpret inputs and coerce into double (throws error if not double)
    set stepSize [expr {double($stepSize)}]
    if {$stepSize <= 0.0} {
        return -code error "Step size must be > 0.0"
    }
    set start [expr {double($start)}]
    set targets [lmap target $args {
        expr {double($target)}
    }]
    # Initialize with start
    set values [list $start]
    # Loop through targets
    foreach target $targets {
        set gap [expr {$target - $start}]
        # Skip for duplicates
        if {$gap == 0} {
            continue
        }
        # Calculate step value and number of steps
        set step [expr {$gap > 0 ? $stepSize : -$stepSize}]; 
        set n [expr {int($gap/$step)}]
        for {set i 1} {$i <= $n} {incr i} {
            lappend values [expr {$start + $i*$step}]
        }
        # For the case where it doesn't go all the way
        if {[lindex $values end] != $target} {
            lappend values $target
        }
        # Reset for next target (if any)
        set start $target
    }
    return $values
}

# linspace --
#
# Generate equally spaced list with specific number of points
#
# Arguments:
# n:        Number of points
# x1:       First number 
# x2:       Last number

proc ::tda::ndlist::linspace {n x1 x2} {
    set x1 [expr {double($x1)}]
    set x2 [expr {double($x2)}]
    set gap [expr {$x2 - $x1}]
    set values ""
    for {set i 0} {$i < $n} {incr i} {
        lappend values [expr {$x1 + $gap*$i/($n - 1.0)}]
    }
    return $values
}

# linterp --
# 
# Simple linear interpolation, assuming ascending order on list X
#
# Arguments:
# xq:           x values to query
# xp:           x points
# yp:           y points (same length as xp)

proc ::tda::ndlist::linterp {xq xp yp} {
    # Error check size of input
    if {[llength $xp] != [llength $yp]} {
        return -code error "x and y must be same size"
    }
    # Perform matches
    set values ""
    foreach x $xq {
        set x1 [lindex $xp 0]
        set y1 [lindex $yp 0]
        # Check bounds
        if {$x < $x1} {
            return -code error "xq value $x below bounds of xp"
        }; # end if
        foreach x2 [lrange $xp 1 end] y2 [lrange $yp 1 end] {
            # Error check
            if {$x1 >= $x2} {
                return -code error "xp must be strictly increasing"
            }
            # Compare x to x1 & x2
            if {$x == $x1} {
                # Simple match
                lappend values $y1
                break
            } elseif {$x > $x1 && $x < $x2} {
                # Interpolate
                set r [expr {($x-$x1)/($x2-$x1)}]; # ratio into line-segment
                set y [expr {$r*($y2-$y1)+$y1}]
                lappend values $y
                break
            } elseif {$x == $x2} {
                # Simple match
                lappend values $y2
                break
            } else {
                set x1 $x2
                set y1 $y2 
                continue
            }; # end if
        }; # end foreach
        # Check bounds
        if {$x > $x2} {
            return -code error "xq value $x above bounds of xp"
        }; # end if
    }; # end foreach
    return $values
}

# find --
#
# Comparison-style vector searching. By default, converts logical vector into
# list of indices for use in nget/nset/nreplace.
#
# Arguments:
# vector:       Vector to find values. 
# op scalar:    Comparison operator and comparison scalar value. Default != 0
# option:       -first, -last, or -all. Default -all.
#               If first or last, returns single index, -1 for failure.
#               If all, returns list of indices, blank for none.

proc ::tda::ndlist::find {args} {
    if {[llength $args] > 4} {
        return -code error "wrong # args: should be\
                \"find ?type? vector ?op value?\""
    }
    # Type of search
    if {[llength $args] % 2 == 0} {
        set type [lindex $args 0]
        set vector [lindex $args 1]
        if {$type ni {-first -last -all}} {
            return -code error "Unknown option. Try -first, -last, or -all"
        }
    } else {
        set type -all
        set vector [lindex $args 0]
    }
    # Comparison operator and scalar value
    if {[llength $args] > 2} {
        # User provided comparison operator and scalar value
        set op [lindex $args end-1]
        set scalar [lindex $args end]
        if {$op ni {== != > < >= <= in ni eq ne}} {
            return -code error "Invalid comparison operator"
        }
        switch $type {
            -first {FindFirst $vector $op $scalar}
            -last {FindLast $vector $op $scalar}
            -all {FindAll $vector $op $scalar}
        }
    } else {
        # Treat as boolean vector
        switch $type {
            -first {FindFirstBool $vector}
            -last {FindLastBool $vector}
            -all {FindAllBool $vector}
        }
    }
}

# FindAll --
#
# Find all indices meeting criteria

proc ::tda::ndlist::FindAll {vector op scalar} {
    set i 0
    set indices ""
    foreach value $vector {
        if {[::tcl::mathop::$op $value $scalar]} {
            lappend indices $i
        }
        incr i
    }
    return $indices
}

# FindAllBool --
#
# Find all true indices

proc ::tda::ndlist::FindAllBool {vector} {
    set i 0
    set indices ""
    foreach value $vector {
        if {$value} {
            lappend indices $i
        }
        incr i
    }
    return $indices
}

# FindFirst --
#
# Find first index meeting criteria

proc ::tda::ndlist::FindFirst {vector op scalar} {
    set i 0
    foreach value $vector {
        if {[::tcl::mathop::$op $value $scalar]} {
            return $i
        }
        incr i
    }
    return -1
}

# FindFirstBool --
#
# Find first true indices

proc ::tda::ndlist::FindFirstBool {vector} {
    set i 0
    foreach value $vector {
        if {$value} {
            return $i
        }
        incr i
    }
    return -1
}

# FindLast --
#
# Find last index meeting criteria

proc ::tda::ndlist::FindLast {vector op scalar} {
    for {set i [expr {[llength $vector] - 1}]} {$i >= 0} {incr i -1} {
        if {[::tcl::mathop::$op [lindex $vector $i] $scalar]} {
            return $i
        }
    }
    return -1
}

# FindLastBool --
#
# Find last true index

proc ::tda::ndlist::FindLastBool {vector} {
    for {set i [expr {[llength $vector] - 1}]} {$i >= 0} {incr i -1} {
        if {[lindex $vector $i]} {
            return $i
        }
    }
    return -1
}

# Matrix manipulation
################################################################################

# flatten --
#
# Flatten an matrix to a list without shimmering
# Reference: https://wiki.tcl-lang.org/page/join
#
# Arguments:
# matrix:       Matrix to flatten to 1D

proc ::tda::ndlist::flatten {matrix} {
    concat {*}$matrix
}

# reshape --
# 
# Create a row-oriented matrix from a list of values
#
# Arguments:
# list:         List of values
# n:            Number of rows
# m:            Number of columns

proc ::tda::ndlist::reshape {list n m} {
    set size [expr {$n*$m}]
    if {[llength $list] != $size} {
        return -code error "incompatible dimensions"
    }
    set i -$m
    set j -1
    lmap x [lrepeat $n {}] {
        lrange $list [incr i $m] [incr j $m]
    }
}

# stack --
# 
# Stacks matrices (row-wise)
# 
# Arguments:
# mat1 mat2? mat3?:     Arbitrary number of matrices

proc ::tda::ndlist::stack {args} {
    set Matrix [lindex $args 0]
    set M [llength [lindex $Matrix 0]]
    foreach matrix [lrange $args 1 end] {
        set m [llength [lindex $matrix 0]]
        if {$m != $M} {
            return -code error "incompatible number of columns"
        }
        set Matrix [concat $Matrix $matrix]
    }
    return $Matrix
}

# augment --
# 
# Augments matrices (column-wise)
# 
# Arguments:
# mat1 mat2? mat3?:     Arbitrary number of matrices

proc ::tda::ndlist::augment {args} {
    set Matrix [lindex $args 0]
    set N [llength $Matrix]
    foreach matrix [lrange $args 1 end] {
        set n [llength $matrix]
        if {$n != $N} {
            return -code error "incompatible number of rows"
        }
        set Matrix [lmap Row $Matrix row $matrix {concat $Row $row}]
    }
    return $Matrix
}

# transpose --
# 
# Transposes a matrix
# Adapted from math::linearalgebra::transpose and lsearch example on Tcl wiki
# written by MJ (https://wiki.tcl-lang.org/page/Transposing+a+matrix)
# 
# Arguments:
# matrix:           Matrix to transpose

proc ::tda::ndlist::transpose {matrix} {
    set n [llength $matrix]
    set m [llength [lindex $matrix 0]]
    if {$n == 1 && $m == 1} {
        return $matrix
    } elseif {$n > $m} {
        set i -1
        lmap x [lindex $matrix 0] {
            lsearch -all -inline -subindices -index [incr i] $matrix *
        }
    } else {
        set i -1
        lmap x [lindex $matrix 0] {
            incr i
            lmap row $matrix {lindex $row $i}
        }
    }
}

# Linear algebra routines
################################################################################

# dot --
# 
# Dot product of two vectors of arbitrary dimension
# Code modified from dotproduct in math::linearalgebra package
# 
# Arguments:
# a:            First vector
# b:            Second vector

proc ::tda::ndlist::dot {a b} {
    if {[llength $a] != [llength $b]} {
       return -code error "vectors must be same size"
    }
    set sum 0.0
    foreach ai $a bi $b {
        set sum [expr {$sum + $ai*$bi}]
    }
    return $sum
}

# cross --
# 
# Cross product of two 3D vectors, vec1 vec2
# Code modified from crossproduct in math::linearalgebra package
#
# Arguments:
# a:            First vector, 3D
# b:            Second vector, 3D

proc ::tda::ndlist::cross {a b} {
    if {[llength $a] != 3 || [llength $b] != 3} {
        return -code error "cross-product only defined for 3D vectors"
    }
    lassign $a a1 a2 a3
    lassign $b b1 b2 b3
    set c1 [expr {double($a2*$b3 - $a3*$b2)}]
    set c2 [expr {double($a3*$b1 - $a1*$b3)}]
    set c3 [expr {double($a1*$b2 - $a2*$b1)}]
    return [list $c1 $c2 $c3]
}

# norm --
# 
# Norm of vector (returns double)
# Code modified from norm in math::linearalgebra package
#
# Arguments:
# vector:       Vector
# p:            Norm type. Default 2 (euclidean distance).

proc ::tda::ndlist::norm {vector {p 2}} {
    switch $p {
        1 { # Sum of absolute values
            set norm 0.0
            foreach value $vector {
                set norm [expr {$norm+abs($value)}]
            }
            return $norm
        }
        2 { # Euclidean (use hypot function to avoid overflow)
            set norm 0.0
            foreach value $vector {
                set norm [expr {hypot($value,$norm)}]
            }
            return $norm
        }
        Inf { # Absolute maximum of the vector
            return [expr {double([absmax $vector])}]
        }
        default { # Arbitrary integer norm
            if {![string is integer -strict $p] || $p <= 0} {
                return -code error "p must be integer > 0"
            }
            set sum 0.0
            foreach value $vector {
                set sum [expr {$sum+$value**$p}]
            }
            return [expr {pow($sum,1.0/$p)}]
        }
    }
}

# normalize --
# 
# Normalize vector to have norm of 1.0
# Adapted from math::linearalgebra::unitLengthVector
#
# Arguments:
# vector:       Vector to normalize
# p:            Norm type. Default 2 (euclidean distance)

proc ::tda::ndlist::normalize {vector {p 2}} {
    set norm [norm $vector $p]
    if {$norm == 0} {
        return -code error "cannot normalize a null vector"
    }
    lmap value $vector {expr {$value/$norm}}
}

# matmul --
#
# Multiplies an arbitrary number of matrices. Must agree in dimension.
# Adapted from math::linearalgebra::matmul, but more general and optimized.
#
# Arguments:
# args:     Matrices which have matching inner dimensions
#
# Returns a nxm matrix, by computing the dot-product of rows and columns

proc ::tda::ndlist::matmul {args} {
    # Check dimensions
    set n [llength $args]
    if {$n < 2} {
        return -code error "Must provide at least two matrices"
    } elseif {$n == 2} {
        lassign $args A B
        if {[llength [lindex $A 0]] != [llength $B]} {
            return -code error "Matrix dimensions do not agree"
        }
        # Transpose B matrix for easy multiplication
        set BT [transpose $B]
        # Perform dot-product of all rows and columns
        return [lmap rowA $A {
            lmap colB $BT {
                dot $rowA $colB
            }
        }]
    } else {
        # Determine optimal order of computation
        # This uses a non-recursive matrix chain optimization algorithm
        # as described in "Introduction to Algorithms" by Cormen (2001)
        # --------------------------------------------
        # Input is a list of matrices
        set matrices $args
        # Get list of dimensions
        set dims [lmap matrix $matrices {llength $matrix}]
        lappend dims [llength [lindex $matrices end end]]
        # Initialize cost and best split cache
        set costs [lrepeat $n [lrepeat $n 0]]
        set bests [lrepeat $n [lrepeat $n 0]]
        # Loop through gaps greater than 1
        for {set gap 2} {$gap < $n + 1} {incr gap} {
            for {set i 0} {$i < $n - $gap + 1} {incr i} {
                # Get start and end dimensions
                set dimI [lindex $dims $i]
                set j [expr {$i + $gap - 1}]
                set dimJ [lindex $dims $j+1]
                # Initialize cost as infinite, and best split as zero
                set costIJ Inf
                set bestIJ 0
                # Loop through all potential splits
                for {set k $i} {$k < $j} {incr k} {
                    set dimK [lindex $dims $k+1]
                    set costIK [lindex $costs $i $k]
                    set costKJ [lindex $costs $k+1 $j]
                    set cost [expr {$costIK + $costKJ + $dimI * $dimK * $dimJ}]
                    # Update cost and best split if minimized
                    if {$cost < $costIJ} {
                        set costIJ $cost
                        set bestIJ $k
                    }
                }; # end for loop (split location)
                # Save cost and best split
                lset costs $i $j $costIJ
                lset bests $i $j $bestIJ
            }; # end for loop (starting dimension)
        }; # end for loop (gap size)
        
        # Recursively multiply according to optimal splits
        return [OptimalMatMul 0 [expr {$n - 1}]]
    }
}

# OptimalMatMul --
# 
# Private procedure that recursively handles the optimal matrix multiplication.
# Only used in matmul for cases of more than 2 matrices.
#
# Arguments:
# i:        Index of first matrix
# j:        Index of last matrix

proc ::tda::ndlist::OptimalMatMul {i j} {
    # Access variables in caller
    upvar bests bests; # Matrix of best splits
    upvar matrices matrices; # List of matrices
    
    # Recursion stopping criteria
    if {$i == $j} {
        return [lindex $matrices $i]
    } elseif {$j - $i == 1} {
        # Throws error if matrix dimensions are incorrect.
        return [matmul {*}[lrange $matrices $i $j]]
    }
    
    # Determine split point and recurse.
    set k1 [lindex $bests $i $j]
    set k2 [expr {$k1 + 1}]
    return [matmul [OptimalMatMul $i $k1] [OptimalMatMul $k2 $j]]   
}

# cartprod --
# 
# Cartesian product of multiple vectors (can have duplicates)
# Returns a list of all combinations
# Modified from "cartesianNaryProduct", accessed on 12/15/2021 at 
# https://rosettacode.org/wiki/Cartesian_product_of_two_or_more_lists
#
# Arguments:
# args:         Vectors to take "cartesian product" of

proc ::tda::ndlist::cartprod {args} {
    foreach vector [lassign $args matrix] { 
        set newMatrix {}
        foreach row $matrix {
            foreach value $vector {
                lappend newMatrix [linsert $row end $value]
            }
        }
        set matrix $newMatrix
    }
    return $matrix
}

# cartgrid --
# 
# Create a grid of all configurations of specified parameters.
# Grid is list of dictionaries.
#
# Arguments:
# args       key-value pairs of parameters and lists, or one dictionary

proc ::tda::ndlist::cartgrid {args} {
    # Check arity
    if {[llength $args] == 1} {
        set args [lindex $args 0]
    }
    if {[llength $args]%2 == 1} {
        return -code error "wrong # of args: want \"cartgrid ?key value ...?\""
    }
    # Strip duplicates by converting to dictionary
    set args [dict get $args]
    # Initialize variables for recursive function
    set line ""
    set grid ""
    # Call recursive function
    TraverseAndUpdateGrid {*}$args
    return $grid
}

# TraverseAndUpdateGrid --
#
# Private recursive function which creates parameter grid.

proc ::tda::ndlist::TraverseAndUpdateGrid {args} {
    upvar line line
    upvar grid grid
    if {[llength $args] == 0} {
        # Base case
        lappend grid $line
    } else {
        set args [lassign $args varList list]
        foreach $varList $list {
            foreach var $varList {
                dict set line $var [subst $$var]
            }
            TraverseAndUpdateGrid {*}$args
        }
    }
    return
}

# Vector statistics
################################################################################

# max --
# 
# Maximum value

proc ::tda::ndlist::max {vector} {
    if {[llength $vector] == 0} {
        return -code error "max requires at least one value"
    }
    foreach value [lassign $vector max] {
        if {![string is double -strict $value]} {
            return -code error "expected number but got \"$value\""
        }
        if {$value > $max} {
            set max $value
        }
    }
    return $max
}

# min --
# 
# Minimum value 

proc ::tda::ndlist::min {vector} {
    if {[llength $vector] == 0} {
        return -code error "min requires at least one value"
    }
    foreach value [lassign $vector min] {
        if {![string is double -strict $value]} {
            return -code error "expected number but got \"$value\""
        }
        if {$value < $min} {
            set min $value
        }
    }
    return $min
}

# absmax --
#
# Absolute maximum value 

proc ::tda::ndlist::absmax {vector} {
    if {[llength $vector] == 0} {
        return -code error "absmax requires at least one value"
    }
    set absmax [expr {abs([lindex $vector 0])}]
    foreach value [lrange $vector 1 end] {
        set value [expr {abs($value)}]
        if {$value > $absmax} {
            set absmax $value
        }
    }
    return $absmax
}

# absmin --
#
# Absolute minimum value 

proc ::tda::ndlist::absmin {vector} {
    if {[llength $vector] == 0} {
        return -code error "absmin requires at least one value"
    }
    set absmin [expr {abs([lindex $vector 0])}]
    foreach value [lrange $vector 1 end] {
        set value [expr {abs($value)}]
        if {$value < $absmin} {
            set absmin $value
        }
    }
    return $absmin
}

# sum --
# 
# Sum of values

proc ::tda::ndlist::sum {vector} {
    if {[llength $vector] == 0} {
        return -code error "sum requires at least one value"
    }
    foreach value [lassign $vector sum] {
        set sum [expr {$sum + $value}]
    }
    return $sum
}

# product --
# 
# Product of values

proc ::tda::ndlist::product {vector} {
    if {[llength $vector] == 0} {
        return -code error "product requires at least one value"
    }
    foreach value [lassign $vector product] {
        set product [expr {$product * $value}]
    }
    return $product
}

# mean --
# 
# Mean value

proc ::tda::ndlist::mean {vector} {
    if {[llength $vector] == 0} {
        return -code error "mean requires at least one value"
    }
    return [expr {double([sum $vector])/[llength $vector]}]
}

# median --
# 
# Median value (sorts, then takes middle values)

proc ::tda::ndlist::median {vector} {
    set n [llength $vector]
    if {$n == 0} {
        return -code error "median requires at least one value"
    }
    set sorted [lsort -real $vector]
    if {$n%2 == 1} {
        set i [expr {($n-1)/2}]
        set median [lindex $sorted $i]
    } else {
        set i [expr {$n/2}]
        set j [expr {$n/2 - 1}]
        set median [expr {([lindex $sorted $i] + [lindex $sorted $j])/2.0}]
    }; # end if
    return $median
}

# variance -- 
#
# Sample or population variance
# pop:      Whether to compute population variance. Boolean, default false.

proc ::tda::ndlist::variance {vector {pop 0}} {
    set n [llength $vector]
    if {$n < 2} {
        return -code error "sample variance requires at least 2 values"
    }
    set mean [mean $vector]
    set squares [lmap x $vector {expr {($x - $mean)**2}}]
    return [expr {double([sum $squares])/($n - 1 + bool($pop))}]
}

# stdev -- 
#
# Sample standard deviation

proc ::tda::ndlist::stdev {args} {
    expr {sqrt([variance {*}$args])}
}

# N-Dimensional List implementation
################################################################################

# nrepeat --
#
# Create an ndlist filled with one value
#
# Arguments:
# n, m, ...     Dimensions of ndlist
# value:        Value to repeat

proc ::tda::ndlist::nrepeat {args} {
    foreach n [lassign [lreverse $args] ndlist] {
        set ndlist [lrepeat $n $ndlist]
    }
    return $ndlist
}

proc ::tda::ndlist::mrepeat {n m value} {
    nrepeat $n $m $value
}

proc ::tda::ndlist::vrepeat {n value} {
    lrepeat $n $value
}

# nshape --
#
# Get dimensions of ndlist given a number of dimensions. Assumes proper ndlist
#
# Arguments:
# ndtype:       Type of ndlist (e.g. 1D, 2D, etc.)
# ndlist:       ndlist to get size of
# dim:          Dimension to get along. Zero for all dimensions

proc ::tda::ndlist::nshape {ndtype ndlist {dim ""}} {
    set ndims [InterpretNDType $ndtype]
    # Switch for type
    if {$dim == ""} {
        return [GetDims $ndims $ndlist]
    } elseif {$dim >= 0 && $dim < $ndims} {
        # Get single dimension (along first index)
        return [llength [lindex $ndlist {*}[lrepeat $dim 0]]]
    } else {
        return -code error "dim must be between 0 and [expr {$ndims - 1}]"
    }
}

proc ::tda::ndlist::mshape {matrix {dim ""}} {
    nshape 2D $matrix $dim
}

proc ::tda::ndlist::vshape {vector} {
    llength $vector
}

# InterpretNDType --
# Interpret dimension argument for ndlist commands that require ndims.

proc ::tda::ndlist::InterpretNDType {ndtype} {
    if {![regexp {^\d+[dD]$} $ndtype]} {
        return -code error "Invalid ND syntax"
    }
    return [string range $ndtype 0 end-1]
}

# GetDims --
#
# Private procedure to get dimensions of an ndlist along first index

proc ::tda::ndlist::GetDims {ndims ndlist} {
    # Get list of dimensions (along first index)
    set dims ""
    foreach i [lrepeat $ndims {}] {
        lappend dims [llength $ndlist]
        set ndlist [lindex $ndlist 0]
    }
    return $dims
}

# nget --
# 
# Get portion of ndlist using ndlist index notation.
#
# Arguments:
# ndlist:       Valid ndlist
# indices:      Separate arguments for index dimensions

proc ::tda::ndlist::nget {ndlist args} {
    set indices $args
    set ndims [llength $indices]
    # Scalar case
    if {$ndims == 0} {
        return $ndlist
    }
    # Parse indices
    set dims [GetDims $ndims $ndlist]
    set iArgs [lassign [ParseIndices $indices $dims] iDims iLims]
    # Process limits and dimensions
    set subdims ""
    foreach dim $dims iLim $iLims iDim $iDims {
        if {$iLim >= $dim} {
            return -code error "index out of range"
        }
        if {$iDim > 0} {
            lappend subdims $iDim
        }
    }
    # Parse indices
    return [RecGet $ndlist {*}$iArgs]
}

proc ::tda::ndlist::mget {matrix i j} {
    nget $matrix $i $j
}
proc ::tda::ndlist::rget {matrix i} {
    nget $matrix $i* :
}
proc ::tda::ndlist::cget {matrix j} {
    nget $matrix : $j*
}
proc ::tda::ndlist::vget {vector i} {
    nget $vector $i
}

# RecGet --
#
# Private recursive handler for nget
# 
# Arguments:
# ndlist:       ndlist to index
# args:         iType, iList, ...
# Types:    
#   A: All indices
#   L: List of indices
#   R: Range of indices
#   S: Single index (flatten)

proc ::tda::ndlist::RecGet {ndlist iType iList args} {
    # Base case
    if {[llength $args] == 0} {
        return [Get $ndlist $iType $iList]
    }
    # Flatten for "S" case
    if {$iType eq "S"} {
        RecGet [Get $ndlist $iType $iList] {*}$args
    } else {
        lmap ndrow [Get $ndlist $iType $iList] {
            RecGet $ndrow {*}$args
        }
    }
}

# Get --
#
# Base case for RecGet

proc ::tda::ndlist::Get {list iType iList} {
    # Switch for index type
    switch $iType {
        A { # All indices
            return $list
        }
        L { # List of indices
            return [lmap i $iList {
                lindex $list $i
            }]
        }
        R { # Range of indices
            lassign $iList i1 i2
            if {$i2 >= $i1} {
                return [lrange $list $i1 $i2]
            } else {
                return [lreverse [lrange $list $i2 $i1]]
            }
        }
        S { # Single index (flatten)
            set i [lindex $iList 0]
            return [lindex $list $i]
        }
    }
}

# nset --
# 
# Set portion of ndlist using ndlist index notation.
# Simply calls nreplace to set new value of ndlist.
#
# Arguments:
# varName:      Variable where a valid ndlist is stored
# indices:      Separate arguments for index dimensions
# sublist:      Sublist to set (must agree in dimension or unity)

# Examples:
# > set a {1 2 3 4}
# > nset a 0:1 {foo bar}
# > puts $a
# foo bar 3 4

proc ::tda::ndlist::nset {varName args} {
    upvar 1 $varName ndlist
    # Initialize ndlist if not set yet
    if {![info exists ndlist]} {
        set ndlist ""
    }
    set ndlist [nreplace $ndlist {*}$args]
    return $ndlist
}

proc ::tda::ndlist::mset {varName i j submat} {
    tailcall nset $varName $i $j $submat
}
proc ::tda::ndlist::rset {varName i subrow} {
    tailcall nset $varName $i* : $subrow
}
proc ::tda::ndlist::cset {varName j subcol} {
    tailcall nset $varName : $j* $subcol
}
proc ::tda::ndlist::vset {varName i subvec} {
    tailcall nset $varName $i $subvec
}

# nreplace --
#
# Replace portion of ndlist - return new list
# 
# Arguments:
# ndlist:       Valid ndlist
# indices:      Separate arguments for index dimensions
# sublist:      Sublist to replace with (must agree in dimension or unity)
#               If blank, removes elements (must remove only along one axis)

proc ::tda::ndlist::nreplace {ndlist args} {
    # Interpret arguments
    set indices [lrange $args 0 end-1]
    set sublist [lindex $args end]
    set ndims [llength $indices]
    # Scalar case
    if {$ndims == 0} {
        return $sublist
    }
    # Parse indices
    set dims [GetDims $ndims $ndlist]
    set iArgs [lassign [ParseIndices $indices $dims] iDims iLims]
    # Scalar case
    if {[llength $iArgs] == 0} {
        return $sublist
    }
    # Switch for replacement type (removal or substitution)
    if {[llength $sublist] == 0} {
        # Removal/deletion    
        # Get axis to delete along
        set axis -1
        set i 0
        foreach {iType iList} $iArgs {
            if {$iType ne "A"} {
                if {$axis != -1} {
                    return -code error "can only delete along one axis"
                }
                set axis $i
            }
            incr i
        }
        # Trivial case (removal of all)
        if {$axis == -1} {
            return ""
        }
        # Get axis information
        set dim [lindex $dims $axis]
        set iDim [lindex $iDims $axis]
        set iLim [lindex $iLims $axis]
        set iType [lindex $iArgs [expr {$axis * 2}]]
        set iList [lindex $iArgs [expr {$axis * 2 + 1}]]
        # Handle "L" case, indices must be sorted and unique.
        if {$iType eq "L"} {
            set iList [lsort -integer -decreasing -unique $iList]
            set iDim [llength $iList]
        }
        # Check for null case
        if {$dim == $iDim} {
            return ""
        }
        # Call recursive removal handler
        return [RecRemove $ndlist $axis $iType $iList]
    } else {
        # Substitution/replacement
        # Expand ndlist if needed based on index limits.
        foreach dim $dims iLim $iLims {
            if {$iLim >= $dim} {
                # Get expanded dimensions and expand ndlist
                set dims [lmap dim $dims iLim $iLims {
                    expr {$iLim >= $dim ? $iLim + 1 : $dim}
                }]
                set ndlist [Expand $ndlist {*}$dims]
                break
            }
        }
        # Process input dimensions
        set subdims ""
        foreach iDim $iDims {
            if {$iDim > 0} {
                lappend subdims $iDim
            }
        }
        # Tile sublist if needed based on index dimensions.
        set sublist [NTile $sublist {*}$subdims]
        # Call recursive replacement handler
        return [RecReplace $ndlist $sublist {*}$iArgs]
    }
    return $ndlist
}

proc ::tda::ndlist::mreplace {matrix i j submat} {
    nreplace $matrix $i $j $submat
}
proc ::tda::ndlist::rreplace {matrix i subrow} {
    nreplace $matrix $i* : $subrow
}
proc ::tda::ndlist::creplace {matrix j subcol} {
    nreplace $matrix : $j* $subcol
}
proc ::tda::ndlist::vreplace {vector i subvec} {
    nreplace $vector $i $subvec
}

# NTile --
#
# Tile an ndlist to compatible dimensions.
#
# Arguments:
# ndlist:       The ndlist to tile
# args:         New dimensions

proc ::tda::ndlist::NTile {ndlist args} {    
    set dims1 $args
    set dims0 [GetDims [llength $dims1] $ndlist]
    foreach dim0 $dims0 dim1 $dims1 {
        if {$dim0 != $dim1} {
            return [RecTile $ndlist $dims0 $dims1]
        }
    }
    return $ndlist
}

# RecTile --
#
# Recursive handler for NTile. 
# Tiles a compatible ndlist (dimensions must match or be unity) 
# For example, 1x1, 1x4, 4x1, and 5x4 are all compatible with 5x4.

proc ::tda::ndlist::RecTile {ndlist dims0 dims1} {
    # Switch for base cases
    if {[llength $dims0] == 0} {
        return $ndlist
    } elseif {[llength $dims0] == 1} {
        return [Tile $ndlist $dims0 $dims1]
    }
    # Strip dimension from args
    set dims0 [lassign $dims0 n0]
    set dims1 [lassign $dims1 n1]
    if {$n0 != $n1} {
        lrepeat $n1 [RecTile [lindex $ndlist 0] $dims0 $dims1]
    } else {
        lmap ndrow $ndlist {
            RecTile $ndrow $dims0 $dims1
        }
    }
}

# Tile --
#
# Base case for RecTile. Throws error if dimensions are incompatible

proc ::tda::ndlist::Tile {list n0 n1} {
    if {$n0 == $n1} {
        return $list
    } elseif {$n0 == 1} {
        return [lrepeat $n1 [lindex $list 0]]
    } else {
        return -code error "incompatible dimensions"
    }
}

# RecRemove --
#
# Private recursive handler for removing elements from ndlists
#
# Arguments:
# ndlist:       ndlist to modify (value, not name)
# axis:         Axis to remove on
# iType:        Index type (A is not an option for Remove)
# Types:    
#   L: List of indices
#   R: Range of indices
#   S: Single index (does not flatten)
# iList:        List corresponding to index type (varies)

proc ::tda::ndlist::RecRemove {ndlist axis iType iList} {
    # Base case
    if {$axis == 0} {
        return [Remove $ndlist $iType $iList]
    }
    # Recursion case
    incr axis -1
    set ndlist [lmap ndrow $ndlist {
        RecRemove $ndrow $axis $iType $iList
    }]
    return $ndlist
}

# Remove --
#
# Base case for RecRemove

proc ::tda::ndlist::Remove {list iType iList} {
    # Base case
    switch $iType {
        L { # Subset of indices
            foreach i $iList {
                set list [lreplace $list $i $i]
            }
        }
        R { # Range of indices
            lassign $iList i1 i2
            if {$i2 >= $i1} {
                set list [lreplace $list $i1 $i2]
            } else {
                set list [lreplace $list $i2 $i1]
            }
        }
        S { # Single index (same as L for removal)
            set i [lindex $iList 0]
            set list [lreplace $list $i $i]
        }
    }
    return $list
}

# RecReplace --
#
# Private recursive handler for nreplace
# 
# Arguments:
# ndlist:       ndlist to modify (pass by value)
# sublist:      ndlist to substitute at specified indices
# args:         iType, iList, ...
# Types:    
#   A: All indices
#   L: List of indices
#   R: Range of indices
#   S: Single index

proc ::tda::ndlist::RecReplace {ndlist sublist iType iList args} {
    # Base case
    if {[llength $args] == 0} {
        return [Replace $ndlist $sublist $iType $iList]
    }
    # Get portion of ndlist to perform substitution
    set ndrows [Get $ndlist $iType $iList]
    # Recursively replace elements in sublist
    if {$iType eq "S"} {
        set sublist [RecReplace $ndrows $sublist {*}$args]
    } else {
        set sublist [lmap ndrow $ndrows subrow $sublist {
            RecReplace $ndrow $subrow {*}$args
        }]
    }
    # Finally, replace at this level.
    return [Replace $ndlist $sublist $iType $iList]
}

# Replace --
#
# Base case (list) for RecReplace 
# 
# Arguments:
# list:         list to modify (pass by value)
# sublist:      list to substitute at specified indices
# args:         iType, iList, ...
# Types:    
#   A: All indices
#   L: List of indices
#   R: Range of indices
#   S: Single index

proc ::tda::ndlist::Replace {list sublist iType iList} {
    # Switch for index type
    switch $iType {
        A { # All indices
            set list $sublist
        }
        L { # Subset of indices
            foreach i $iList subrow $sublist {
                lset list $i $subrow
            }
        }
        R { # Range of indices
            lassign $iList i1 i2
            if {$i2 >= $i1} {
                set list [lreplace $list $i1 $i2 {*}$sublist]
            } else {
                set list [lreplace $list $i2 $i1 {*}[lreverse $sublist]]
            }
        }
        S { # Single index (flatten)
            set i [lindex $iList 0]
            lset list $i $sublist
        }
    }
    return $list
}

# Expand --
#
# Expand an ndlist to specified dimension list, so that lset doesn't throw error

proc ::tda::ndlist::Expand {ndlist n args} {
    variable filler
    # Expand list as needed
    if {[llength $ndlist] < $n} {
        lappend ndlist {*}[lrepeat [expr {$n-[llength $ndlist]}] $filler]
    }
    # Base case
    if {[llength $args] == 0} {
        return $ndlist
    }
    # Recursion for higher-dimension lists
    lmap sublist $ndlist {
        Expand $sublist {*}$args
    }
}

# ParseIndices --
# 
# Loop through index inputs - returning required information for getting/setting
# 
# Returns a list - iDim then iArgs, where iArgs is a key-value list
# iDims iLims iType iList iType iList ...

proc ::tda::ndlist::ParseIndices {inputs dims} {
    set iDims ""; # dimensions of indexed region
    set iLims ""; # Maximum indices for indexed region
    set iArgs ""; # paired list of index type and index list (meaning varies)
    foreach input $inputs dim $dims {
        lassign [ParseIndex $input $dim] iDim iLim iType iList 
        lappend iDims $iDim
        lappend iLims $iLim
        lappend iArgs $iType $iList
    }
    return [list $iDims $iLims {*}$iArgs]
}

# ParseIndex --
# 
# Used for parsing index input (i.e. list of indices, range 0:10, etc
# Returns list, with first element being the index input type, and the remaining
# arguments being the index integers.

# Returns:
# iDim:     Dimension of indexed range (e.g. number of indices)
# iLim:     Largest index in indexed range
# iType:    Type of index
#   A:      All indices
#   R:      Range of indices
#   L:      List of indices 
#   S:      Single index (flattens array, iDim = 0)
# iList:    Depends on iType. For range, i1 and i2

proc ::tda::ndlist::ParseIndex {input n} {
    # Check length of input
    if {[llength $input] == 1} {
        # Single index, colon, or range notation
        set index [lindex $input 0]
        # Check for colon (special syntax)
        if {[string match *:* $index]} {
            # Colon or range notation
            if {[string length $index] == 1} {
                # Colon notation (all indices)
                set iType A
                set iList ""
                set iDim $n
                set iLim [expr {$n - 1}]
            } else {
                # Range notation (slice)
                set parts [split $index :]
                if {[llength $parts] == 2} {
                    # Simple range
                    lassign $parts i1 i2
                    set i1 [Index2Integer $i1 $n]
                    set i2 [Index2Integer $i2 $n]
                    set iType R
                    set iList [list $i1 $i2]
                    if {$i2 >= $i1} {
                        # Forward range
                        set iDim [expr {$i2 - $i1 + 1}]
                        set iLim $i2
                    } else {
                        # Reverse range
                        set iDim [expr {$i1 - $i2 + 1}]
                        set iLim $i1
                    }
                } elseif {[llength $parts] == 3} {
                    # Skipped range
                    lassign $parts i1 step i2
                    set i1 [Index2Integer $i1 $n]
                    set i2 [Index2Integer $i2 $n]
                    if {![string is integer -strict $step]} {
                        return -code error "invalid range index notation"
                    }
                    # Deal with range case
                    if {$i2 >= $i1} {
                        if {$step == 1} {
                            # Forward range
                            set iType R
                            set iList [list $i1 $i2]
                            set iDim [expr {$i2 - $i1 + 1}]
                            set iLim $i2; # end of range
                        } else {
                            # Forward stepped range (list)
                            set iType L
                            set iList [Range $i1 $i2 $step]
                            set iDim [llength $iList]
                            set iLim [lindex $iList end]; # end of list
                        }
                    } else {
                        if {$step == -1} {
                            # Reverse range
                            set iType R
                            set iList [list $i1 $i2]
                            set iDim [expr {$i1 - $i2 + 1}]
                            set iLim $i1; # start of range
                        } else {
                            # Reverse stepped range (list)
                            set iType L
                            set iList [Range $i1 $i2 $step]
                            set iDim [llength $iList]
                            set iLim [lindex $iList 0]; # start of list
                        }
                    }
                } else {
                    return -code error "invalid range index notation"
                }
            }; # end if just colon or if range notation
        } elseif {[string index $index end] eq "*"} {
            # Single index notation (flatten along this dimension)
            set i [Index2Integer [string range $index 0 end-1] $n]
            set iType S
            set iList $i
            set iDim 0; # flattens
            set iLim $i
        } else {
            # Single index list (do not flatten)
            set i [Index2Integer $index $n]
            set iType L
            set iList $i
            set iDim 1
            set iLim $i
        }; # end parse single index
    } else {
        # List of indices (user entered)
        set iType L
        set iList [lmap index $input {Index2Integer $index $n}]
        set iDim [llength $iList]
        set iLim 0
        foreach i $iList {
            if {$i > $iLim} {
                set iLim $i
            }
        }
    }
    return [list $iDim $iLim $iType $iList]
}

# Index2Integer --
#
# Private function, converts end+-integer index format into integer
# Negative indices get converted, such that -1 is end, -2 is end-1, etc.
#
# Arguments:
# index:        Tcl index format (integer?[+-]integer? or end?[+-]integer?)
# n:            Length of list to index

proc ::tda::ndlist::Index2Integer {index n} {
    # Default case (skip regexp, much faster)
    if {[string is integer -strict $index]} {
        set i $index
    } else {
        # Check if index is valid format
        set match [regexp -inline {^(end|[+-]?[0-9]+)([+-][0-9]+)?$} $index]
        if {[llength $match] == 0} {
            return -code error "bad index \"$index\": must be\
                    integer?\[+-\]integer? or end?\[+-\]integer?"
        }
        # Convert end to n-1 if needed
        set base [lindex $match 1]
        if {$base eq {end}} {
            set base [expr {$n - 1}]
        }
        # Handle offset
        set offset [lindex $match 2]
        if {$offset eq {}} {
            set i $base
        } else {
            set i [expr {$base + $offset}]
        }
    }
    # Handle negative index (from end)
    if {$i < 0} {
        set i [expr {$i % $n}]
    }
    return $i
}

# nmap --
#
# Map a command over an ndlist, functional programming style.
#
# ndtype:       Number of dimensions (e.g. 1D, 2D, etc.)
# command:      Command prefix (list)
# ndlist:       ndlist to map over
# args:         Additional arguments to command after ndlist

proc ::tda::ndlist::nmap {ndtype command ndlist args} {
    set ndims [InterpretNDType $ndtype]
    tailcall RecMap $ndims $command $ndlist {*}$args
}

proc ::tda::ndlist::RecMap {ndims command ndlist args} {
    if {$ndims == 1} {
        tailcall Map $command $ndlist {*}$args
    }
    incr ndims -1
    lmap ndrow $ndlist {
        uplevel 1 [list ::tda::ndlist::RecMap $ndims $command $ndrow {*}$args]
    }
}

proc ::tda::ndlist::Map {command ndlist args} {
    lmap value $ndlist {
        uplevel 1 [linsert $command end $value {*}$args]
    }
}

proc ::tda::ndlist::mmap {command matrix args} {
    tailcall nmap 2D $command $matrix {*}$args
}
proc ::tda::ndlist::vmap {command vector args} {
    tailcall nmap 1D $command $vector {*}$args
}
proc ::tda::ndlist::rmap {command matrix args} {
    tailcall nmap 1D $command $matrix {*}$args
}
proc ::tda::ndlist::cmap {command matrix args} {
    tailcall nmap 1D $command [transpose $matrix] {*}$args
}

# nfor --
# 
# Loop over ndlists. Returns new ndlist like lmap.
# Calling "continue" will skip elements at the lowest level.
# Calling "break" will exit the entire loop.
# Note that the resulting ndlist may not be a proper ndlist if "continue" or 
# "break" are called.
#
# Syntax:
# nfor <$ndtype> $dims $body
# nfor $ndtype $varName $ndlist <$varName $ndlist ...> $body
# 
# Arguments:
# ndtype:       Number of dimensions (e.g. 1D, 2D, etc.)
# varName:      Variable name to iterate with
# ndlist:       ndlist to iterate over
# body:         Body to iterate with

proc ::tda::ndlist::nfor {args} {
    variable nfor_i; # array
    variable nfor_break 0; # variable to pass break with
    
    # Check arity
    if {[llength $args] == 0 || ([llength $args] > 3 && [llength $args]%2)} {
        return -code error "wrong # args: should be \"nfor ?ndtype? dims body\"\
                or \"nfor ndtype varName ndlist ?varName ndlist ...? body\""
    }
    
    # Save old indices and initialize new
    set old_i [array get nfor_i]
    array unset nfor_i
    try { # Try to perform map, and regardless, restore old indices
        if {[llength $args] == 2} {
            # Basic case, dynamic dimension determination
            lassign $args dims body
            set ndims [llength $dims]
            if {$ndims == 0} {
                return [uplevel 1 $body]
            }
            return [SingleFor $ndims [nrepeat {*}$dims ""] $body]
        } elseif {[llength $args] == 3} {
            # Basic case, with optional dimension qualifier
            lassign $args ndtype dims body
            set ndims [InterpretNDType $ndtype]
            if {[llength $dims] != $ndims} {
                return -code error "expected $ndims dimensions"
            }
            if {$ndims == 0} {
                return [uplevel 1 $body]
            }
            return [SingleFor $ndims [nrepeat {*}$dims ""] $body]
        } elseif {[llength $args] == 4} {
            # Loop over a single ndlist (simpler case)
            lassign $args ndtype varName ndlist body
            set ndims [InterpretNDType $ndtype]
            # Create link variable for SingleMap
            upvar 1 $varName x
            # Scalar case
            if {$ndims == 0} {
                set x $ndlist
                return [uplevel 1 $body]
            }
            return [SingleFor $ndims $ndlist $body]
        } else {
            # Loop over multiple ndlists
            set ndtype [lindex $args 0]
            set mapping [dict get [lrange $args 1 end-1]]
            set body [lindex $args end]
            set ndims [InterpretNDType $ndtype]
            # Unzip varMap to varNames and ndlists
            set varNames ""
            set ndlists ""
            foreach {varName ndlist} $mapping {
                lappend varNames $varName
                lappend ndlists $ndlist
            }
            # Tile ndlists to combined dimensions
            set cdims [GetCombinedSize $ndims {*}$ndlists]
            set ndlists [lmap ndlist $ndlists {NTile $ndlist {*}$cdims}]
            # Create linkVars for MultiMap
            set i 0
            set linkVars ""
            foreach varName $varNames ndlist $ndlists {
                upvar 1 $varName x$i
                lappend linkVars x$i
                incr i
            }
            # Scalar case
            if {$ndims == 0} {
                lassign $ndlists {*}$linkVars
                return [uplevel 1 $body]
            }
            return [MultiFor $ndims $linkVars $ndlists $body]
        }
    } finally {
        # Restore previous indices
        array unset nfor_i
        array set nfor_i $old_i
    }
}
proc ::tda::ndlist::mfor {args} {
    tailcall nfor 2D {*}$args
}
proc ::tda::ndlist::vfor {args} {
    tailcall nfor 1D {*}$args
}

# SingleFor --
#
# Private procedure to perform a single loop over ndlist
#
# Arguments:
# ndims:        Number of dimensions of ndlist
# ndlist:       ndlist to loop over
# body:         Body to evaluate in caller's caller.
# dim:          Recursion variable. Initializes as zero. (depth)

proc ::tda::ndlist::SingleFor {ndims ndlist body {dim 0}} {
    variable nfor_i
    variable nfor_break
    set nfor_i($dim) -1
    if {$ndims == 1} {
        # Base case
        set result [uplevel 1 [list lmap x $ndlist "
            incr nfor_i($dim)
            uplevel 1 [list $body]
        "]]
        # Check for break
        if {$nfor_i($dim) != [llength $ndlist] - 1} {
            set nfor_break 1
        }
        return $result
    } 
    # Recursion case
    tailcall lmap x $ndlist "
        incr nfor_i($dim)
        if {\$nfor_break} {break}
        SingleFor [incr ndims -1] \$x [list $body] [incr dim]
    "
}

# MultiFor --
#
# Used for when there are multiple ndlists.
# 
# Arguments:
# ndims:        Number of dimensions at the current recursion level.
# linkVars:     Variables in caller that link to caller's caller.
# ndlists:      Lists to iterate over.
# body:         Body to evaluate in caller's caller.
# dim:          Recursion variable. Initializes as zero. (depth)

proc ::tda::ndlist::MultiFor {ndims linkVars ndlists body {dim 0}} {
    variable nfor_i
    variable nfor_break
    # Create link-value mapping
    set linkMap ""; # mapping of link vars to ndlists
    foreach linkVar $linkVars ndlist $ndlists {
        lappend linkMap $linkVar $ndlist
    }
    # Initialize index
    set nfor_i($dim) -1
    # Base case
    if {$ndims == 1} {
        set result [uplevel 1 [list lmap {*}$linkMap "
            incr nfor_i($dim)
            uplevel 1 [list $body]
        "]]
        # Check for break
        if {$nfor_i($dim) != [llength $ndlist] - 1} {
            set nfor_break 1
        }
        return $result
    }
    # Recursion case
    set linkRef ""; # list of references to link variables
    foreach linkVar $linkVars {
        append linkRef "\$$linkVar "
    }
    tailcall lmap {*}$linkMap "
        incr nfor_i($dim)
        if {\$nfor_break} {break}
        MultiFor [incr ndims -1] [list $linkVars] \[list $linkRef\] \
                [list $body] [incr dim]
    "
}

# i, j, k --
#
# Access nfor indices (also works with nexpr)

proc ::tda::ndlist::i {{dim 0}} {
    variable nfor_i
    return $nfor_i($dim)
}
proc ::tda::ndlist::j {} {i 1}
proc ::tda::ndlist::k {} {i 2}

# nexpr --
# 
# Create a new ndlist based on element-wise operations (variant of nfor)
#
# Syntax:
# nexpr $ndtype $varName $ndlist <$varName $ndlist ...> $expr
# 
# Arguments:
# ndtype:       Type of ndlist (e.g. 1D, 2D, etc.)
# varName:      Variable name to use in expresssion
# ndlist:       ndlist to iterate over
# expr:         Expression to evaluate

proc ::tda::ndlist::nexpr {ndtype args} {
    # Check arity
    if {[llength $args]%2 != 1 || [llength $args] == 1} {
        return -code error "wrong # args: should be \"nexpr ndtype \
                varName ndlist ?varName ndlist ...? expr\""
    }
    # Call nmap, with expression in-place of body
    set varMap [lrange $args 0 end-1]
    set expr [lindex $args end]
    tailcall nfor $ndtype {*}$varMap [list expr $expr]
}
proc ::tda::ndlist::mexpr {args} {
    tailcall nexpr 2D {*}$args
}
proc ::tda::ndlist::vexpr {args} {
    tailcall nexpr 1D {*}$args
}
    
# GetCombinedSize --
# 
# Get combined size for combining ndlists (in nexpr)
#
# Arguments:
# ndims:            Number of dimensions in each ndlist
# ndlists:          ndlists to get combined dimensions of (for tiling)

proc ::tda::ndlist::GetCombinedSize {ndims args} {
    set cdims [lrepeat $ndims 1]; # Combined dimensions
    foreach ndlist $args {
        set dims [GetDims $ndims $ndlist]
        set cdims [lmap cdim $cdims dim $dims {
            if {$cdim == 1} {
                set cdim $dim
            } elseif {$dim != 1 && $dim != $cdim} {
                return -code error "incompatible dimensions"
            }
            set cdim
        }]
    }
    return $cdims
}

# nop --
#
# Simple math operations on ndlists. Faster than nexpr for simple stuff.
#
# Syntax:
# nop $ndtype $op $ndlist
# nop $ndtype $ndlist $op $scalar
# nop $ndtype $ndlist1 .$op $ndlist1
#
# Arguments:
# ndtype:       Number of dimensions (e.g. 1D, 2D, etc.)
# op:           Valid mathop
# ndlist:       Compatible ndlists
# scalar:       Scalar to perform mathop with

# Matrix examples:
# nop 2D / $matrix ; # Performs reciprocal
# nop 2D - $matrix; # Negates values
# nop 2D ! $matrix; # Boolean negation
# nop 2D $matrix + 5; # Adds 5 to each matrix element
# nop 2D 2 ./ $matrix; # Performs 2 divided by each matrix element
# nop 2D $matrix ** 2; # Squares entire matrix
# nop 2D $A .- $B; # Element-wise subtraction

proc ::tda::ndlist::nop {ndtype args} {
    set ndims [InterpretNDType $ndtype]
    # Switch for arity
    if {[llength $args] == 2} {
        # Self-operation
        lassign $args op ndlist
        # Scalar case
        if {$ndims == 0} {
            return [::tcl::mathop::$op $ndlist]
        }
        return [RecSelfOp $ndims $op $ndlist]
    } elseif {[llength $args] == 3} {
        if {[string index [lindex $args 1] 0] eq "."} {
            # Element-wise operation
            lassign $args ndlist1 op ndlist2
            set op [string range $op 1 end]
            # Scalar case
            if {$ndims == 0} {
                return [::tcl::mathop::$op $ndlist1 $ndlist2]
            }
            # Get combined size and conform ndlists.
            set cdims [GetCombinedSize $ndims $ndlist1 $ndlist2]
            set ndlist1 [NTile $ndlist1 {*}$cdims]
            set ndlist2 [NTile $ndlist2 {*}$cdims]
            return [RecElementWiseOp $ndims $ndlist1 $op $ndlist2]
        } else {
            # Scalar operation
            lassign $args ndlist op scalar
            # Scalar case
            if {$ndims == 0} {
                return [::tcl::mathop::$op $ndlist $scalar]
            }
            return [RecScalarOp $ndims $ndlist $op $scalar]
        }
    } else {
        return -code error "wrong # args: should be \"nop ndims op ndlist\",\
                \"nop ndims ndlist op value\", or\
                \"nop ndims ndlist1 .op ndlist2\""
    }
}

proc ::tda::ndlist::mop {args} {
    tailcall nop 2D {*}$args
}
proc ::tda::ndlist::vop {args} {
    tailcall nop 1D {*}$args
}

# SelfOp --
#
# Recursive handler for single-argument math operation (i.e. negation)

proc ::tda::ndlist::RecSelfOp {ndims op ndlist} {
    # Base case
    if {$ndims == 1} {
        return [SelfOp $op $ndlist]
    }
    # Recursion
    incr ndims -1
    lmap ndrow $ndlist {
        RecSelfOp $ndims $op $ndrow
    }
}

# SelfOp --
#
# Base case (list) for RecSelfOp

proc ::tda::ndlist::SelfOp {op list} {
    lmap value $list {
        ::tcl::mathop::$op $value
    }
}

# RecScalarOp --
#
# Perform operation with scalar and ndlist

proc ::tda::ndlist::RecScalarOp {ndims ndlist op scalar} {
    # Base case
    if {$ndims == 1} {
        return [ScalarOp $ndlist $op $scalar]
    }
    # Recursion
    incr ndims -1
    lmap ndrow $ndlist {
        RecScalarOp $ndims $ndrow $op $scalar
    }
}

# ScalarOp --
#
# Base case (list) for RecScalarOp

proc ::tda::ndlist::ScalarOp {list op scalar} {
    lmap value $list {
        ::tcl::mathop::$op $value $scalar
    }
}

# RecElementWiseOp --
# 
# Perform element-wise operation with ndlists

proc ::tda::ndlist::RecElementWiseOp {ndims ndlist1 op ndlist2} {
    # Base case
    if {$ndims == 1} {
       return [ElementWiseOp $ndlist1 $op $ndlist2]
    }
    # Recursion
    incr ndims -1
    lmap ndrow1 $ndlist1 ndrow2 $ndlist2 {
        RecElementWiseOp $ndims $ndrow1 $op $ndrow2
    }
}

# ElementWiseOp --
# 
# Base case for RecElementWiseOp

proc ::tda::ndlist::ElementWiseOp {list1 op list2} {
    lmap value1 $list1 value2 $list2 {
        ::tcl::mathop::$op $value1 $value2
    }
}

# Finally, provide the package
package provide tda::ndlist 0.1.0
