import xlrd, sys, re, MySQLdb
from csv import DictWriter

def getBatches(cursor):
  cursor.execute('''SELECT idbatches, client_filename
                    FROM batches''')
  result = cursor.fetchall()
  batchDict = {}
  for item in result:
    batchDict[str(item[0])] = str(item[1])

  return batchDict


def processXLSX(inputFile, outputFile, db, cursor):
  worksheet = xlrd.open_workbook(inputFile).sheet_by_index(0)
  headers = dict( (i, worksheet.cell_value(0, i) ) for i in range(worksheet.ncols) ) 
  drObject = ( dict( (headers[j], worksheet.cell_value(i, j)) for j in headers ) for i in range(1, worksheet.nrows) )

  headerList = []

  for key in headers:
    headerList.append(headers[key])

  headerList.insert(0, 'Batch_Name')

  batchDict = getBatches(cursor)
  dictList = []
  countDict = {}
  batchIDfieldName = ''

  batchIDfieldName = ''
  for item in drObject:
    for key in item:
      if re.search('[Bb][Aa][Tt][Cc][Hh]', str(key)):
        batchIDfieldName = key
        break
    break

  for item in drObject:
    batchID = int(item[batchIDfieldName])
    item['Batch_Name'] = batchDict[str(batchID)]

    if str(batchID) not in countDict.keys():
      countDict[str(batchID)] = 1
    else:
      countDict[str(batchID)] += 1

    dictList.append(item)

  for key in countDict:
    cursor.execute('''UPDATE batches
                      SET final_item_count = {0},
                      return_date = CURDATE()
                      WHERE idbatches = {1}
                      '''.format(countDict[key], key))

  with open(outputFile, 'w') as output:
    dwObject = DictWriter(output, headerList, restval = '', delimiter = ',')
    dwObject.writeheader()
    for row in dictList:
      dwObject.writerow(row)


def main():
  db = MySQLdb.connect(host='173.255.254.42',db='decc',read_default_file='~/.my.cnf')
  cursor = db.cursor()
  processXLSX(sys.argv[1], sys.argv[2], db, cursor)


if __name__ == '__main__':
  main()