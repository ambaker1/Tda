# io.tcl
################################################################################
# File import and export, and datatype conversions

# Copyright (C) 2023 Alex Baker, ambaker1@mtu.edu
# All rights reserved. 

# See the file "LICENSE" in the top level directory for information on usage, 
# redistribution, and for a DISCLAIMER OF ALL WARRANTIES.
################################################################################

package require tda::tbl 0.1

# Define namespace
namespace eval ::tda::io {
    # Exported commands
    # General data import and export
    namespace export readFile; # Read a file
    namespace export putsFile; # Simplified writing to files (depreciated)
    namespace export writeFile; # Overwrite a file
    namespace export appendFile; # Append to a file
    
    # Special data import/export commands
    namespace export readMatrix; # Read a file to matrix
    namespace export writeMatrix; # Write a matrix to file
    namespace export readTable; # Read a file to table
    namespace export writeTable; # Write a table to file
    
    # Data conversion utilities
    namespace export txt2mat mat2txt; # Space-delimited <-> Matrix
    namespace export csv2mat mat2csv; # CSV <-> Matrix
    namespace export tbl2mat mat2tbl; # Table <-> Matrix
    namespace export txt2csv csv2txt; # Space-delimited <-> CSV
    namespace export csv2tbl tbl2csv; # CSV <-> Table
    namespace export tbl2txt txt2tbl; # Table <-> Space-delimited
}

# Data import and export functions
################################################################################
# Reading and writing of files in Tcl is done through opening a file, printing
# to that file, and closing the file. 
# Likewise, reading a file is done through opening a file, reading the file, 
# and then closing the file.
# The functions "readFile" and "putsFile" simplify this process for 
# importing or exporting entire contents of a file.
# Variable values can also be saved with the "saveVars" command, or 
# data can be copied from variables from Tk widget in "viewVars".
################################################################################

# readFile --
#
# Loads data from file, ignoring last newline
#
# Arguments:
# options:          fconfigure options
# -newline:         Read the last newline (default ignores last newline)
# filename:         File to read from

proc ::tda::io::readFile {args} {
    # Check arity
    if {[llength $args] == 0} {
        return -code error "wrong # args: should be \"readFile\
                ?option value ...? ?-newline? filename\""
    }
    # Parse optional arguments
    set options [lrange $args 0 end-1]
    set nonewline true
    if {[llength $options]%2 == 1} {
        if {[lindex $options end] ne "-newline"} {
            return -code error "wrong # args: should be \"readFile\
                    ?option value ...? ?-newline? filename\""
        }
        set nonewline false
        set options [lrange $options 0 end-1]; # trim -newline
    }
    set filename [lindex $args end]
    set options [lrange $args 0 end-1]
    # Try to open file for reading, and configure as specified
    set fid [open $filename r]
    fconfigure $fid {*}$options
    # Read data from file
    if {$nonewline} {
        set data [read -nonewline $fid]
    } else {
        set data [read $fid]
    }
    close $fid
    return $data
}

# putsFile --
#
# Saves data to file, overwriting previous contents (depreciated)
#
# Arguments:
# filename:         File to write to
# data:             Data to write

proc ::tda::io::putsFile {filename data} {
    WriteToFile $filename $data w 0
}

# writeFile --
# 
# Overwrite file with data, with additional options
#
# Arguments:
# option value ... :    fconfigure options
# -nonewline:           Option to not write a final newline
# filename:             File to write to
# data:                 Data to write to file

proc ::tda::io::writeFile {args} {
    # Check arity
    if {[llength $args] < 2} {
        return -code error "wrong # args: should be \"writeFile\
                ?option value ...? ?-nonewline? filename data\""
    }
    # Parse optional arguments
    set options [lrange $args 0 end-2]
    set nonewline false
    if {[llength $options]%2 == 1} {
        if {[lindex $options end] ne "-nonewline"} {
            return -code error "wrong # args: should be \"writeFile\
                    ?option value ...? ?-nonewline? filename data\""
        }
        set nonewline true
        set options [lrange $options 0 end-1]; # trim -nonewline
    }
    set filename [lindex $args end-1]
    set data [lindex $args end]
    WriteToFile $filename $data w $nonewline {*}$options
}

