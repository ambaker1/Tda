# tbl.tcl
################################################################################
# Constant-time tabular data format, using TclOO and Tcl dictionaries.

# Copyright (C) 2023 Alex Baker, ambaker1@mtu.edu
# All rights reserved. 

# See the file "LICENSE" in the top level directory for information on usage, 
# redistribution, and for a DISCLAIMER OF ALL WARRANTIES.
################################################################################

# Define namespace
namespace eval ::tda::tbl {
    # Table object class
    namespace export tbl
}

# IsUnique --
# Check if a list is unique
proc ::tda::tbl::IsUnique {list} {
    set map ""
    foreach item $list {
        if {[dict exists $map $item]} {
            return 0
        }
        dict set map $item ""
    }
    return 1
}

# NormalizeIndex --
# Normalize an end-integer style index
proc ::tda::tbl::NormalizeIndex {n index} {
    expr [string map [list end [expr {$n - 1}]] $index]
}

# Definition of the table class and its methods:
oo::class create ::tda::tbl::tbl {
    # Variables used in all methods
    variable keys keymap keyname fields fieldmap fieldname data
    
    # Constructor - called by "tbl new" and "tbl create"
    constructor {args} {
        # Initialize table variables
        set keys ""; # Ordered list of keys
        set keymap ""; # dictionary of keys and indices
        set keyname key; # Name of keys (first column name)
        set fields ""; # Ordered list of fields
        set fieldmap ""; # Dictionary of fields and indices
        set fieldname field; # Name of fields
        set data ""; # Double-nested dictionary of table data
        my define {*}$args
        return
    }
    
    # $tblObj --
    #
    # Calling the table object without any arguments will just return properties
    
    method unknown {args} {
        if {[llength $args] == 0} {
            return [my properties]
        }
        # Fall through to default processing otherwise
        next {*}$args
    }
    unexport unknown

    # $tblObj copy --
    #
    # Shorthand for copying a table object
    
    method copy {args} {
        uplevel 1 [list oo::copy [self] {*}$args]
    }
    
    # Table property definition
    ########################################################################
    
    # $tblObj define --
    # 
    # Define main table properties (everything that defines a table)
    # key-value input
    # 
    # Arguments:
    # option:       keyname, fieldname, keys, fields, or data
    # value:        corresponding values. For keys and fields, ignores dupes.
    
    method define {args} {
        # Check arity
        if {[llength $args] == 1} {
            set args [lindex $args 0]
        }
        if {[llength $args]%2 == 1} {
            return -code error "Incorrect number of arguments"
        }
        foreach {property value} $args {
            # Fill in metakeys
            switch $property {
                keyname { 
                    set keyname $value
                }
                fieldname {
                    set fieldname $value
                }
                keys {
                    # Ensure no duplicates
                    if {![::tda::tbl::IsUnique $value]} {
                        return -code error "Cannot have duplicate keys"
                    }
                    # Redefine keys and keymap
                    set keys $value
                    set keymap ""
                    set rid 0
                    foreach key $keys {
                        dict set keymap $key $rid
                        incr rid
                    }

                    # Filter data
                    foreach key [dict keys $data] {
                        if {![dict exists $keymap $key]} {
                            dict unset data $key
                        }
                    }
                    # Initialize entries
                    foreach key $keys {
                        if {![dict exists $data $key]} {
                            dict set data $key ""
                        }
                    }
                }
                fields {
                    # Ensure no duplicates
                    if {![::tda::tbl::IsUnique $value]} {
                        return -code error "Cannot have duplicate fields"
                    }
                    # Redefine fields and fieldmap
                    set fields $value
                    set fieldmap ""
                    set cid 0
                    foreach field $fields {
                        dict set fieldmap $field $cid
                        incr cid
                    }
                    
                    # Filter data
                    dict for {key rdict} $data {
                        foreach field [dict keys $rdict] {
                            if {![dict exists $fieldmap $field]} {
                                dict unset data $key $field
                            }
                        }
                    }
                }
                data {
                    # Overwrite data (adds any new keys/fields as well)
                    foreach key $keys {
                        dict set data $key ""
                    }
                    dict for {key rdict} $value {
                        my set $key {*}$rdict
                    }
                }
                default {
                    return -code error "Wrong option. Try \"keyname\",\
                            \"fieldname\", \"keys\", \"fields\", or \"data\""
                }
            }; # end switch
        }; # end foreach property value
        return
    }
    
    # Table property access
    ########################################################################
    
    # $tblObj properties --
    # 
    # Return a dictionary completely defining the table.
    
    method properties {} {
        return [dict create keyname $keyname fieldname $fieldname keys $keys \
                fields $fields data $data]
    }
    
    # $tblObj keyname/fieldname --
    # 
    # Access keyname/fieldname of table

    method keyname {} {
        return $keyname
    }
    
    method fieldname {} {
        return $fieldname
    }
    
    # $tblObj keys/fields --
    # 
    # Access table keys/fields with optional glob pattern
    # 
    # Arguments:
    # pattern:      Optional, default *
    
    method keys {{pattern *}} {
        if {$pattern eq {*}} {
            return $keys
        } else {
            return [lsearch -inline -all $keys $pattern]
        }
    }
    
    method fields {{pattern *}} {
        if {$pattern eq {*}} {
            return $fields
        } else {
            return [lsearch -inline -all $fields $pattern]
        }
    }
    
    # $tblObj data --
    #
    # Access dictionary form of data (ordered by entry), with option for key
    #
    # Arguments:
    # key:          Optional, specify key
    
    # $tblObj data <$key>
    
    method data {args} {
        if {[llength $args] == 0} {
            return $data
        } elseif {[llength $args] == 1} {
            set key [lindex $args 0]
            if {[dict exists $keymap $key]} {
                return [dict get $data $key]
            } else {
                return -code error "Unknown key \"$key\""
            }
        } else {
            return -code error "Incorrect number of arguments"
        }
    }
    
    # Derived table properties
    ########################################################################
    
    # $tblObj values --
    #
    # Get matrix of values (alias for mget with all keys and fields)
    
    method values {} {my mget}
    
    # $tblObj shape --
    #
    # Get shape of table (number of keys and fields)
    
    method shape {{dim ""}} {
        switch $dim {
            "" {list [my height] [my width]}
            0 {my height}
            1 {my width}
            default {return -code error "dim must be blank, 0, or 1"}
        }
    }
    
    # $tblObj height/width --
    #
    # Number of keys/fields in table
    
    method height {} {
        return [llength $keys]
    }
    
    method width {} {
        return [llength $fields]
    }
    
    # $tblObj exists --
    #
    # Check if key/field or key/field pairing exists, using hashmaps
    # 
    # Arguments:
    # option:       key, field, or value
    # args:         $key for key, $field for field, and $key $field for value
    
    method exists {option args} {
        switch $option {
            key { # Check if key exists
                if {[llength $args] != 1} {
                    return -code error "Incorrect number of arguments"
                }
                return [dict exists $keymap [lindex $args 0]]
            }
            field { # Check if field exists
                if {[llength $args] != 1} {
                    return -code error "Incorrect number of arguments"
                }
                return [dict exists $fieldmap [lindex $args 0]]
            }
            value { # Check if key/field pairing exists in data
                if {[llength $args] != 2} {
                    return -code error "Incorrect number of arguments"
                }
                return [dict exists $data {*}$args]
            }
            default {
                return -code error "Incorrect option. Try key, field, or value"
            }
        }; # end switch option
    }
          
    # $tblObj find --
    # 
    # Find row/column index for a given key/field. Return -1 if not found.
    #
    # Arguments:
    # option:       "key" or "field"
    # value:        $key for key, $field for field
    
    method find {option value} {
        switch $option {
            key {
                set key $value
                if {[dict exists $keymap $key]} {
                    return [dict get $keymap $key]
                } else {
                    return -1
                }
            }
            field {
                set field $value
                if {[dict exists $fieldmap $field]} {
                    return [dict get $fieldmap $field]
                } else {
                    return -1
                }
            }
            default {
                return -code error "Unknown option. Try \"key\" or \"field\""
            }
        }
    }
    
    # $tblObj key/field --
    # 
    # Return the key/field associated with row/column index
    # Returns error if out of range
    #
    # Arguments:
    # rid/cid:          Row/column ID (can use end-integer format)
    
    method key {rid} {
        set rid [::tda::tbl::NormalizeIndex [llength $keys] $rid]
        if {$rid < 0 || $rid >= [llength $keys]} {
            return -code error "Row ID out of range"
        }
        return [lindex $keys $rid]
    }
    
    method field {cid} {
        set cid [::tda::tbl::NormalizeIndex [llength $fields] $cid]
        if {$cid < 0 || $cid >= [llength $fields]} {
            return -code error "Column ID out of range"
        }
        return [lindex $fields $cid]
    }
    
    # Table entry
    ########################################################################
        
    # $tblObj set --
    #
    # Set single values in a table (single or dictionary form)
    #
    # Arguments:
    # key:          Key to set
    # args:         field value pairs

    method set {key args} {
        # Check arity
        if {[llength $args] % 2 == 1} {
            return -code error "Incorrect number of arguments"
        }
        
        # Add keys and fields
        my add keys $key
        my add fields {*}[dict keys $args]
    
        # Add data
        dict for {field value} $args {
            # Handle blanks
            if {$value eq ""} {
                dict unset data $key $field
            } else {
                dict set data $key $field $value
            }; # end if blank
        }

        return
    }

    # $tblObj rset --
    #
    # Set entire row
    # 
    # Arguments:
    # key:          Key associated with row
    # row:          List of values (length must match table width, or be scalar)

    method rset {key row} {
        # Get input and target dimensions and check for error
        set m0 [llength $fields]
        set m1 [llength $row]
        if {$m1 == 0} {
            set type blank
        } elseif {$m1 == 1} {
            set value [lindex $row 0]
            if {$value eq ""} {
                set type blank
            } else {
                set type scalar
            }
        } elseif {$m1 == $m0} {
            set type values
        } else {
            return -code error "Inconsistent number of fields/columns"
        }
        
        # Add key
        my add keys $key
        
        # Switch for input type (blank, scalar, or values)
        switch $type {
            blank {
                dict set data $key ""
            }
            scalar {
                foreach field $fields {
                    dict set data $key $field $value
                }; # end foreach field
            }
            values {
                foreach value $row field $fields {
                    # Handle blanks
                    if {$value eq ""} {
                        dict unset data $key $field
                    } else {
                        dict set data $key $field $value
                    }; # end if blank
                }; # end foreach value/field
            }
        }; # end switch input type
            
        return
    }

    # $tblObj cset --
    #
    # Set entire column
    # 
    # Arguments:
    # field:        Field associated with column
    # column:       List of values (length must match height, or be scalar)

    method cset {field column} {
        # Get source and input dimensions and get input type
        set n0 [llength $keys]
        set n1 [llength $column]
        if {$n1 == 0} {
            set type blank
        } elseif {$n1 == 1} {
            set value [lindex $column 0]
            if {$value eq ""} {
                set type blank
            } else {
                set type scalar
            }
        } elseif {$n1 == $n0} {
            set type values
        } else {
            return -code error "Inconsistent number of keys/rows"
        }
        
        # Add to field list
        my add fields $field
        
        # Switch for input type (blank, scalar, or column)
        switch $type {
            blank {
                foreach key $keys {
                    dict unset data $key $field
                }; # end foreach value/field
            }
            scalar {
                foreach key $keys {
                    dict set data $key $field $value
                }; # end foreach key
            }
            values {
                foreach value $column key $keys {
                    # Handle blanks
                    if {$value eq ""} {
                        dict unset data $key $field
                    } else {
                        dict set data $key $field $value
                    }; # end if blank
                }; # end foreach value/field
            }
        }; # end switch input type
        
        return
    }

    # $tblObj mset --
    #
    # Set range of table
    # 
    # Arguments:
    # keys:         Keys associated with rows (default all)
    # field:        Fields associated with columns (default all)
    # matrix:       Matrix of values (dimensions must match table or be scalar)

    method mset {args} {
        # Check arity
        if {[llength $args] == 1} {
            # All keys and fields
            set matrix [lindex $args 0]
            set keyset $keys
            set fieldset $fields
        } elseif {[llength $args] == 3} {
            # Specified keys and fields (validate)
            lassign $args keyset fieldset matrix
        } else {
            return -code error "Incorrect number of arguments"
        }
        
        # Get source and input dimensions and get input type
        set n0 [llength $keyset]
        set m0 [llength $fieldset]
        set n1 [llength $matrix]
        set m1 [llength [lindex $matrix 0]]
        if {$n1 == 0 && $m1 == 0} {
            set type blank
        } elseif {$n1 == 1 && $m1 == 1} {
            set value [lindex $matrix 0 0]
            if {$value eq ""} {
                set type blank
            } else {
                set type scalar
            }
        } elseif {$n1 == $n0 && $m1 == $m0} {
            set type values
        } else {
            return -code error "Input must be 0x0, 1x1 or ${n0}x${m0}"
        }
                
        # Add to key/field lists
        my add keys {*}$keyset
        my add fields {*}$fieldset
        
        # Switch for input type (blank, scalar, or matrix)
        switch $type {
            blank {
                foreach key $keyset {
                    foreach field $fieldset {
                        dict unset data $key $field
                    }; # end foreach value/field
                }; # end foreach row/key
            }
            scalar {
                foreach key $keyset {
                    foreach field $fieldset {
                        dict set data $key $field $value
                    }; # end foreach value/field
                }; # end foreach row/key
            }
            values {
                foreach row $matrix key $keyset {
                    foreach value $row field $fieldset {
                        # Handle blanks
                        if {$value eq ""} {
                            dict unset data $key $field
                        } else {
                            dict set data $key $field $value
                        }; # end if blank
                    }; # end foreach value/field
                }; # end foreach row/key
            }
        }; # end switch input type

        return
    }
    
    # Table access
    ########################################################################
    
    # $tblObj get --
    # 
    # Get a value from a table
    # If a key/field pairing does not exist, returns blank.
    # Return error if a key or field does not exist
    #
    # Arguments:
    # key:          key to query
    # field:        field to query

    method get {key field} {
        if {[dict exists $data $key $field]} {
            return [dict get $data $key $field]
        } elseif {![dict exists $keymap $key]} {
            return -code error "Key \"$key\" does not exist"
        } elseif {![dict exists $fieldmap $field]} {
            return -code error "Field \"$field\" does not exist"
        } else {
            return ""
        }
    }
    
	# $tblObj index --
	#
	# Get a value from a table using numbered indices
	# 
	# Arguments:
	# rid:          row index
	# cid:          column index
    
    method index {rid cid} {
        my get [my key $rid] [my field $cid]
    }
    
    # $tblObj index2 --
    # 
    # Indexing, origin == 1. Zero will return keys and fields
    # Used in method "view" to get values for display
    
    method index2 {i j} {
        incr i -1
        incr j -1
        if {$i == -1} {
            if {$j == -1} {
                return "$keyname\\$fieldname"
            }
            return [my field $j]
        }
        if {$j == -1} {
            return [my key $i]
        }
        my index $i $j
    }

    # $tblObj rget --
    #
    # Get a list of row values
    #
    # Arguments:
    # key:          key to query

    method rget {key} {
        # Check key validity
        if {![dict exists $keymap $key]} {
            return -code error "Key \"$key\" does not exist"
        }
        # Build output values vector
        set row ""
        foreach field $fields {
            if {[dict exists $data $key $field]} {
                lappend row [dict get $data $key $field]
            } else {
                lappend row ""
            }
        }
        return $row
    }

    # $tblObj cget --
    #
    # Get a list of column values
    #
    # Arguments:
    # field:        field to query

    method cget {field} {
        # Check field validity
        if {![dict exists $fieldmap $field]} {
            return -code error "Field \"$field\" does not exist"
        }
        # Build output values vector
        set column ""
        foreach key $keys {
            if {[dict exists $data $key $field]} {
                lappend column [dict get $data $key $field]
            } else {
                lappend column ""
            }
        }
        return $column
    }

    # $tblObj mget --
    #
    # Get a matrix of table values 
    #
    # Arguments:
    # keys:         Keys to query (default all)
    # fields:       Fields to query (default all)

    method mget {args} {
        # Check arity
        if {[llength $args] == 0} {
            # All keys and fields
            set keyset $keys
            set fieldset $fields
        } elseif {[llength $args] == 2} {
            # Specified keys and fields (validate)
            lassign $args keyset fieldset
            foreach key $keyset {
                if {![dict exists $keymap $key]} {
                    return -code error "Key \"$key\" does not exist"
                }
            }
            foreach field $fieldset {
                if {![dict exists $fieldmap $field]} {
                    return -code error "Field \"$field\" does not exist"
                }
            }
        } else {
            return -code error "Incorrect number of arguments"
        }

        # Build output values matrix
        set matrix ""
        foreach key $keyset {
            # Build row
            set row ""
            foreach field $fieldset {
                if {[dict exists $data $key $field]} {
                    lappend row [dict get $data $key $field]
                } else {
                    lappend row ""
                }; # end if field exists
            }; # end foreach fields
            lappend matrix $row
        }
        return $matrix
    }
    
    # $tblObj expr --
    #
    # Perform a field expression, return list of values
    # 
    # Arguments:
    # fieldExpr:    Tcl expression, but with @ symbol for fields
    
    method expr {fieldExpr} {
        # Get mapping of fields in fieldExpr
        set exp {@\w+|@{(\\\{|\\\}|[^\\}{]|\\\\)*}}
        set fieldMap ""
        foreach {match submatch} [regexp -inline -all $exp $fieldExpr] {
            lappend fieldMap [join [string range $match 1 end]] $match
        }
        
        # Check validity of fields in field expression
        dict for {field match} $fieldMap {
            if {![dict exists $fieldmap $field] && $field ne $keyname} {
                return -code error "Field \"$field\" not in table"
            }
        }
        
        # Get values according to field expression
        set values ""
        foreach key $keys {
            # Perform regular expression substitution
            set subExpr $fieldExpr
            set valid 1
            foreach {field match} $fieldMap {
                # Fields get priority over keyname.
                if {[dict exists $data $key $field]} {
                    set subValue [dict get $data $key $field]
                } elseif {$field eq $keyname} {
                    # Keyname case
                    set subValue $key
                } else {
                    set valid 0
                    break
                }
                set subExpr [regsub $match $subExpr "{$subValue}"]
            }; # end foreach fieldmap pair
            if {$valid} {
                # Only add data if all required fields exist.
                lappend values [uplevel 1 [list expr $subExpr]]
            } else {
                lappend values ""
            }; # end if valid
        }; # end foreach key
        
        # Return values created by field expression
        return $values
    }
    
    # $tblObj fedit --
    #
    # Assign or edit a column based on field expression
    # 
    # Arguments:
    # field:        Field to edit or create
    # fieldExpr:    Tcl expression, but with @ symbol for fields
    
    method fedit {field fieldExpr} {
        my cset $field [uplevel 1 [list [self] expr $fieldExpr]]
        return
    }
    
    # $tblObj query --
    #
    # Get keys that match a specific criteria from field expression
    #
    # Arguments:
    # fieldExpr:        Field expression that results in a boolean value
    
    method query {fieldExpr} {
        return [lmap bool [uplevel 1 [list [self] expr $fieldExpr]] key $keys {
            if {$bool} {
                set key
            } else {
                continue
            }
        }]
    }
    
    # $tblObj filter --
    # 
    # Reduce a table based on query results
    #
    # Arguments:
    # fieldExpr:        Field expression that results in a boolean value
    
    method filter {fieldExpr} {
        my define keys [uplevel 1 [list [self] query $fieldExpr]]
        return
    }
    
    # $tblObj search --
    #
    # Find key or keys that match a specific criteria, using lsearch.
    # If -inline is selected, filters the table instead.
    # 
    # Arguments:
    # args:         Selected lsearch options. Use -- to signal end of options.         
    # field:        Field to search in. If omitted, will search in keys.
    # value:        Value to search for.
    
    method search {args} {
        # Interpret arguments
        set options ""
        set inline false
        set remArgs ""
        set optionCheck 1
        foreach arg $args {
            if {$optionCheck} {
                # Check valid options
                if {$arg in {
                    -exact
                    -glob
                    -regexp
                    -sorted
                    -all
                    -not
                    -ascii
                    -dictionary
                    -integer
                    -nocase
                    -real
                    -decreasing
                    -increasing
                    -bisect
                }} then {
                    lappend options $arg
                    continue
                } elseif {$arg eq "-inline"} {
                    set inline true
                    continue
                } else {
                    set optionCheck 0
                    if {$arg eq {--}} {
                        continue
                    }
                }; # end check option arg
            }; # end if checking for options
            lappend remArgs $arg
        }; # end foreach arg
        
        # Process value and field arguments
        switch [llength $remArgs] {
            1 {set value [lindex $remArgs 0]}
            2 {lassign $remArgs field value}
            default {return -code error "Incorrect number of arguments"}
        }; # end switch arity of remaining

        # Handle key search case
        if {![info exists field]} {
            # Filter by keys 
            return [lsearch {*}$options -inline $keys $value]
        }

        # Filter by field values
        if {![dict exists $fieldmap $field]} {
            return -code error "Field \"$field\" is not in table"
        }
        
        # Check whether to include blanks or not
        set includeBlanks [expr {
            ![catch {lsearch {*}$options {{}} $value} result] && $result == 0
        }]
        
        # Get search list
        set searchList [lmap key $keys {
            if {[dict exists $data $key $field]} {
                list $key [dict get $data $key $field]
            } elseif {$includeBlanks} {
                list $key {}
            } else {
                continue
            }
        }]; # end lmap key
        
        # Get matches and corresponding keys
        set matchList [lsearch {*}$options -index 1 -inline $searchList $value]
        if {{-all} in $options} {
            # Return key list
            set keys [lsearch -all -inline -subindices -index 0 $matchList *]
            if {$inline} {
                my define keys $keys
                return
            }
            return $keys
        } else {
            # Return key
            set key [lindex $matchList 0]
            if {$inline} {
                my define keys [list $key]
                return
            }
            return $key
        }
    }
    
    # $tblObj sort --
    # 
    # Sort a table, using lsort
    #
    # Arguments:
    # options:      Selected lsort options. Use -- to signal end of options.
    # args:         Fields to sort by
    
    method sort {args} {
        # Interpret arguments
        set options ""
        set fieldset ""
        set optionCheck 1
        foreach arg $args {
            if {$optionCheck} {
                # Check valid options
                if {$arg in {
                    -ascii
                    -dictionary
                    -integer
                    -real
                    -increasing
                    -decreasing
                    -nocase
                }} then {
                    lappend options $arg
                    continue
                } else {
                    set optionCheck 0
                    if {$arg eq "--"} {
                        continue
                    }
                }
            }
            lappend fieldset $arg
        }
    
        # Switch for sort type (keys vs fields)
        if {[llength $fieldset] == 0} {
            # Sort by keys
            set keys [lsort {*}$options $keys]
        } else {
            # Sort by field values
            foreach field $fieldset {
                # Check validity of field
                if {![dict exists $fieldmap $field]} {
                    return -code error "Field \"$field\" is not in table"
                }
                
                # Get column and blanks
                set cdict ""; # Column dictionary for existing values
                set blanks ""; # Keys for blank values
                foreach key $keys {
                    if {[dict exists $data $key $field]} {
                        dict set cdict $key [dict get $data $key $field]
                    } else {
                        lappend blanks $key
                    }
                }
                
                # Sort valid keys by values, and then add blanks
                set keys [concat [dict keys [lsort -stride 2 -index 1 \
                        {*}$options $cdict]] $blanks]
            }; # end foreach field
        }; # end if number of fields
        
        # Update key map
        set rid 0
        foreach key $keys {
            dict set keymap $key $rid
            incr rid
        }
    
        return
    }
    
    # $tblObj with --
    # 
    # Loops through table (row-wise), using dict with on the table data.
    # Missing data is represented by blanks. Setting a field to blank or 
    # unsetting the variable will unset the data.
    #
    # Arguments:
    # body:         Body to evaluate

    method with {body} {
        variable temp; # Temporary variable for dict with loop
        foreach key $keys {
            # Establish keyname variable (not upvar, cannot modify)
            uplevel 1 [list set $keyname $key]
            # Create temporary row dict with blanks
            set temp [dict get $data $key]
            foreach field $fields {
                if {![dict exists $temp $field]} {
                    dict set temp $field ""
                }
            }
            # Evaluate body, using dict with
            uplevel 1 [list dict with [self namespace]::temp $body]
            # Filter out blanks
            dict set data $key [dict filter $temp value ?*]
        }
        # Return nothing
        return
    }
    
    # $tblObj merge --
    # 
    # Add table data from other tables, merging the data. 
    # keyname and fieldname must be consistent to merge.
    # 
    # Arguments:
    # args:         Tables to merge into main table
    
    method merge {args} {
        # Check compatibility
        foreach tblObj $args {
            if {$keyname ne [uplevel 1 [list $tblObj keyname]]} {
                return -code error "Cannot merge tables - keyname conflict"
            }
            if {$fieldname ne [uplevel 1 [list $tblObj fieldname]]} {
                return -code error "Cannot merge tables - fieldname conflict"
            }
        }
        # Merge input tables
        foreach tblObj $args {
            # Add keys/fields
            my add keys {*}[uplevel 1 [list $tblObj keys]]
            my add fields {*}[uplevel 1 [list $tblObj fields]]
            # Merge data
            dict for {key rdict} [uplevel 1 [list $tblObj data]] {
                dict set data $key [dict merge [dict get $data $key] $rdict]
            }
        }
        return
    }
    
    # Table manipulation
    ########################################################################
    
    # $tblObj add --
    #
    # Add keys/fields to the table, appending to end, in "dict set" fashion.
    # Duplicates may be entered with no penalty.
    # 
    # Arguments:
    # option:       "keys" or "fields"
    # args:         Keys or fields
    
    method add {option args} {
        switch $option {
            keys {
                foreach key $args {
                    if {![dict exists $keymap $key]} {
                        dict set keymap $key [llength $keys]
                        lappend keys $key
                    }
                    # Ensure that data entries exist
                    if {![dict exists $data $key]} {
                        dict set data $key ""
                    }
                }
            }
            fields {
                foreach field $args {
                    if {![dict exists $fieldmap $field]} {
                        dict set fieldmap $field [llength $fields]
                        lappend fields $field
                    }
                }
            }
            default {
                return -code error "Unknown option. Try \"key\" or \"field\""
            }
        }
        return
    }
    
    # $tblObj remove --
    #
    # Remove keys/fields if they exist. Handles duplicates just fine.
    #
    # Arguments:
    # option:       "keys" or "fields"
    # value:        Keys or fields
    
    method remove {option args} {
        switch $option {
            keys {
                # Get keys to remove in order of index
                set ridmap ""
                foreach key $args {
                    if {[dict exists $keymap $key]} {
                        dict set ridmap $key [dict get $keymap $key]
                    }
                }
                # Switch for number of keys to remove
                if {[dict size $ridmap] == 0} {
                    return
                } elseif {[dict size $ridmap] > 1} {
                    set ridmap [lsort -integer -stride 2 -index 1 $ridmap]
                }   

                # Remove from keys and data (k-trick for performance)
                set count 0; # Count of removed values
                dict for {key rid} $ridmap {
                    incr rid -$count; # Adjust for removed elements
                    set keys [lreplace $keys[set keys ""] $rid $rid]
                    dict unset keymap $key
                    dict unset data $key
                    incr count
                }
                
                # Update keymap
                set rid [lindex $ridmap 1]; # minimum removed rid
                foreach key [lrange $keys $rid end] {
                    dict set keymap $key $rid
                    incr rid
                }
            }
            fields {
                # Get fields to remove in order of index
                set cidmap ""
                foreach field $args {
                    if {[dict exists $fieldmap $field]} {
                        dict set cidmap $field [dict get $fieldmap $field]
                    }
                }
                # Switch for number of keys to remove
                if {[dict size $cidmap] == 0} {
                    return
                } elseif {[dict size $cidmap] > 1} {
                    set cidmap [lsort -integer -stride 2 -index 1 $cidmap]
                }   
                
                # Remove from fields and data (k-trick for performance)
                set count 0; # Count of removed values
                dict for {field cid} $cidmap {
                    incr cid -$count; # Adjust for removed elements
                    set fields [lreplace $fields[set fields ""] $cid $cid]
                    dict unset fieldmap $field
                    dict for {key rdict} $data {
                        dict unset data $key $field
                    }
                    incr count
                }
                
                # Update fieldmap
                set cid [lindex $cidmap 1]; # minimum removed cid
                foreach field [lrange $fields $cid end] {
                    dict set fieldmap $field $cid
                    incr cid
                }
            }
            default {
                return -code error "Unknown option. Try \"keys\" or \"fields\""
            }
        }
        return
    }
    
    # $tblObj insert --
    # 
    # Insert keys/fields (must be unique, and no duplicates)
    #
    # Arguments:
    # option:       "keys" or "fields"
    # index:        Row or column ID (with end-integer notation)
    # args:         Keys or fields
    
    method insert {option index args} {
        switch $option {
            keys {
                # Ensure input keys are unique and new
                if {![::tda::tbl::IsUnique $args]} {
                    return -code error "Cannot have duplicate key inputs"
                }
                foreach key $args {
                    if {[dict exists $keymap $key]} {
                        return -code error "Key \"$key\" already exists"
                    }
                }
                # Convert index input to integer, and check
                set rid [::tda::tbl::NormalizeIndex [llength $keys] $index]
                if {$rid < 0 || $rid > [llength $keys]} {
                    return -code error "Row ID out of range"
                }
                # Insert keys (using k-trick for performance)
                set keys [linsert $keys[set keys ""] $rid {*}$args]
                # Update indices in key map
                foreach key [lrange $keys $rid end] {
                    dict set keymap $key $rid
                    incr rid
                }
                # Ensure that entries in data exist
                foreach key $args {
                    if {![dict exists $data $key]} {
                        dict set data $key ""
                    }
                }
            }
            fields {
                # Ensure input fields are unique and new
                if {![::tda::tbl::IsUnique $args]} {
                    return -code error "Cannot have duplicate field inputs"
                }
                foreach field $args {
                    if {[dict exists $fieldmap $field]} {
                        return -code error "Field \"$field\" already exists"
                    }
                }
                # Convert index input to integer, and check
                set cid [::tda::tbl::NormalizeIndex [llength $fields] $index]
                if {$cid < 0 || $cid > [llength $fields]} {
                    return -code error "Column ID out of range"
                }
                # Insert fields (using k-trick for performance)
                set fields [linsert $fields[set fields ""] $cid {*}$args]
                # Update indices in field map
                foreach field [lrange $fields $cid end] {
                    dict set fieldmap $field $cid
                    incr cid
                }
            }
            default {
                return -code error "Unknown option. Try \"keys\" or \"fields\""
            }
        }
        return
    }
      
    # $tblObj rename --
    #
    # Rename keys or fields in table
    #
    # Arguments:
    # option:       "keys" or "fields"
    # old:          List of old keys or fields
    # new:          List of new keys or fields

    method rename {option old new} {
        if {[llength $old] != [llength $new]} {
            return -code error "Old and new must match in length"
        }
        if {![::tda::tbl::IsUnique $old] || ![::tda::tbl::IsUnique $new]} {
            return -code error "Old and new must be unique"
        }
        switch $option {
            keys {
                # Get old rows (checks for error)
                set rows [lmap key $old {my rget $key}]
                
                # Update key list and map (requires two loops, incase of 
                # intersection between old and new lists)
                set rids ""
                foreach oldKey $old newKey $new {
                    set rid [dict get $keymap $oldKey]
                    lappend rids $rid
                    lset keys $rid $newKey
                    dict unset keymap $oldKey
                    dict unset data $oldKey
                }
                foreach newKey $new rid $rids row $rows {
                    dict set keymap $newKey $rid; # update in-place
                    my rset $newKey $row; # Re-add row
                }
            }
            fields {
                # Get old rows (checks for error)
                set columns [lmap field $old {my cget $field}]
                
                # Update field list and map (requires two loops, incase of 
                # intersection between old and new lists)
                set cids ""
                foreach oldField $old newField $new {
                    set cid [dict get $fieldmap $oldField]
                    lappend cids $cid
                    lset fields $cid $newField
                    dict unset fieldmap $oldField
                    dict for {key rdict} $data {
                        dict unset data $key $oldField
                    }
                }
                foreach newField $new cid $cids column $columns {
                    dict set fieldmap $newField $cid; # update in-place
                    my cset $newField $column; # Re-add column
                }
            }
            default {
                return -code error "Unknown option. Try \"keys\" or \"fields\""
            }
        }
        return
    }     

    # $tblObj mkkey --
    # 
    # Make a field the key (data loss possible)
    # If a field is empty for some keys, those keys will be lost. 
    # Additionally, if field values repeat, this will only take the last one.
    # Intended to be used with a field that is full and unique.
    # 
    # Arguments:
    # field:            Field to swap with key.
    
    method mkkey {field} {
        # Check validity of transfer
        if {[dict exists $fieldmap $keyname]} {
            return -code error "Keyname conflict with fields"
        }
        if {![dict exists $fieldmap $field]} {
            return -code error "Field \"$field\" does not exist"
        }
        
        # Swap keyname/field
        my cset $keyname $keys
        my cswap $keyname $field; # Moves field to end
        set keyname $field
        set fields [lrange $fields 0 end-1]
        dict unset fieldmap $field
        
        # Restructure data and key list
        set newData ""
        set newKeys ""
        foreach key $keys {
            if {[dict exists $data $key $field]} {
                set rdict [dict get $data $key]
                set newKey [dict get $rdict $field]
                dict set newData $newKey [dict remove $rdict $field]
                lappend newKeys $newKey
            }
        }
        set data $newData
        set keys $newKeys
        
        return
    }
    
    # $tblObj rmove/cmove --
    #
    # Move rows and columns
    # 
    # Arguments:
    # key/field:        Key or field to move
    # index:            Row/column ID to move to.
    
    method rmove {key index} {
        # Get source index, checking validity of key
        if {![dict exists $keymap $key]} {
            return -code error "Key \"$key\" not in table"
        }
        set i [dict get $keymap $key]
        # Convert target index input to integer, and check
        set j [::tda::tbl::NormalizeIndex [llength $keys] $index]
        if {$j < 0 || $j >= [llength $keys]} {
            return -code error "Target row ID out of range"
        }
        # Switch for move type
        if {$i < $j} {
            # Target index is beyond source
            set keys [concat [lrange $keys 0 $i-1] [lrange $keys $i+1 $j] \
                    [list $key] [lrange $keys $j+1 end]]
            set rid $i
        } elseif {$i > $j} {
            # Target index is below source
            set keys [concat [lrange $keys 0 $j-1] [list $key] \
                    [lrange $keys $j $i-1] [lrange $keys $i+1 end]]
            set rid $j
        } else {
            # Trivial case
            return
        }
        # Update keymap
        foreach key [lrange $keys $rid end] {
            dict set keymap $key $rid
            incr rid
        }
        return
    }
    
    method cmove {field index} {
        # Get source index, checking validity of field
        if {![dict exists $fieldmap $field]} {
            return -code error "Field \"$field\" not in table"
        }
        set i [dict get $fieldmap $field]
        # Convert target index input to integer, and check
        set j [::tda::tbl::NormalizeIndex [llength $fields] $index]
        if {$j < 0 || $j >= [llength $fields]} {
            return -code error "Target column ID out of range"
        }
        # Switch for move type
        if {$i < $j} {
            # Target index is beyond source
            set fields [concat [lrange $fields 0 $i-1] \
                    [lrange $fields $i+1 $j] [list $field] \
                    [lrange $fields $j+1 end]]
            set cid $i
        } elseif {$i > $j} {
            # Target index is below source
            set fields [concat [lrange $fields 0 $j-1] [list $field] \
                    [lrange $fields $j $i-1] [lrange $fields $i+1 end]]
            set cid $j
        } else {
            # Trivial case
            return
        }
        # Update fieldmap
        foreach field [lrange $fields $cid end] {
            dict set fieldmap $field $cid
            incr cid
        }
        return
    }
    
    # $tblObj rswap/cswap --
    #
    # Swap rows/columns
    #
    # Arguments:
    # key1/field1:       Key or field 1
    # key2/field2:       Key or field 2
    
    method rswap {key1 key2} {
        # Check existence of keys
        foreach key [list $key1 $key2] {
            if {![dict exists $keymap $key]} {
                return -code error "Key \"$key\" is not in table"
            }
        }
        # Get row IDs
        set rid1 [dict get $keymap $key1]
        set rid2 [dict get $keymap $key2]
        # Update key list and map
        lset keys $rid2 $key1
        lset keys $rid1 $key2
        dict set keymap $key1 $rid2
        dict set keymap $key2 $rid1
        return
    }
    
    method cswap {field1 field2} {
        # Check existence of fields
        foreach field [list $field1 $field2] {
            if {![dict exists $fieldmap $field]} {
                return -code error "Field \"$field\" is not in table"
            }
        }
        # Get column IDs
        set cid1 [dict get $fieldmap $field1]
        set cid2 [dict get $fieldmap $field2]
        # Update field list and map
        lset fields $cid2 $field1
        lset fields $cid1 $field2
        dict set fieldmap $field1 $cid2
        dict set fieldmap $field2 $cid1
        return
    }
    
    # $tblObj transpose --
    # 
    # Transpose a table
    
    method transpose {} {
        # Swap keys/fields
        lassign [list $keyname $fieldname] fieldname keyname
        lassign [list $keys $fields] fields keys
        lassign [list $keymap $fieldmap] fieldmap keymap
        # Initialize transpose
        foreach key $keys {
            dict set transpose $key ""
        }
        # Transpose data
        dict for {key rdict} $data {
            dict for {field value} $rdict {
                dict set transpose $field $key $value
            }
        }
        set data $transpose
        return
    }    
    
    # $tblObj clean --
    #
    # Clear keys and fields that don't exist in data
    
    method clean {} {
        # Remove blank keys
        set blankKeys ""
        foreach key $keys {
            if {[dict size [dict get $data $key]] == 0} {
                lappend blankKeys $key
            }
        }
        my remove keys {*}$blankKeys
        # Remove blank fields
        set blankFields ""
        foreach field $fields {
            set isBlank 1
            dict for {key rdict} $data {
                if {[dict exists $rdict $field]} {
                    set isBlank 0
                    break
                }
            }
            if {$isBlank} {
                lappend blankFields $field
            }
        }
        my remove fields {*}$blankFields
        return
    }
}

# Import all exported command into parent package
namespace eval ::tda {
    namespace import -force tbl::*
    namespace export {*}[namespace eval tbl {namespace export}]
}

# Finally, provide the package
package provide tda::tbl 0.1.0
