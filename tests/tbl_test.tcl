# Called from "build.tcl" in parent directory

# Table module
# define    
# new
# create
tie tblObj [tbl new]
$tblObj define data {
    1 {x 3.44 y 7.11 z 8.67}
    2 {x 4.61 y 1.81 z 7.63}
    3 {x 8.25 y 7.56 z 3.84}
    4 {x 5.20 y 6.78 z 1.11}
    5 {x 3.26 y 9.92 z 4.56}
}
tbl create foo {data {
    1 {x 3.44 y 7.11 z 8.67}
    2 {x 4.61 y 1.81 z 7.63}
    3 {x 8.25 y 7.56 z 3.84}
    4 {x 5.20 y 6.78 z 1.11}
    5 {x 3.26 y 9.92 z 4.56}
}}
assert [$tblObj] eq [foo]
assert [foo properties] eq [foo]
assert [$tblObj properties] eq {keyname key fieldname field keys {1 2 3 4 5} fields {x y z} data {1 {x 3.44 y 7.11 z 8.67} 2 {x 4.61 y 1.81 z 7.63} 3 {x 8.25 y 7.56 z 3.84} 4 {x 5.20 y 6.78 z 1.11} 5 {x 3.26 y 9.92 z 4.56}}}
tie tblCopy [$tblObj copy]
$tblCopy define keys {1 2} fields x
assert [$tblCopy properties] eq {keyname key fieldname field keys {1 2} fields x data {1 {x 3.44} 2 {x 4.61}}}
assert [$tblCopy] eq {keyname key fieldname field keys {1 2} fields x data {1 {x 3.44} 2 {x 4.61}}}

# key/field, i/j
assert [$tblObj keyname] eq key
assert [$tblObj fieldname] eq field
assert [$tblObj key 0] eq 1
assert [$tblObj i 1] == 0
assert [$tblObj key end] eq 5
assert [$tblObj i 5] == 4
assert [$tblObj field 0] eq x
assert [$tblObj j x] == 0
assert [$tblObj field end] eq z
assert [$tblObj j z] == 2

# find (DEPRECIATED)
assert [$tblObj find key 1] eq [$tblObj i 1]
assert [$tblObj find field x] eq [$tblObj j x]


# keys
# fields
assert [$tblObj keys] eq {1 2 3 4 5}
assert [$tblObj keys -i 0:2] eq {1 2 3}
assert [$tblObj fields] eq {x y z}
assert [$tblObj fields -j 0:1] eq {x y}
assert [$tblObj fields -j end] eq {z}
assert [$tblObj fields {[x-y]}] eq {x y}

# rename keys
tie tblCopy [$tblObj copy]
$tblCopy rename keys [lmap key [$tblCopy keys] {string cat K $key}]
assert [$tblCopy keys] eq {K1 K2 K3 K4 K5}

tie tblCopy [$tblObj copy]
$tblCopy rename keys [$tblCopy keys -i 0:2] {K1 K2 K3}
assert [$tblCopy keys] eq {K1 K2 K3 4 5}
assert [$tblCopy keys K*] eq {K1 K2 K3}

# rename fields
tie tblCopy [$tblObj copy]
$tblCopy rename fields {a b c}; # Renames all fields
$tblCopy rename fields {c a} {C A}; # Selected fields
assert [$tblCopy fields] eq {A b C}
assert [$tblCopy fields {[A-Z]}] eq {A C}

# mkkey (no data loss)
# remove fields
tie tblCopy [$tblObj copy]
$tblCopy fedit record_ID {[string cat R @key]}
$tblCopy mkkey record_ID
$tblCopy remove fields key
assert [$tblCopy keys] eq {R1 R2 R3 R4 R5}
assert [$tblCopy fields] eq {x y z}
assert [$tblCopy values] eq [$tblObj values]
$tblCopy remove keys {*}[$tblCopy keys -i 1:end-1]
assert [$tblCopy keys] eq {R1 R5}

# mkkey (data loss)
# remove keys
# data
tie tblCopy [$tblObj copy]
$tblCopy cset {record ID} {R1 R3 R1 R2 R1}; # 1 R1 2 R3 
$tblCopy mkkey {record ID}
assert [$tblCopy keys] eq {R1 R3 R2}
assert [$tblCopy cget key] eq {5 4 2}
$tblCopy sort
assert [$tblCopy keys] eq {R1 R2 R3}
assert [$tblCopy cget key] eq {5 2 4}
$tblCopy remove keys R2
assert [$tblCopy keys] eq {R1 R3}
assert [dict exists [$tblCopy data] R2] == 0

