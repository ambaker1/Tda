source test.tcl

# Export data to file (creates or overwrites the file)
putsFile example.txt "hello world"
# Import the contents of the file (requires that the file exists)
assert [readFile example.txt] eq "hello world"

writeFile example.txt "hello world"
appendFile -nonewline example.txt "goodbye "
appendFile example.txt "moon"

assert [readFile example.txt] eq "hello world\ngoodbye moon"

# Binary files
# Example modified from example on tcl wiki written by Mac Cody and Jeff David
# https://wiki.tcl-lang.org/page/Working+with+binary+data
set outBinData [binary format s2Sa6B8 {100 -2} 100 foobar 01000001]
puts "Format done: $outBinData"
writeFile -translation binary binfile.bin $outBinData
set inBinData [readFile -translation binary binfile.bin]
puts [binary scan $inBinData s2Sa6B8 val1 val2 val3 val4]
puts "Scan done: $val1 $val2 $val3 $val4"

# Acid test for csv parser/writer
# Acid test files from https://github.com/maxogden/csv-spectrum

set csvDir "csv_samples"
set commas_in_quotes [readFile $csvDir/comma_in_quotes.csv]
set empty [readFile $csvDir/empty.csv]
set empty_crlf [readFile $csvDir/empty_crlf.csv]
set escaped_quotes [readFile $csvDir/escaped_quotes.csv]
set json [readFile $csvDir/json.csv]
set newlines [readFile $csvDir/newlines.csv]
set quotes_and_newlines [readFile $csvDir/quotes_and_newlines.csv]
set simple [readFile $csvDir/simple.csv]
set simple_crlf [readFile $csvDir/simple_crlf.csv]
set utf8 [readFile $csvDir/utf8.csv]

# from commas_in_quotes.csv
assert [csv2mat $commas_in_quotes] eq \
{{first last address city zip} {John Doe {120 any st.} {Anytown, WW} 08123}}

assert [readMatrix $csvDir/comma_in_quotes.csv] eq \
{{first last address city zip} {John Doe {120 any st.} {Anytown, WW} 08123}}

assert [csv2mat $empty] eq \
{{a b c} {1 {} {}} {2 3 4}}

assert [csv2mat $empty_crlf] eq \
{{a b c} {1 {} {}} {2 3 4}}

assert [csv2mat $escaped_quotes] eq \
{{a b} {1 {ha "ha" ha}} {3 4}}

assert [csv2mat $json] eq \
{{key val} {1 {{"type": "Point", "coordinates": [102.0, 0.5]}}}}

assert [csv2mat $newlines] eq \
{{a b c} {1 2 3} {{Once upon 
a time} 5 6} {7 8 9}}

assert [csv2mat $quotes_and_newlines] eq \
{{a b} {1 {ha 
"ha" 
ha}} {3 4}}

assert [csv2mat $simple] eq \
{{a b c} {1 2 3}}

assert [csv2mat $simple_crlf] eq \
{{a b c} {1 2 3}}

assert [csv2mat $utf8] eq \
{{a b c} {1 2 3} {4 5 ʤ}}


# Reverse acid-test
assert [mat2csv [csv2mat $commas_in_quotes]] eq $commas_in_quotes
# SKIPPING WRITE TEST FOR EMPTY CELLS - EMPTY CELLS ARE WRITTEN LIKE ,, RATHER THAN ,"",
# assert [mat2csv [csv2mat $empty]] eq $empty
# assert [mat2csv [csv2mat $empty_crlf]] eq $empty_crlf
assert [mat2csv [csv2mat $escaped_quotes]] eq $escaped_quotes
assert [mat2csv [csv2mat $json]] eq $json
assert [mat2csv [csv2mat $newlines]] eq $newlines
assert [mat2csv [csv2mat $quotes_and_newlines]] eq $quotes_and_newlines
assert [mat2csv [csv2mat $simple]] eq $simple
assert [mat2csv [csv2mat $simple_crlf]] eq $simple_crlf
assert [mat2csv [csv2mat $utf8]] eq $utf8


# Conversion acid test
set table [csv2tbl $commas_in_quotes]
assert [txt2csv [mat2txt [tbl2mat $table]]] eq $commas_in_quotes
$table destroy

set table [csv2tbl $escaped_quotes]
assert [txt2csv [mat2txt [tbl2mat $table]]] eq $escaped_quotes
$table destroy

set table [csv2tbl $json]
assert [txt2csv [mat2txt [tbl2mat $table]]] eq $json
$table destroy

set table [csv2tbl $newlines]
assert [txt2csv [mat2txt [tbl2mat $table]]] eq $newlines
$table destroy

set table [csv2tbl $quotes_and_newlines]
assert [txt2csv [mat2txt [tbl2mat $table]]] eq $quotes_and_newlines
$table destroy

set table [csv2tbl $simple]
assert [txt2csv [mat2txt [tbl2mat $table]]] eq $simple
$table destroy

set table [csv2tbl $simple_crlf]
assert [txt2csv [mat2txt [tbl2mat $table]]] eq $simple_crlf
$table destroy

set table [csv2tbl $utf8]
assert [txt2csv [mat2txt [tbl2mat $table]]] eq $utf8
$table destroy
