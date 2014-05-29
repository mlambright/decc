DROP SCHEMA "decc" CASCADE;
CREATE SCHEMA "decc";
SET search_path = "decc";

CREATE TABLE "decc"."auth_user" (
    "id" serial NOT NULL PRIMARY KEY,
    "name" VARCHAR(255),
    "email" VARCHAR(255)
)
;
CREATE TABLE "decc_form_address" (
    "id" serial NOT NULL PRIMARY KEY,
    "street1" varchar(255),
    "street2" varchar(255),
    "city" varchar(255),
    "state" varchar(255),
    "zipcode" varchar(32)
)
;
CREATE TABLE "decc_form_contact" (
    "id" serial NOT NULL PRIMARY KEY,
    "user_id" integer NOT NULL UNIQUE REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED,
    "work_phone" varchar(255),
    "cell_phone" varchar(255),
    "fax" varchar(255),
    "added_date" date NOT NULL,
    "modified_date" date NOT NULL
)
;
CREATE TABLE "decc_form_billable" (
    "id" serial NOT NULL PRIMARY KEY,
    "contact_id" integer NOT NULL REFERENCES "decc_form_contact" ("id") DEFERRABLE INITIALLY DEFERRED,
    "address_id" integer NOT NULL REFERENCES "decc_form_address" ("id") DEFERRABLE INITIALLY DEFERRED,
    "tax_status" varchar(255) NOT NULL,
    "added_date" date NOT NULL,
    "modified_date" date NOT NULL,
    "org_name" varchar(255) NOT NULL
)
;
CREATE TABLE "decc_form_project" (
    "id" serial NOT NULL PRIMARY KEY,
    "billable_id" integer NOT NULL REFERENCES "decc_form_billable" ("id") DEFERRABLE INITIALLY DEFERRED,
    "start_date" date NOT NULL,
    "end_date" date,
    "order_frequency" integer,
    "estimated_item_count" integer,
    "notes" text,
    "added_date" date NOT NULL,
    "modified_date" date NOT NULL,
    "invoice_date" date
)
;
CREATE TABLE "decc_form_client" (
    "id" serial NOT NULL PRIMARY KEY,
    "address_id" integer NOT NULL REFERENCES "decc_form_address" ("id") DEFERRABLE INITIALLY DEFERRED,
    "project_id" integer NOT NULL REFERENCES "decc_form_project" ("id") DEFERRABLE INITIALLY DEFERRED,
    "org_name" varchar(255) NOT NULL,
    "added_date" timestamp with time zone NOT NULL,
    "modified_date" timestamp with time zone NOT NULL
)
;
CREATE TABLE "decc_form_clientcontact" (
    "id" serial NOT NULL PRIMARY KEY,
    "client_id" integer NOT NULL REFERENCES "decc_form_client" ("id") DEFERRABLE INITIALLY DEFERRED,
    "contact_id" integer NOT NULL REFERENCES "decc_form_contact" ("id") DEFERRABLE INITIALLY DEFERRED,
    "order" integer NOT NULL
)
;
CREATE TABLE "decc_form_type" (
    "id" serial NOT NULL PRIMARY KEY,
    "project_id" integer NOT NULL REFERENCES "decc_form_project" ("id") DEFERRABLE INITIALLY DEFERRED,
    "type_name" varchar(255) NOT NULL,
    "field_notes" text,
    "cost_rate" numeric(4, 2) NOT NULL,
    "cost_noi" numeric(5, 3) NOT NULL
)
;
CREATE TABLE "decc_form_committee_projects" (
    "id" serial NOT NULL PRIMARY KEY,
    "committee_id" integer NOT NULL,
    "project_id" integer NOT NULL REFERENCES "decc_form_project" ("id") DEFERRABLE INITIALLY DEFERRED,
    UNIQUE ("committee_id", "project_id")
)
;
CREATE TABLE "decc_form_committee" (
    "id" serial NOT NULL PRIMARY KEY,
    "name" varchar(255) NOT NULL
)
;
ALTER TABLE "decc_form_committee_projects" ADD CONSTRAINT "committee_id_refs_id_4cb2100d" FOREIGN KEY ("committee_id") REFERENCES "decc_form_committee" ("id") DEFERRABLE INITIALLY DEFERRED;

