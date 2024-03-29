# vis.tcl
################################################################################
# Data visualization

# Copyright (C) 2023 Alex Baker, ambaker1@mtu.edu
# All rights reserved. 

# See the file "LICENSE" in the top level directory for information on usage, 
# redistribution, and for a DISCLAIMER OF ALL WARRANTIES.
################################################################################

package require wob 1.0
package require tda::ndlist 0.1
package require tda::tbl 0.1
package require tda::io 0.1

# Define namespace
namespace eval ::tda::vis {
    variable figCount 0; # For figure number title
    namespace export viewMatrix; # Open up widget to view matrix
    namespace export viewTable; # Open up widget to view table
    namespace export plotXY; # Open up a widget for viewing data
}

# viewTable --
# 
# Create a wob widget for viewing a table contents. Copies to CSV format.
#
# Arguments:
# table:        Table to view
# title:        Title of widget (default "Table")

proc ::tda::vis::viewTable {table} {
    # Create widget for viewing table
    set widget [::wob::widget new "Table $table"]
    $widget eval {package require Tktable}
    $widget alias GetValue $table index
    $widget alias CopyCSV ::tda::mat2csv
    $widget set n [$table height]
    $widget set m [$table width]
    $widget eval {
        # Modify the clipboard function to copy correctly from table
        trace add execution clipboard leave TrimClipBoard
        proc TrimClipBoard {cmdString args} {
            if {[lindex $cmdString 1] eq "append"} {
                set clipboard [clipboard get]
                clipboard clear
                clipboard append [CopyCSV $clipboard] 
            }
        }
    
        # Create frame, scroll bar, and button
        frame .f -bd 2 -relief groove
        scrollbar .f.sbar -command {.f.tbl yview}
        
        # Create table (-state disabled prevents editing)
        table .f.tbl -rows [expr {$n + 1}] -cols [expr {$m + 1}] \
                -titlerows 1 -titlecols 1 -height 20 -width 10 \
                -yscrollcommand {.f.sbar set} -invertselected 1 \
                -command {GetValue [expr {%r - 1}] [expr {%c - 1}]} \
                -state disabled -wrap 1 -rowstretchmode unset \
                -colstretchmode all -selecttitle 1 -selectmode extended
        .f.tbl tag configure active -fg black
        .f.tbl height 0 1; # Height of title row 

        # Arrange widget
        grid .f -column 0 -row 0 -columnspan 2 -rowspan 1 -sticky nsew
        grid .f.tbl -column 0 -row 1 -columnspan 1 -rowspan 1 -sticky nsew
        grid .f.sbar -column 1 -row 1 -columnspan 1 -rowspan 1 -sticky ns
        grid columnconfigure . all -weight 1
        grid rowconfigure . all -weight 1
        grid columnconfigure .f .f.tbl -weight 1
        grid rowconfigure .f .f.tbl -weight 1
    }
    return $widget
}

# viewMatrix --
#
# Create a wob widget to view a matrix contents. Uses "viewTable".
# 
# Arguments:
# matrix:       Matrix to view

proc ::tda::vis::viewMatrix {matrix} {
    set table [::tda::mat2tbl $matrix 0 0]
    $table define keyname R 
    $table define fieldname C
    set widget [viewTable $table]
    $widget eval [list wm title . "Matrix"]
    $widget eval {.f.tbl configure -selecttitle 0}
    return $widget
}

# plotXY --
#
# Interactive display for viewing scatter plot data. 
# 
# Arguments:
# XY:           Matrix with first column as X, and the remainder as series.
# X Y1 Y2...:   X vector and Y vectors

proc ::tda::vis::plotXY {args} {
    variable screenWidth
    variable screenHeight
    # Get screen height and width from Tk in interpreter
    if {![info exists screenWidth] || ![info exists screenHeight]} {
        set child [interp create]
        $child eval {package require Tk}
        set screenWidth [$child eval {winfo screenwidth .}]
        set screenHeight [$child eval {winfo screenheight .}]  
        interp delete $child
    }
    set size [list [expr {$screenWidth/2}] [expr {$screenHeight/2}]]
    set fig [ScatterPlot new $size]
    # Switch for arity
    if {[llength $args] == 1} {
        set args [lassign $args XY] 
        set YList [lassign [::tda::ndlist::transpose $XY] X]
    } else {
        set YList [lassign $args X]
    }
    # Plot series
    foreach Y $YList {
        $fig plot $X $Y
    }
    return $fig
}

# ScatterPlot --
#
# Sub-class of widget for creating scatter plots
# Inspired from https://wiki.tcl-lang.org/page/A+little+function+plotter