# clear, clean, and wipe
$tblCopy define keyname foo
$tblCopy clear
assert [$tblCopy shape] eq {0 3}
$tblCopy clean
assert [$tblCopy shape] eq {0 0}
assert [$tblCopy keyname] eq foo
$tblCopy wipe
assert [$tblCopy keyname] eq key

# data
assert [$tblObj data] eq {1 {x 3.44 y 7.11 z 8.67} 2 {x 4.61 y 1.81 z 7.63} 3 {x 8.25 y 7.56 z 3.84} 4 {x 5.20 y 6.78 z 1.11} 5 {x 3.26 y 9.92 z 4.56}}
assert [$tblObj data 3] eq {x 8.25 y 7.56 z 3.84}

# values
assert [$tblObj values] eq {{3.44 7.11 8.67} {4.61 1.81 7.63} {8.25 7.56 3.84} {5.20 6.78 1.11} {3.26 9.92 4.56}}

# exists
assert [$tblObj exists key 3]
assert [$tblObj exists key 6] == 0
assert [$tblObj exists field y]
assert [$tblObj exists field foo] == 0
assert [$tblObj exists value x y]
$tblObj set 3 y ""
assert [$tblObj exists value x y] == 0
$tblObj set 3 y 7.56; # reset

# get
assert [$tblObj get 2 x] == 4.61
assert [$tblObj get -kf 2 x] == 4.61
assert [$tblObj get -kj 2 0] == 4.61
assert [$tblObj get -if 1 x] == 4.61
assert [$tblObj get -ij 1 0] == 4.61
assert [$tblObj get 1,0] == 4.61

# indexing using ndlist
# index method
assert [$tblObj get end,end] == 4.56
assert [$tblObj get -1,-1] == 4.56
assert [$tblObj get -if end-1 z] == 1.11
assert [catch {$tblObj get end+1,0}]; # Should throw an error (out of range)
assert [$tblObj index -1,-1] eq [$tblObj get -1,-1]; # DEPRECIATED

# set key field
$tblObj set 2 x foo
assert [$tblObj get 2 x] == foo
$tblObj set 2 x 4.61
# set -kf key field
$tblObj set -kf 2 x foo
assert [$tblObj get 2 x] == foo
$tblObj set 2 x 4.61
# set -kj key j
$tblObj set -kj 2 0 foo
assert [$tblObj get 2 x] == foo
$tblObj set 2 x 4.61
# set -if i field
$tblObj set -if 1 x foo
assert [$tblObj get 2 x] == foo
$tblObj set 2 x 4.61
# set -ij i j
$tblObj set -ij 1 0 foo
assert [$tblObj get 2 x] == foo
$tblObj set 2 x 4.61
# set i,j
$tblObj set 1,0 foo
assert [$tblObj get 2 x] == foo
$tblObj set 2 x 4.61

# rget
assert [$tblObj rget 2] eq {4.61 1.81 7.63}
assert [$tblObj rget -i 1] eq {4.61 1.81 7.63}
assert [$tblObj rget -i end] eq {3.26 9.92 4.56}

# rset key
$tblObj rset 2 {foo bar foo}
assert [$tblObj rget 2] eq {foo bar foo}
$tblObj rset 2 {4.61 1.81 7.63}
# rset -i i
$tblObj rset -i 1 {foo bar foo}
assert [$tblObj rget 2] eq {foo bar foo}
$tblObj rset 2 {4.61 1.81 7.63}
# Delete row
$tblObj rset 2 ""
assert [$tblObj rget 2] eq {{} {} {}}
assert [$tblObj exists value 2 x] == 0
$tblObj rset 2 {4.61 1.81 7.63}
# Set row to scalar
$tblObj rset 2 foo
assert [$tblObj rget 2] eq {foo foo foo}
$tblObj rset 2 {4.61 1.81 7.63}

# cget
assert [$tblObj cget x] eq {3.44 4.61 8.25 5.20 3.26}
assert [$tblObj cget -j 0] eq {3.44 4.61 8.25 5.20 3.26}

# cset field
$tblObj cset x {foo bar foo bar foo}
assert [$tblObj cget x] eq {foo bar foo bar foo}
$tblObj cset x {3.44 4.61 8.25 5.20 3.26}
# cset -j j
$tblObj cset -j 0 {foo bar foo bar foo}
assert [$tblObj cget x] eq {foo bar foo bar foo}
$tblObj cset x {3.44 4.61 8.25 5.20 3.26}
# Delete row
$tblObj cset x ""
assert [$tblObj cget x] eq {{} {} {} {} {}}
assert [$tblObj exists value 2 x] == 0
$tblObj cset x {3.44 4.61 8.25 5.20 3.26}
# Set row to scalar
$tblObj cset x foo
assert [$tblObj cget x] eq {foo foo foo foo foo}
$tblObj cset x {3.44 4.61 8.25 5.20 3.26}

