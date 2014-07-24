from PyPDF2 import PdfFileReader
from csv import DictReader, DictWriter
from sys import argv
import os, MySQLdb, re, shutil


def findClients(cursor):
  result = cursor.execute('SELECT idclients, org_name FROM clients')
  table = cursor.fetchall()
  clients = []

  print 'id\torg name'
  for item in table:
    print item[0], '\t', item[1]
    clients.append(str(item[0]))

  return clients


def getProject(clientID, cursor):
  result = cursor.execute('''SELECT MAX(idprojects)
                             FROM projects
                             WHERE projects.clients_idclients = {0}
                             '''.format(clientID))

  value = cursor.fetchall()[0][0]
  return value


def findOrders(projectID, cursor):
  result = cursor.execute('''SELECT idorders AS ID, order_date AS DATE
                             FROM orders
                             WHERE projects_idprojects = {0}
                             '''.format(projectID))

  table = cursor.fetchall()
  orders = [0]

  print 'id\torder date'
  for item in table:
    print item[0], '\t', item[1]
    orders.append(str(item[0]))

  return orders


def createOrder(projectID, cursor):
  cursor.execute('''INSERT INTO orders (order_date, projects_idprojects, digital)
                    VALUES (CURDATE(), {0}, TRUE);
                    '''.format(projectID))


def findTypes(projectID, cursor):
  result = cursor.execute('''SELECT idtypes AS ID, type_name AS NAME
                             FROM types
                             WHERE projects_idprojects = {0}
                             '''.format(projectID))

  table = cursor.fetchall()
  types = []

  print 'id\ttype name'
  for item in table:
    print item[0], '\t', item[1]
    types.append(str(item[0]))

  return types  


def createPart(orderID, typeID, state, rush, van, match, quad, cursor, db):
  cursor.execute('''INSERT INTO parts (state, item_count, orders_idorders, 
                    types_idtypes, rush, van, quad, `match`, destroy_files,
                    return_files, batch_count)
                    VALUES ('{0}', 0, {1}, {2}, {3}, {4}, {5}, {6}, 0, 0, 0)
                    '''.format(state, orderID, typeID, rush, van, quad, match))

  db.commit()

  cursor.execute('''SELECT MAX(idpieces)
                      FROM parts
                      WHERE orders_idorders = {0}
                      '''.format(orderID))

  result = cursor.fetchall()[0][0]

  return result


def obtainStartNum(clientID, cursor):
  result = cursor.execute('''SELECT MAX(idbatches) + 1 AS ID
                             FROM batches
                             INNER JOIN parts
                             ON batches.parts_idparts = parts.idpieces
                             INNER JOIN orders
                             ON parts.orders_idorders = orders.idorders
                             INNER JOIN projects
                             ON orders.projects_idprojects = projects.idprojects
                             WHERE projects.clients_idclients = {0}
                             '''.format(clientID))

  value = cursor.fetchall()[0][0]

  if value is not None:
    batchID = value
  else:
    batchID = int(clientID) * 10000000 + 1
  return batchID


def processPDF(PATH, outputPATH, startNum, partID, cursor, db):
  files = [os.path.join(dp, f) for dp, dn, filenames in os.walk(PATH) for f in filenames]
  batchID = startNum
  totalPages = 0
  print 'Starting ID:\t', startNum

  if not os.path.exists(outputPATH):
    os.makedirs(outputPATH)

  for item in files:
    clientFilename = re.sub(r'^/', '', item.replace(PATH, ''))

    extension = re.sub(r'^.*\.(.*?)$', r'\1', item).lower()
    vendorFilename = str("%010d" % (batchID,)) + "." + extension

    if extension == 'pdf' :
      input = PdfFileReader(item)
      page_count = input.getNumPages()
    else:
      page_count = 1

    totalPages += int(page_count)

    if re.search(r'(/)|(\\)$', item):
      outfile = outputPATH + vendorFilename
    else:
      outfile = outputPATH + '/' + vendorFilename

    cursor.execute('''INSERT INTO batches
                      (idbatches, client_filename, vendor_filename,
                      initial_item_count, submission_date, processed_date,
                      parts_idparts)
                      VALUES (%s, %s, %s, %s, CURDATE(), CURDATE(), %s)
                      ''', (batchID, clientFilename, vendorFilename, page_count, partID))

    shutil.move(item, outfile)

    batchID += 1
  db.commit()
  print 'Total Pages:\t', totalPages
  print 'Ending ID:\t', batchID-1


