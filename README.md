# Tda
Tcl Data Analysis

Tda (pronounced "ta-da!"), is a comprehensive data analysis package for Tcl.

Tda has the following sub-packages:

| Module      | Description |
| ----------- | ----------- |
| tda::ndlist | N-dimensional list manipulation |
| tda::tbl    | Tabular data structure |
| tda::io     | File utilities and data conversions |
| tda::vis    | Data visualization tools |

Full documentation is available [here]{doc/tda.pdf}

## Installation
Tda is a Tin package. Tin makes installing Tcl packages easy, and is available [here]{https://github.com/ambaker1/Tin}.
After installing Tin, simply include the following in your script to install tda:
```tcl
package require tin
tin add -auto tda https://github.com/ambaker1/Tda install.tcl 0.1.1-
tin install tda
```
This will install Tda and all dependent Tin packages.
Once Tda is installed, use the following code to load the package and import the commands.
```tcl
package require tda
namespace import tda::*
```
Alternatively, the Tin package can also be used to easily import the commands.
```tcl
package require tin
tin import tda
```

## Collaboration
If you would like to collaborate and improve Tda, fork the repository and submit a pull request.

