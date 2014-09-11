import xlrd, sys, re, psycopg2, psycopg2.extras
from csv import DictWriter
from db_info import HOST, DB, USER
import vrqc


def getBatches(cursor):
  cursor.execute('''SELECT id, original_filename
                    FROM decc_form_batch''')
  result = cursor.fetchall()
  batchDict = {}
  for item in result:
    batchDict[str(item[0])] = str(item[1])
  return batchDict


def writeFile(dictList, outputFile):
  with open(outputFile, 'w') as output:
    dwObject = DictWriter(output, headerList, restval = '', delimiter = ',')
    dwObject.writeheader()
    for row in dictList:
      dwObject.writerow(row)


def processXLSX(inputFile, db, cursor):
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
    cursor.execute('''UPDATE decc_form_batch
                      SET final_item_count = {0},
                      return_date = current_date
                      WHERE id = {1};
                      '''.format(countDict[key], key))
    db.commit()
  return dictList
  

def main():
  ##MAKE ANY CONNECTION CHANGES HERE
  db = psycopg2.connect(host = HOST, database = DB, user = USER)
  cursor = db.cursor()
  processXLSX(sys.argv[1], db, cursor)
  dictList = vrqc.run(dictList, sys.argv[2])
  writeFile(dictList, sys.argv[2])


if __name__ == '__main__':
  main()