def processPhysical(PATH, outputPATH, partID, startNum, db, cursor):
  dictList = []
  ID = int(startNum)

  with open(PATH, 'r') as file:
    input = DictReader(file)
    for item in input:
      rowInfo = item
      cursor.execute('''INSERT INTO batches (idbatches, vendor_filename, client_filename, submission_date, 
                        processed_date, parts_idparts) 
                        VALUES ('{0}', '{0}', '{1}', curdate(), curdate(), {2});
                        '''.format(ID, item['Batch Name'], partID))

      db.commit()

      rowInfo['Batch ID'] = "%010d" % ID
      dictList.append(rowInfo)

      ID += 1

  with open(outputPATH, 'w') as file:
    output = DictWriter(file, fieldnames = ['Batch ID', 'Batch Name'], restval = '', delimiter = ',')

    output.writeheader()
    for row in dictList:
      output.writerow(row)


def main():
  PATH = argv[1]
  outputPATH = argv[2]

  ##MAKE ANY CONNECTION CHANGES HERE (INCLUDING DEFAULT FILE)
  db = MySQLdb.connect(host='173.255.254.42',db='decc',read_default_file='~/.my.cnf')
  cursor = db.cursor()

  clients = [1]
  clientID = ''
  while clientID not in clients:
    clients = findClients(cursor)
    clientID = str(raw_input("Which Client ID are these batches related to? "))

  projectID = getProject(clientID, cursor)

  orders = [1]
  orderResponse = ''
  while orderResponse not in orders:
    orders = findOrders(projectID, cursor)
    print '0\tNew Order'
    orderResponse = str(raw_input("Which Order ID are these batches related to? "))

    if orderResponse == '0':
      createOrder(projectID, cursor)
      db.commit()
      orders = findOrders(projectID, cursor)
      orderResponse = str(raw_input("Which Order ID are these batches related to? "))
  orderID = orderResponse

  types = [1]
  typeID = ''
  while typeID not in types:
    types = findTypes(projectID, cursor)
    typeID = str(raw_input("Which Type ID are these batches related to? "))
  state = str(raw_input("Which State are these batches related to? ")).upper()

  rushResponse = ''
  while rushResponse.upper() not in ['Y', 'N']:
    rushResponse = str(raw_input('Is this a rush order? (Y/N) '))
  if rushResponse == 'Y':
    rush = 1
  else:
    rush = 0
  vanResponse = ''
  while vanResponse.upper() not in ['Y', 'N']:
    vanResponse = str(raw_input('VAN entry requested? (Y/N) '))
  if vanResponse == 'Y':
    van = 1
  else:
    van = 0
  matchResponse = ''
  while matchResponse.upper() not in ['Y', 'N']:
    matchResponse = str(raw_input('VF matching requested? (Y/N) '))
  if matchResponse == 'Y':
    match = 1
  else:
    match = 0
  quadResponse = ''
  while quadResponse.upper() not in ['Y', 'N']:
    quadResponse = str(raw_input('Quad sharing requested? (Y/N) '))
  if quadResponse == 'Y':
    quad = 1
  else:
    quad = 0

  partID = createPart(orderID, typeID, state, rush, van, match, quad, cursor, db)
  startNum = obtainStartNum(clientID, cursor)

  methodResponse = ''
  while methodResponse.upper() not in ['D', 'P']:
    methodResponse = str(raw_input('Were the batches transmitted (D)igitally or (P)hysically? '))

  if methodResponse.upper() == 'D':
    processPDF(PATH, outputPATH, startNum, partID, cursor, db)
  else:
    processPhysical(PATH, outputPATH, partID, startNum, db, cursor)

  db.close()


if __name__ == '__main__':
  main()