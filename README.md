#DECC
The scripts in this repo can be used to process files for use in the ***DECC*** project.

##MySQLfilereceipt.py
This script, when applied to a directory containing ***DECC*** batch scan files, will add records to the MySQL database for each file (recursively), and will move and rename each file to the appropriate convention its use is as follows
```
python MySQLfilereceipt.py inputPath outputPath
```
As written, the script assumes a [MySQL option file](http://dev.mysql.com/doc/refman/5.1/en/option-files.html) stored at ~/.my.cnf. That option can be changed at line 151 of the script.