##DECC
The scripts in this repo can be used to process files for use in the ***DECC*** project.

###processScans.py
This script, when applied to a directory containing ***DECC*** batch scan files, will add records to the MySQL database for each file (recursively), and will move each file to a user-designated directory and rename each file to the appropriate convention. It is used as follows:
```
python processScans.py inputPath outputPath
```
As written, the script assumes a [PostgreSQL Password file](http://www.postgresql.org/docs/9.3/static/libpq-pgpass.html)
This script uses [PyPDF2](https://pypi.python.org/pypi/PyPDF2/1.22) and [psycopg2](http://initd.org/psycopg/)

###processXLSX.py
This script processes individual xlsx files returned from vendor; it attaches a batch name to each record, writes out a final csv, and updates the database with final counts. It is used as follows:
```
python processXLSX.py inputFile outputFile
```
As written, the script assumes a [PostgreSQL Password file](http://www.postgresql.org/docs/9.3/static/libpq-pgpass.html)
This script uses [PyPDF2](https://pypi.python.org/pypi/PyPDF2/1.22), [psycopg2](http://initd.org/psycopg/), and [xlrd](https://pypi.python.org/pypi/xlrd)

###vrqc.py
This script quality checks voter registration files returned from vendor. It is called as follows
```
python vrqc.py inputFile outputFile
```