# mget
assert [$tblObj values] eq [$tblObj mget]
assert [$tblObj mget :,:] eq [$tblObj mget]
set submat {{3.44 8.67} {4.61 7.63} {8.25 3.84}}
assert [$tblObj mget {1 2 3} {x z}] eq $submat
assert [$tblObj mget -kf {1 2 3} {x z}] eq $submat
assert [$tblObj mget -if {0 1 2} {x z}] eq $submat
assert [$tblObj mget -kj {1 2 3} {0 end} eq $submat
assert [$tblObj mget -ij 0:2 {0 end} eq $submat
assert [$tblObj mget "0:2,0 2"] eq $submat

set submat2 {{foo1 bar1} {foo2 bar2} {foo3 bar3}}
# mset keys fields
$tblObj mset {1 2 3} {x z} $submat2
assert [$tblObj mget {1 2 3} {x z}] eq $submat2
$tblObj mset {1 2 3} {x z} $submat; # reset
# mset -kf keys fields
$tblObj mset -kf {1 2 3} {x z} $submat2
assert [$tblObj mget {1 2 3} {x z}] eq $submat2
$tblObj mset {1 2 3} {x z} $submat; # reset
# mset -if i fields
$tblObj mset -if 0:2 {x z} $submat2
assert [$tblObj mget {1 2 3} {x z}] eq $submat2
$tblObj mset {1 2 3} {x z} $submat; # reset
# mset -kj keys j
$tblObj mset -if {1 2 3} {0 end} $submat2
assert [$tblObj mget {1 2 3} {x z}] eq $submat2
$tblObj mset {1 2 3} {x z} $submat; # reset
# mset -ij i j
$tblObj mset -ij 0:2 {0 end} $submat2
assert [$tblObj mget {1 2 3} {x z}] eq $submat2
$tblObj mset {1 2 3} {x z} $submat; # reset
# mset i,j
$tblObj mset 0:2,[list 0 2] $submat2
assert [$tblObj mget {1 2 3} {x z}] eq $submat2
$tblObj mset {1 2 3} {x z} $submat; # reset

# shape
assert [$tblObj shape] eq {5 3}
assert [$tblObj shape 0] == 5
assert [$tblObj shape 1] == 3
# height
assert [$tblObj height] == 5
# width
assert [$tblObj width] == 3

# add fields with set
tie tblCopy [$tblObj copy]
$tblCopy set 1 x 2.00 y 5.00 foo bar
assert [$tblCopy data 1] eq {x 2.00 y 5.00 z 8.67 foo bar}
assert [$tblCopy data -i 0] eq {x 2.00 y 5.00 z 8.67 foo bar}


# Add fields and edit through "with"
set a 20.0; # external variable in "with" and "fedit"
tie tblCopy [$tblObj copy]
$tblCopy add fields q
$tblCopy with {
set q [expr {$x*2 + $a}]; # modify field value
}
assert [$tblCopy cget q] eq {26.88 29.22 36.5 30.4 26.52}


# Add keys, and sort keys
$tblCopy add keys 0 7 12 3 8 2 1
assert [$tblCopy keys] eq {1 2 3 4 5 0 7 12 8}
$tblCopy sort -integer 
assert [$tblCopy keys] eq {0 1 2 3 4 5 7 8 12}

# Move and swap rows
# rmove
# rswap 
tie tblCopy [$tblObj copy]
$tblCopy rmove 1 end-1
assert [$tblCopy keys] eq {2 3 4 1 5}
$tblCopy rswap 1 5
assert [$tblCopy keys] eq {2 3 4 5 1}
$tblCopy rmove [$tblCopy key -i end-1] 0
assert [$tblCopy] eq [$tblObj]

# Move and swap columns
# rmove
# rswap
$tblCopy cmove x end
assert [$tblCopy fields] eq {y z x}
$tblCopy cmove z end
assert [$tblCopy fields] eq {y x z}
$tblCopy cswap x y
assert [$tblCopy fields] eq {x y z}
assert [$tblCopy] eq [$tblObj]

# Insert keys/fields
$tblCopy insert keys 2 foo bar
assert [$tblCopy keys] eq {1 2 foo bar 3 4 5}
$tblCopy insert fields end+1 foo bar
assert [$tblCopy fields] eq {x y z foo bar}
assert [catch {$tblCopy insert fields 0 foo}]; # cannot insert existing field
assert [catch {$tblCopy insert fields 0 bah bah}]; # Cannot have duplicates

# Expr and fedit
tie tblCopy [$tblObj copy]
assert [$tblCopy expr {@x*2 + $a}] eq {26.88 29.22 36.5 30.4 26.52}
$tblCopy fedit q {@x*2 + $a}
assert [$tblCopy cget q] eq {26.88 29.22 36.5 30.4 26.52}
# Access to key values in "expr"
assert [$tblCopy expr {@key}] eq [$tblCopy keys]

# Query
assert [$tblObj query {@x > 3.0 && @y > 7.0}] eq {1 3 5}

# Filter
tie tblCopy [$tblObj copy]
$tblCopy filter {@x > 3.0 && @y > 7.0}
assert [$tblCopy keys] eq {1 3 5}

# Searching and sorting
tie tblCopy [$tblObj copy]
assert [$tblCopy search -real x 8.25] == 3; # returns first matching key
$tblCopy sort -real x
assert [$tblCopy keys] eq {5 1 2 4 3}
assert [$tblCopy cget x] eq {3.26 3.44 4.61 5.20 8.25}
assert [$tblCopy search -sorted -bisect -real x 5.0] == 2
$tblCopy search -inline -real x 8.25
assert [$tblCopy keys] == 3; # returns first matching key

# Merging tables
tie newTable [tbl new data {1 {x 5.00 q 6.34}}]
tie tblCopy [$tblObj copy]
# $newTable set 1 x 5.00 q 6.34
$tblCopy merge $newTable
$newTable destroy; # clean up
assert [$tblCopy properties] eq {keyname key fieldname field keys {1 2 3 4 5} fields {x y z q} data {1 {x 5.00 y 7.11 z 8.67 q 6.34} 2 {x 4.61 y 1.81 z 7.63} 3 {x 8.25 y 7.56 z 3.84} 4 {x 5.20 y 6.78 z 1.11} 5 {x 3.26 y 9.92 z 4.56}}}

# Single entry or dictionary entry settings
tie tbl1 [tbl new keys {1 2 3}]
tie tbl2 [tbl new {keys {1 2 3}}]
assert [$tbl1] eq [$tbl2]

# transpose
tie tblCopy [$tblObj copy]
$tblCopy transpose
assert [$tblCopy keyname] eq [$tblObj fieldname]
assert [$tblCopy fieldname] eq [$tblObj keyname]
assert [$tblCopy keys] eq [$tblObj fields]
assert [$tblCopy fields] eq [$tblObj keys]
assert [transpose [$tblCopy values]] eq [$tblObj values]
$tblCopy transpose
assert [$tblCopy] eq [$tblObj]


# # unknown       # Calls properties (no args to object command)
# # add           # Add keys/fields to table
# # cget          # Get column of data
# # clean         # Clean table of keys/fields with no data
# # clear         # Clear table data, keeping field names
# # cmove         # Move column
# # copy          # Copy table to new object
# # cset          # Set an entire column
# # cswap         # Swap columns
# # data          # Get dictionary-style data of table
# # define        # Define table properties
# # exists        # Check if keys/fields/values exist
# # expr          # Perform column operation on table
# # fedit         # Create field with expr.
# # field         # Get field for given column index
# # fieldname     # Get fieldname
# # fields        # Get list of fields given column index and glob patterns 
# # filter        # Filter table given expr
# # find          # DEPRECIATED. Get row and column indices given key/field
# # get           # Get single values from table
# # height        # Get height of table (number of keys)
# # i             # Get row index given key
# # index         # DEPRECIATED. Get value from table given row/column. 
# # insert        # Insert keys/fields into table
# # j             # Get column index given field
# # key           # Get key given row index
# # keyname       # Get keyname
# # keys          # Get list of keys given row index and glob patterns 
# # merge         # Merge table data into current table
# # mget          # Get matrix of data from table
# # mkkey         # Make a field the key
# # mset          # Set a matrix of data in table
# # properties    # Get table properties. Same as calling object without args
# # query         # Query keys that meet table expr.
# # remove        # Remove keys/fields from table
# # rename        # Rename keys/fields in table
# # rget          # Get row of data in table
# # rmove         # Move rows
# # rset          # Set rows of data in table
# # rswap         # Swap rows in table
# # search        # Search for keys meeting lsearch criteria in table
# # set           # Set single values in table
# # shape         # Get shape of table
# # sort          # Sort table using lsort
# # transpose     # Transpose table
# # values        # Get table values
# # width         # Get width of table (number of fields)
# # wipe          # Wipe table (resets to fresh table)
# # with          # Loop through tabular data