# appendFile --
# 
# Append file with data, with additional options
#
# Arguments:
# option value ... :    fconfigure options
# -nonewline:           Option to not write a final newline
# filename:             File to write to
# data:                 Data to write to file

proc ::tda::io::appendFile {args} {
    # Check arity
    if {[llength $args] < 2} {
        return -code error "wrong # args: should be \"appendFile\
                ?option value ...? ?-nonewline? filename data\""
    }
    # Parse optional arguments
    set options [lrange $args 0 end-2]
    set nonewline false
    if {[llength $options]%2 == 1} {
        if {[lindex $options end] ne "-nonewline"} {
            return -code error "wrong # args: should be \"appendFile\
                    ?option value ...? ?-nonewline? filename data\""
        }
        set nonewline true
        set options [lrange $options 0 end-1]; # trim -nonewline
    }
    set filename [lindex $args end-1]
    set data [lindex $args end]
    WriteToFile $filename $data a $nonewline {*}$options
}

# WriteToFile --
#
# Private procedure called by putsFile, writeFile, and appendFile
# Creates directory if it does not exist
#
# Arguments:
# filename:     File to write
# data:         Data to write to file
# access:       Access mode (w or a)
# nonewline:    True or false, whether to include -nonewline flag
# args:         fconfigure settings

proc ::tda::io::WriteToFile {filename data access nonewline args} {
    file mkdir [file dirname $filename]
    set fid [open $filename $access]
    fconfigure $fid {*}$args
    # Write data to file
    if {$nonewline} {
        puts -nonewline $fid $data
    } else {
        puts $fid $data
    }
    close $fid
    return
}

# Short-hand commands for reading/writing tablular and matrix data from/to file

# readMatrix --
#
# Read a file to matrix
#
# Arguments:
# options:          fconfigure options
# -newline:         Read the last newline (default ignores last newline)
# filename:         File to read from. If ".csv", converts from CSV

proc ::tda::io::readMatrix {args} {
    set filename [lindex $args end]
    if {[file extension $filename] eq ".csv"} {
        csv2mat [readFile {*}$args]
    } else {
        txt2mat [readFile {*}$args]
    }
}

# writeMatrix --
#
# Write a matrix to file
#
# Arguments:
# option value ... :    fconfigure options
# -nonewline:           Option to not write a final newline
# filename:             File to write to. If ".csv", writes to CSV
# matrix:               Matrix to write to file

proc ::tda::io::writeMatrix {args} {
    set filename [lindex $args end-1]
    if {[file extension $filename] eq ".csv"} {
        writeFile {*}[lrange $args 0 end-1] [mat2csv [lindex $args end]]
    } else {
        writeFile {*}[lrange $args 0 end-1] [mat2txt [lindex $args end]]
    }
}

# readTable --
# 
# Read a file to table
#
# Arguments:
# options:          fconfigure options
# -newline:         Read the last newline (default ignores last newline)
# filename:         File to read from. If ".csv", converts from CSV

proc ::tda::io::readTable {args} {
    set filename [lindex $args end]
    if {[file extension $filename] eq ".csv"} {
        csv2tbl [readFile {*}$args]
    } else {
        txt2tbl [readFile {*}$args]
    }
}

# writeTable --
#
# Write a table to file
#
# Arguments:
# option value ... :    fconfigure options
# -nonewline:           Option to not write a final newline
# filename:             File to write to. If ".csv", writes to CSV
# table:                Table to write to file

proc ::tda::io::writeTable {args} {
    set filename [lindex $args end-1]
    if {[file extension $filename] eq ".csv"} {
        writeFile {*}[lrange $args 0 end-1] [tbl2csv [lindex $args end]]
    } else {
        writeFile {*}[lrange $args 0 end-1] [tbl2txt [lindex $args end]]
    }
}

# Data Conversion
################################################################################
# txt: Space-delineated with newlines to separate rows (actually Tcl lists)
# csv: Comma-separated values, with newlines to separate rows.
# mat: List of rows, using Tcl lists. See ndlist module.
# tbl: Tabular data, using dictionaries. See table module.
# The base data type is matrix. So, all main conversion functions convert 
# between matrix and other types. Other conversion functions are derived.
################################################################################

