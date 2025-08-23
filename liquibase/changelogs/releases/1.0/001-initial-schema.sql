--liquibase formatted sql

--changeset liquibase:001-create-customers
CREATE TABLE IF NOT EXISTS PUBLIC.CUSTOMERS (
    customer_id NUMBER PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);
--rollback DROP TABLE PUBLIC.CUSTOMERS;

--changeset liquibase:002-create-products
CREATE TABLE IF NOT EXISTS PUBLIC.PRODUCTS (
    product_id NUMBER PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL,
    category VARCHAR(100),
    price DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);
--rollback DROP TABLE PUBLIC.PRODUCTS;

--changeset liquibase:003-create-orders
CREATE TABLE IF NOT EXISTS PUBLIC.ORDERS (
    order_id NUMBER PRIMARY KEY,
    customer_id NUMBER NOT NULL,
    order_date DATE NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    FOREIGN KEY (customer_id) REFERENCES PUBLIC.CUSTOMERS(customer_id)
);
--rollback DROP TABLE PUBLIC.ORDERS;

--changeset liquibase:004-create-order-items
CREATE TABLE IF NOT EXISTS PUBLIC.ORDER_ITEMS (
    order_item_id NUMBER PRIMARY KEY,
    order_id NUMBER NOT NULL,
    product_id NUMBER NOT NULL,
    quantity NUMBER NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    line_total DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES PUBLIC.ORDERS(order_id),
    FOREIGN KEY (product_id) REFERENCES PUBLIC.PRODUCTS(product_id)
);
--rollback DROP TABLE PUBLIC.ORDER_ITEMS;