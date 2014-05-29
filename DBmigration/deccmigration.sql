ALTER TABLE "tempdecc"."orders" ALTER "digital" TYPE bool USING CASE WHEN "digital"=0 THEN FALSE ELSE TRUE END;
ALTER TABLE "tempdecc"."parts" ALTER "rush" TYPE bool USING CASE WHEN "rush"=0 THEN FALSE ELSE TRUE END;
ALTER TABLE "tempdecc"."parts" ALTER "van" TYPE bool USING CASE WHEN "van"=0 THEN FALSE ELSE TRUE END;
ALTER TABLE "tempdecc"."parts" ALTER "quad" TYPE bool USING CASE WHEN "quad"=0 THEN FALSE ELSE TRUE END;
ALTER TABLE "tempdecc"."parts" ALTER "destroy_files" TYPE bool USING CASE WHEN "destroy_files"=0 THEN FALSE ELSE TRUE END;
ALTER TABLE "tempdecc"."parts" ALTER "return_files" TYPE bool USING CASE WHEN "return_files"=0 THEN FALSE ELSE TRUE END;
ALTER TABLE "tempdecc"."parts" ALTER "match" TYPE bool USING CASE WHEN "match"=0 THEN FALSE ELSE TRUE END;

INSERT INTO "decc"."auth_user" (name, email)
SELECT DISTINCT name, email
FROM "tempdecc"."contacts";

INSERT INTO "decc"."decc_form_address" (street1, city, state, zipcode)
SELECT DISTINCT billing_address, city, state, zip 
FROM "tempdecc"."billable";

INSERT INTO "decc"."decc_form_address" (street1, city, state, zipcode)
SELECT DISTINCT oldclients.shipping_address, oldclients.city, oldclients.state, oldclients.zip 
FROM "tempdecc"."clients" AS oldclients
LEFT JOIN "decc"."decc_form_address" AS newclients
ON oldclients.shipping_address = newclients.street1
   	AND newclients.city = oldclients.city
   	AND newclients.state = oldclients.state
   	AND newclients.zipcode = oldclients.zip
WHERE newclients.id IS NULL;

INSERT INTO "decc"."decc_form_contact" (id, work_phone, cell_phone, fax, added_date, modified_date, user_id)
SELECT DISTINCT idcontacts, work_phone, cell_phone, fax, added_date, modified_date, users.id
FROM "tempdecc"."contacts" as oldcontacts
INNER JOIN "decc"."auth_user" AS users
ON oldcontacts.name = users.name
   	AND oldcontacts. email = users.email;

INSERT INTO "decc"."decc_form_billable" (id, contact_id, address_id, tax_status, added_date, modified_date, org_name)
SELECT DISTINCT oldbillable.idtable1, newcontacts.id AS contact_id, addresses.id AS address_id, tax_status, oldbillable.added_date, oldbillable.modified_date, billable_org
FROM "tempdecc"."billable" AS oldbillable
INNER JOIN "tempdecc"."contacts" AS oldcontacts
ON idcontacts = contacts_idcontacts
INNER JOIN "decc"."auth_user" AS users
ON users.email = oldcontacts.email
   	AND users.name = oldcontacts.name 
INNER JOIN "decc"."decc_form_contact" AS newcontacts
ON users.id = newcontacts.user_id
INNER JOIN "decc"."decc_form_address" AS addresses
ON oldbillable.billing_address = addresses.street1
   	AND oldbillable.city = addresses.city
   	AND oldbillable.state = addresses.state
   	AND oldbillable.zip = addresses.zipcode
ORDER BY oldbillable.idtable1;

INSERT INTO "decc"."decc_form_project" (id, billable_id, start_date, end_date, order_frequency, estimated_item_count, notes, added_date, modified_date, invoice_date)
SELECT DISTINCT idprojects, newbillable.id AS billable_id, start_date, end_date, order_frequency, estimated_item_count, notes, oldproject.added_date, oldproject.modified_date, invoice_date
FROM "tempdecc"."projects" AS oldproject
INNER JOIN "tempdecc"."billable" AS oldbillable
ON oldproject.billable_idtable1 = oldbillable.idtable1
INNER JOIN "decc"."decc_form_billable" AS newbillable
ON oldbillable.billable_org = newbillable.org_name
ORDER BY idprojects;

INSERT INTO "decc"."decc_form_client" (id, address_id, project_id, org_name, added_date, modified_date)
SELECT DISTINCT oldclient.idclients, addresses.id AS address_id, clientconnect.idprojects AS project_id, oldclient.org_name, oldclient.added_date, oldclient.modified_date
FROM "tempdecc"."clients" AS oldclient
INNER JOIN "decc"."decc_form_address" AS addresses
ON oldclient.shipping_address = addresses.street1
   	AND oldclient.city = addresses.city
   	AND oldclient.state = addresses.state
   	AND oldclient.zip = addresses.zipcode
INNER JOIN (
	SELECT idclients, max(oldproject.idprojects) AS idprojects
	FROM "tempdecc"."clients"
	INNER JOIN "tempdecc"."projects" AS oldproject
	ON idclients = clients_idclients
	GROUP BY idclients
	) AS clientconnect
ON oldclient.idclients = clientconnect.idclients
ORDER BY oldclient.idclients;

INSERT INTO "decc"."decc_form_clientcontact" (client_id, contact_id, "order")
SELECT DISTINCT clients_idclients, contacts_idcontacts, "order"
FROM "tempdecc"."clients_has_contacts";

INSERT INTO "decc"."decc_form_type" (id, project_id, type_name, field_notes, cost_rate, cost_noi)
SELECT DISTINCT idtypes, projects_idprojects, type_name, field_notes, cost_rate, cost_to_noi
FROM "tempdecc"."types"
ORDER BY idtypes;

INSERT INTO "decc"."decc_form_order" (id, project_id, order_date, digital, bill_date, paid_date)
SELECT DISTINCT idorders, projects_idprojects, order_date, digital, bill_date, paid_date
FROM "tempdecc"."orders"
ORDER BY idorders;

INSERT INTO "decc"."decc_form_part" (id, order_id, form_type_id, rush, state, item_count, batch_count, van, quad, "match", destroy_files, return_files, extras)
SELECT DISTINCT idpieces, orders_idorders, types_idtypes, rush, state, item_count, 0, van, quad, "match", destroy_files, return_files, extras
FROM "tempdecc"."parts"
ORDER BY idpieces;

INSERT INTO "decc"."decc_form_batch" (id, part_id, client_filename, vendor_filename, item_count, final_item_count, submission_date, processed_date, return_date)
SELECT DISTINCT idbatches, parts_idparts, client_filename, vendor_filename, initial_item_count, final_item_count, submission_date, processed_date, return_date
FROM "tempdecc"."batches"
ORDER BY idbatches;

DROP SCHEMA "tempdecc" CASCADE;