CREATE TABLE "decc_form_order" (
    "id" serial NOT NULL PRIMARY KEY,
    "project_id" integer NOT NULL REFERENCES "decc_form_project" ("id") DEFERRABLE INITIALLY DEFERRED,
    "order_date" date NOT NULL,
    "digital" boolean NOT NULL,
    "bill_date" date,
    "paid_date" date
)
;
CREATE TABLE "decc_form_part" (
    "id" serial NOT NULL PRIMARY KEY,
    "order_id" integer NOT NULL REFERENCES "decc_form_order" ("id") DEFERRABLE INITIALLY DEFERRED,
    "form_type_id" integer NOT NULL REFERENCES "decc_form_type" ("id") DEFERRABLE INITIALLY DEFERRED,
    "rush" boolean NOT NULL,
    "state" varchar(2) NOT NULL,
    "item_count" integer NOT NULL,
    "batch_count" integer NOT NULL,
    "van" boolean NOT NULL,
    "quad" boolean NOT NULL,
    "match" boolean NOT NULL,
    "destroy_files" boolean NOT NULL,
    "return_files" boolean NOT NULL,
    "extras" varchar(255)
)
;
CREATE TABLE "decc_form_batch" (
    "id" integer CHECK ("id" >= 0) NOT NULL PRIMARY KEY,
    "part_id" integer NOT NULL REFERENCES "decc_form_part" ("id") DEFERRABLE INITIALLY DEFERRED,
    "committee_id" integer REFERENCES "decc_form_committee" ("id") DEFERRABLE INITIALLY DEFERRED,
    "client_filename" varchar(100) NOT NULL,
    "vendor_filename" varchar(255) NOT NULL,
    "item_count" integer,
    "final_item_count" integer,
    "submission_date" date NOT NULL,
    "processed_date" date,
    "return_date" date
)
;
CREATE TABLE "decc_form_registrant" (
    "id" serial NOT NULL PRIMARY KEY,
    "batch_id" integer NOT NULL REFERENCES "decc_form_batch" ("id") DEFERRABLE INITIALLY DEFERRED,
    "citizenship" varchar(255),
    "age" varchar(10),
    "dob_mm" varchar(2),
    "dob_dd" varchar(2),
    "dob_yy" varchar(4),
    "first_name" varchar(255),
    "middle_name" varchar(255),
    "last_name" varchar(255),
    "suffix" varchar(64),
    "home_area_code" varchar(16),
    "home_phone" varchar(32),
    "race" varchar(255),
    "party" varchar(255),
    "gender" varchar(64),
    "date_signed_mm" varchar(2),
    "date_signed_dd" varchar(2),
    "date_signed_yy" varchar(4),
    "mobile_area_code" varchar(16),
    "mobile_phone" varchar(32),
    "email_address" varchar(255),
    "volunteer" varchar(255),
    "previous_name" varchar(255),
    "bad_image" varchar(32),
    "error_code" integer
)
;
CREATE TABLE "decc_form_registrantaddress" (
    "id" serial NOT NULL PRIMARY KEY,
    "registrant_id" integer NOT NULL REFERENCES "decc_form_registrant" ("id") DEFERRABLE INITIALLY DEFERRED,
    "address_id" integer NOT NULL REFERENCES "decc_form_address" ("id") DEFERRABLE INITIALLY DEFERRED,
    "address_type" varchar(20) NOT NULL
)
;
CREATE INDEX "decc_form_billable_contact_id" ON "decc_form_billable" ("contact_id");
CREATE INDEX "decc_form_billable_address_id" ON "decc_form_billable" ("address_id");
CREATE INDEX "decc_form_project_billable_id" ON "decc_form_project" ("billable_id");
CREATE INDEX "decc_form_client_address_id" ON "decc_form_client" ("address_id");
CREATE INDEX "decc_form_client_project_id" ON "decc_form_client" ("project_id");
CREATE INDEX "decc_form_clientcontact_client_id" ON "decc_form_clientcontact" ("client_id");
CREATE INDEX "decc_form_clientcontact_contact_id" ON "decc_form_clientcontact" ("contact_id");
CREATE INDEX "decc_form_type_project_id" ON "decc_form_type" ("project_id");
CREATE INDEX "decc_form_committee_projects_committee_id" ON "decc_form_committee_projects" ("committee_id");
CREATE INDEX "decc_form_committee_projects_project_id" ON "decc_form_committee_projects" ("project_id");
CREATE INDEX "decc_form_order_project_id" ON "decc_form_order" ("project_id");
CREATE INDEX "decc_form_part_order_id" ON "decc_form_part" ("order_id");
CREATE INDEX "decc_form_part_form_type_id" ON "decc_form_part" ("form_type_id");
CREATE INDEX "decc_form_batch_part_id" ON "decc_form_batch" ("part_id");
CREATE INDEX "decc_form_batch_committee_id" ON "decc_form_batch" ("committee_id");
CREATE INDEX "decc_form_registrant_batch_id" ON "decc_form_registrant" ("batch_id");
CREATE INDEX "decc_form_registrantaddress_registrant_id" ON "decc_form_registrantaddress" ("registrant_id");
CREATE INDEX "decc_form_registrantaddress_address_id" ON "decc_form_registrantaddress" ("address_id");

COMMIT;
