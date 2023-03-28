# Script to install package in Tcl installation library folder
set install_path [file join {*}[file dirname [info library]] tda-0.1.0]
file delete -force $install_path
file mkdir $install_path
file copy LICENSE $install_path
file copy README.md $install_path
file copy doc/tda.pdf $install_path
file copy {*}[glob -directory lib *] $install_path
