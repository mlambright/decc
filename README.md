#DECC
The scripts in this repo can be used to process files for use in the ***DECC*** project.

##processScans.py
This script, when applied to a directory containing ***DECC*** batch scan files, will add records to the MySQL database for each file (recursively), and will move each file to a user-designated directory and rename each file to the appropriate convention. It is used as follows:
```
python processScans.py inputPath outputPath
```
As written, the script assumes a [MySQL option file](http://dev.mysql.com/doc/refman/5.1/en/option-files.html) stored at ~/.my.cnf. That option can be changed at line 151 of the script.
This script uses [PyPDF2](https://pypi.python.org/pypi/PyPDF2/1.22) and [MySQLdb](https://pypi.python.org/pypi/MySQL-python/1.2.5)