# TrimMatrix --
# 
# Private procedure to trim matrix of header row and header column.
#
# Arguments:
# matrix:       Matrix to trim (or not)
# hRows:        Number of header rows
# hCols:        Number of header columns

proc ::tda::io::TrimMatrix {matrix hRows hCols} {
    if {$hRows > 0} {
        set matrix [lrange $matrix $hRows end]
    }
    if {$hCols > 0} {
        set matrix [lmap row $matrix {lrange $row $hCols end}]
    }
    return $matrix
}

# txt2mat --
#
# Convert from space-delimited text to matrix
# Newlines can be escaped inside curly braces
# Ignores blank lines
#
# Arguments:
#
# text:     Text to convert
# hRows:    Number of header rows to truncate. Default 0
# hCols:    Number of header columns to truncate. Default 0

proc ::tda::io::txt2mat {text {hRows 0} {hCols 0}} {
    set matrix ""
    set row ""
    foreach line [split $text \n] {
        # Add to row, and handle escaped newlines
        append row $line
        if {[string is list $row]} {
            lappend matrix $row
            set row ""
        } else {
            append row \n
        }
    }
    return [TrimMatrix $matrix $hRows $hCols]
}

# mat2txt --
#
# Convert from matrix to space-delimited text
#
# Arguments:
#
# matrix:       Matrix to convert
# hRows:        Number of header rows to truncate. Default 0
# hCols:        Number of header columns to truncate. Default 0

proc ::tda::io::mat2txt {matrix {hRows 0} {hCols 0}} {
    return [join [TrimMatrix $matrix $hRows $hCols] \n]
}

# csv2mat --
#
# Convert from comma-separated values to matrix
# Ignores blank lines
#
# Arguments:
#
# csv:          CSV string to convert
# hRows:        Number of header rows to truncate. Default 0
# hCols:        Number of header columns to truncate. Default 0

proc ::tda::io::csv2mat {csv {hRows 0} {hCols 0}} {
    # Initialize variables
    set matrix ""; # Output matrix
    set csvRow ""; # CSV-formatted row of data
    set val ""; # Value in matrix row
    
    # Split csv by newline and loop through lines
    foreach line [split $csv \n] {
        append csvRow $line
        # Check for escaped newline condition
        if {[regexp -all "\"" $csvRow] % 2} {
            # Odd number of quotes
            append csvRow \n
            continue
        }
        # Split csv row by comma and loop through items, creating matrix row
        set row ""; # Matrix row of data
        set blanks 0; # Number of blanks (ignore blank rows)
        foreach item [split $csvRow ,] {
            append val $item
            # Check for escaped comma condition
            if {[regexp -all "\"" $val] % 2} {
                # Odd number of quotes
                append val ,
                continue
            }
            # Check if escaped (commas, newlines, or quotes)
            if {[regexp "\"" $val]} {
                # Remove outer escaping quotes
                set val [string range $val 1 end-1]
                # Check for escaped quotes
                if {[regexp "\"" $val]} {
                    # Replace with normal quotes
                    set val [regsub -all "\"\"" $val "\""]
                }
            }
            if {$val eq ""} {
                incr blanks
            }
            # Add to row
            lappend row $val
            # Clear val
            set val ""
        }
        # Add to matrix
        lappend matrix $row
        # Clear csv row
        set csvRow ""
    }
    return [TrimMatrix $matrix $hRows $hCols]
}

# mat2csv --
#
# Convert from matrix to comma-separated values
#
# Arguments:
#
# matrix:       Matrix to convert
# hRows:        Number of header rows to truncate. Default 0
# hCols:        Number of header columns to truncate. Default 0

proc ::tda::io::mat2csv {matrix {hRows 0} {hCols 0}} {
    set csvTable ""
    # Loop through matrix rows
    foreach row [TrimMatrix $matrix $hRows $hCols] {
        set csvRow ""
        foreach val $row {
            # Perform escaping if required
            if {[string match "*\[\",\r\n\]*" $val]} {
                set val "\"[string map [list \" \"\"] $val]\""
            }
            lappend csvRow $val
        }
        lappend csvTable [join $csvRow ,]
    }
    return [join $csvTable \n]
}