oo::class create ::tda::vis::ScatterPlot {
    # Create a widget class
    superclass ::wob::widget
    constructor {{size {560 420}}} {
        incr ::tda::vis::figCount
        next "Figure $::tda::vis::figCount"
        # Initialize general figure variables
        my set size $size
        my set colormap {red blue green purple orange}
        
        # Initialize series-specific variables
        my Initialize
        
        # Set up widget
        my eval {
            # Plotting canvas
            lassign $size width height
            grid [canvas .c -background white -width $width -height $height \
                    -relief solid -borderwidth 1] -column 1 -row 0 \
                    -columnspan 3 -rowspan 2 -padx 5 -pady 5 -sticky nsew    
            
            # Axis labels
            grid [label .xmin -textvariable xMinTxt -anchor w -justify left] \
                    -column 1 -row 2 -sticky nw
            grid [label .xmax -textvariable xMaxTxt -anchor e -justify right] \
                    -column 2 -row 2 -columnspan 2 -sticky ne
            grid [label .ymin -textvariable yMinTxt -anchor n -justify right] \
                    -column 0 -row 1 -sticky se
            grid [label .ymax -textvariable yMaxTxt -anchor s -justify right] \
                    -column 0 -row 0 -sticky ne
                    
            # Data index scale
            grid [scale .s -command UpdateActivePoint -showvalue true \
                    -from 0 -to 1 -orient horizontal -sliderrelief raised \
                    -relief groove -borderwidth 2] -column 0 -row 3 \
                    -columnspan 4 -sticky nsew
            
            # Meta data
            grid [label .l0 -text "Series:" -anchor w -justify left] \
                    -column 0 -row 4 -sticky w
            grid [label .l1 -textvariable series -anchor w -justify left] \
                    -column 1 -row 4 -sticky w
            grid [label .l2 -text "Coords:" -anchor w -justify left] \
                    -column 2 -row 4 -sticky w
            grid [label .l3 -textvariable coordTxt -anchor w -justify left] \
                    -column 3 -row 4 -sticky w
            grid columnconfigure . .l3 -weight 1

            # Fix window size
            wm resizable . 0 0
            
            # Bind the mousewheel to cycle through series
            bind . <MouseWheel> {
                if {$nSeries == 0} {return}
                if {%D > 0} {
                    incr series 1
                } else {
                    incr series -1
                }
                SetSeries [expr {$series%%$nSeries}]
            }
            
            # SetSeries --
            # Define the active series and update marker
            proc SetSeries {index} {
                global nSeries series coordsList
                set series $index
                set n [expr {[llength [lindex $coordsList $series]]/2 - 1}]
                if {$n < [.s get]} {
                    .s set $n
                }
                .s configure -to $n
                UpdateActivePoint [.s get]
                return
            }
            
            # Create procedure to update active point from coords list
            proc UpdateActivePoint {i} {
                global nSeries series coordsList activePoint coordTxt
                if {$nSeries == 0} {return}
                set x0 [lindex $coordsList $series [expr {$i*2}]]
                set y0 [lindex $coordsList $series [expr {$i*2 + 1}]]
                set coordTxt [format "%.6g, %.6g" $x0 $y0]
                .c coords $activePoint [PointCoords $x0 $y0]
            }
            
            # PointCoords --
            # Given center coords, get list of outer canvas coords for point
            proc PointCoords {x y} {
                lassign [Coord2Canvas $x $y] x0 y0
                set x1 [expr {$x0 - 3}]
                set x2 [expr {$x0 + 3}]
                set y1 [expr {$y0 - 3}]
                set y2 [expr {$y0 + 3}]
                return [list $x1 $y1 $x2 $y2]
            }
            
            # Coord2Canvas --
            # Create procedure to convert plot coords to canvas coords
            proc Coord2Canvas {x y} {
                global xFactor yFactor xOffset yOffset
                return [list [expr {$x * $xFactor + $xOffset}] \
                        [expr {$y * $yFactor + $yOffset}]]
            }
            
            # Bind left arrow key to move marker to the left through data
            bind . <Key-Left> {
                if {$nSeries == 0} {return}                
                .s set [expr {max([.s get] - 1, 0)}]
            }
            bind . <Shift-Key-Left> {
                if {$nSeries == 0} {return}     
                .s set [expr {max([.s get] - 10, 0)}]
            }
            
            # Bind right arrow key to move marker to the right through data
            bind . <Key-Right> {
                if {$nSeries == 0} {return}
                .s set [expr {min([.s get] + 1,[.s cget -to])}]
            }
            bind . <Shift-Key-Right> {
                if {$nSeries == 0} {return}
                .s set [expr {min([.s get] + 10,[.s cget -to])}]
            }
        }
    }
    
    # $fig clear --
    #
    # Clear the figure canvas
    
    method clear {} {
        my eval .c delete all
        my Initialize
        my eval .s set 0
        my eval .s configure -to 0
    }
    
    # Initialize --
    #
    # Initialize all plotting variables
    
    method Initialize {} {
        my set nSeries 0; # Number of plotted series
        my set series ""; # Index of active series
        my set coordTxt ""; # Text to display coordinates of active point
        my set coordsList ""; # List of coords for each series
        my set optionsList ""; # List of line options for each series
        my set idList ""; # List of series widget IDs for advanced users
        # Data limits
        my set xMinData Inf
        my set xMaxData -Inf
        my set yMinData Inf
        my set yMaxData -Inf
        # Plot limit type (auto or user)
        my set xMinType auto
        my set xMaxType auto
        my set yMinType auto
        my set yMaxType auto
        # Plot range
        my set xMinPlot -1.0
        my set xMaxPlot 1.0
        my set yMinPlot -1.0
        my set yMaxPlot 1.0
        # Plot range text
        my set xMinTxt -1
        my set xMaxTxt 1
        my set yMinTxt -1
        my set yMaxTxt 1
    }
    
    # $fig xlim/ylim --
    #
    # Define the limits of a plot (xMin, xMax, yMin, yMax). Blank for auto
    # Redraw the plot
    
    method xlim {xMin xMax} {
        if {$xMin eq ""} {
            my set xMinType "auto"
        } else {
            my set xMinType "user"
            my set xMinPlot $xMin
        }
        if {$xMax eq ""} {
            my set xMaxType "auto"
        } else {     
            my set xMaxType "user"
            my set xMaxPlot $xMax
        }
        my Draw
    }
    method ylim {yMin yMax} {
        if {$yMin eq ""} {
            my set yMinType "auto"
        } else {
            my set yMinType "user"
            my set yMinPlot $yMin
        }
        if {$yMax eq ""} {
            my set yMaxType "auto"
        } else {     
            my set yMaxType "user"
            my set yMaxPlot $yMax
        }
        my Draw
    }
    
    # $fig plot --
    #
    # Add an X-Y series to the figure
    #
    # Arguments:
    # X:            Independent variable (vector)
    # Y:            Dependent variable (vector)
    # args:         key value options. Currently just for line style.
    
    method plot {X Y args} {
        if {[llength $X] != [llength $Y]} {
            return -code error "Vectors must be equal length"
        }
        foreach x $X y $Y {
            lappend coords $x $y
        }
        if {[llength $coords] == 0} {
            return -code error "Must supply at least one point"
        }
        my set coords $coords
        my set options $args
        my eval {
            # Add series to lists
            incr nSeries
            lappend coordsList $coords
            lappend optionsList $options
            
            # Update data bounds and range
            foreach {x y} $coords {
                if {$x < $xMinData} {
                    set xMinData $x
                } 
                if {$x > $xMaxData} {
                    set xMaxData $x
                }
                if {$y < $yMinData} {
                    set yMinData $y
                }
                if {$y > $yMaxData} {
                    set yMaxData $y
                }
            }
            set xRangeData [expr {$xMaxData - $xMinData}]
            set yRangeData [expr {$yMaxData - $yMinData}]
        }
        # Call draw method
        my Draw
        return [my get series]
    }
    
    # Draw --
    #
    # Draw the data on the canvas
    
    method Draw {} {
        my eval {
            if {$nSeries == 0} {return}
            # Clear canvas
            .c delete all
            
            # Determine plot bounds (auto adds 5%)
            if {$xMinType eq "auto"} {
                set xMinPlot [expr {$xMinData - 0.05*$xRangeData}]
            }
            if {$xMaxType eq "auto"} {
                set xMaxPlot [expr {$xMaxData + 0.05*$xRangeData}]
            }
            if {$yMinType eq "auto"} {
                set yMinPlot [expr {$yMinData - 0.05*$yRangeData}]
            }
            if {$yMaxType eq "auto"} {
                set yMaxPlot [expr {$yMaxData + 0.05*$yRangeData}]
            }
            set xRangePlot [expr {$xMaxPlot - $xMinPlot}]
            set yRangePlot [expr {$yMaxPlot - $yMinPlot}]
            
            
            # Draw axes
            .c create line 0 $yMinPlot 0 $yMaxPlot -fill "light grey"
            .c create line $xMinPlot 0 $xMaxPlot 0 -fill "light grey"
            
            # Draw lines
            set i 0
            set idList ""; # List of widget IDs
            foreach coords $coordsList options $optionsList {
                set color [lindex $colormap [expr {$i%[llength $colormap]}]]
                lappend idList [.c create line $coords -fill $color {*}$options]
                incr i
            }
            
            # Normalize plot to canvas coordinates
            set xFactor [expr {[.c cget -width]/$xRangePlot}]
            set yFactor [expr {-[.c cget -height]/$yRangePlot}]
            set xOffset [expr {-$xMinPlot*$xFactor}]
            set yOffset [expr {-$yMaxPlot*$yFactor}]
            .c scale all 0 0 $xFactor $yFactor
            .c move all $xOffset $yOffset
            
            # Update bound labels
            set xMinTxt [format %.3g $xMinPlot]
            set xMaxTxt [format %.3g $xMaxPlot]
            set yMinTxt [format %.3g $yMinPlot]
            set yMaxTxt [format %.3g $yMaxPlot]
            
            # Create active point marker
            set activePoint [.c create rectangle 0 0 0 0 -width 2]
            SetSeries [expr {$nSeries - 1}]
        }
    }
}

# Import all exported command into parent package
namespace eval ::tda {
    namespace import -force vis::*
    namespace export {*}[namespace eval vis {namespace export}]
}

# Finally, provide the package
package provide tda::vis 0.1.2
