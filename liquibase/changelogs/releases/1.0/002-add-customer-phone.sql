--liquibase formatted sql

--changeset liquibase:005-add-customer-phone-column
ALTER TABLE PUBLIC.CUSTOMERS 
ADD COLUMN phone VARCHAR(20);
--rollback ALTER TABLE PUBLIC.CUSTOMERS DROP COLUMN phone;