# tbl2mat --
#
# Convert from table to matrix
#
# Arguments:
#
# table:        Table to convert
# fieldRow:     Include fields as first row in matrix. Default true
# keyColumn:    Include keys as first column in matrix. Default true

proc ::tda::io::tbl2mat {table {fieldRow 1} {keyColumn 1}} {
    # Get values (blanks for missing data)
    set keys [uplevel 1 $table keys]
    set fields [uplevel 1 $table fields]
    set matrix [uplevel 1 $table values]
    set keyname [uplevel 1 $table keyname]
    if {$keyColumn} {
        set matrix [lmap row $matrix key $keys {linsert $row 0 $key}]
        if {$fieldRow} {
            set matrix [linsert $matrix 0 [linsert $fields 0 $keyname]]
        }
    } elseif {$fieldRow} {
        set matrix [linsert $matrix 0 $fields]
    }
    
    return $matrix
}

# mat2tbl --
#
# Convert from matrix to table
#
# Arguments:
#
# matrix:       Matrix to convert
# fieldRow:     Use first row as fields. Default true
# keyColumn:    Use first column as keys. Default true

proc ::tda::io::mat2tbl {matrix {fieldRow 1} {keyColumn 1}} {
    # Create blank table
    set table [::tda::tbl::tdatbl new]

    # Trim matrix and get keys/fields
    if {$fieldRow} {
        set header [lindex $matrix 0]
        set matrix [lrange $matrix 1 end]
        if {$keyColumn} {
            $table define keyname [lindex $header 0]
            set fields [lrange $header 1 end]
        } else {
            set fields $header
        }
    }
    if {$keyColumn} {
        set keys [lmap row $matrix {lindex $row 0}]
        set matrix [lmap row $matrix {lrange $row 1 end}]
    }
    
    # Generate default keys and fields if required
    if {!$keyColumn} {
        # Generate default table keys (1 to n)
        set n [llength $matrix]
        set keys ""
        for {set i 1} {$i <= $n} {incr i} {
            lappend keys $i
        }
    }
    if {!$fieldRow} {
        # Generate default fields (A to Z, AA to AZ, etc.)
        set m [llength [lindex $matrix 0]]
        set alpha {A B C D E F G H I J K L M N O P Q R S T U V W X Y Z}
        set fields ""
        for {set i 0} {$i < $m} {incr i} {
            set j $i
            set field ""
            while {$j >= 0} {
                set field [string cat [lindex $alpha [expr {$j%26}]] $field]
                set j [expr {$j/26 - 1}]
            }
            lappend fields $field
        }
    }
    
    # Set data in table
    $table mset $keys $fields $matrix
    
    return $table
}

# Derived conversions 
proc ::tda::io::tbl2csv {table {fieldRow 1} {keyColumn 1}} {
    mat2csv [tbl2mat $table $fieldRow $keyColumn]
}
proc ::tda::io::csv2tbl {csv {fieldRow 1} {keyColumn 1}} {
    mat2tbl [csv2mat $csv] $fieldRow $keyColumn
}
proc ::tda::io::tbl2txt {table {fieldRow 1} {keyColumn 1}} {
    mat2txt [tbl2mat $table $fieldRow $keyColumn]
}
proc ::tda::io::txt2tbl {txt {fieldRow 1} {keyColumn 1}} {
    mat2tbl [txt2mat $txt] $fieldRow $keyColumn
}
proc ::tda::io::txt2csv {txt {hRows 0} {hCols 0}} {
    mat2csv [txt2mat $txt $hRows $hCols]
}
proc ::tda::io::csv2txt {csv {hRows 0} {hCols 0}} {
    mat2txt [csv2mat $csv $hRows $hCols]

# Import all exported command into parent package
namespace eval ::tda {
    namespace import -force io::*
    namespace export {*}[namespace eval io {namespace export}]
}

# Finally, provide the package
package provide tda::io 0.1.0
