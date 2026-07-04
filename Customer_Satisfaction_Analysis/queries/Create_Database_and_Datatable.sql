DROP DATABASE IF EXISTS olist_ecommerce;
CREATE DATABASE olist_ecommerce
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE olist_ecommerce;

CREATE TABLE customers (
    customer_id             VARCHAR(50)     NOT NULL,
    customer_unique_id      VARCHAR(50)     NOT NULL,
    customer_zip_code_prefix VARCHAR(10)   NULL,
    customer_city           VARCHAR(100)    NULL,
    customer_state          CHAR(2)         NULL,
    PRIMARY KEY (customer_id),
    INDEX idx_customer_unique (customer_unique_id),
    INDEX idx_customer_state  (customer_state)
);


CREATE TABLE sellers (
    seller_id               VARCHAR(50)     NOT NULL,
    seller_zip_code_prefix  VARCHAR(10)     NULL,
    seller_city             VARCHAR(100)    NULL,
    seller_state            CHAR(2)         NULL,
    PRIMARY KEY (seller_id),
    INDEX idx_seller_state (seller_state)
);


CREATE TABLE geolocation (
    geolocation_zip_code_prefix VARCHAR(10) NOT NULL,
    geolocation_lat             DECIMAL(18,15) NULL,
    geolocation_lng             DECIMAL(18,15) NULL,
    geolocation_city            VARCHAR(100)   NULL,
    geolocation_state           CHAR(2)        NULL,
    PRIMARY KEY (geolocation_zip_code_prefix)
);


CREATE TABLE product_category_name_translation (
    product_category_name           VARCHAR(100)    NOT NULL,
    product_category_name_english   VARCHAR(100)    NULL,
    PRIMARY KEY (product_category_name)
);


CREATE TABLE products (
    product_id                      VARCHAR(50)     NOT NULL,
    product_category_name           VARCHAR(100)    NULL,
    product_category_name_english   VARCHAR(100)    NULL,   
    category_missing_flag           VARCHAR(30)     NULL,   
    PRIMARY KEY (product_id),
    INDEX idx_product_category (product_category_name_english)
);


CREATE TABLE orders (
    order_id                    VARCHAR(50)     NOT NULL,
    customer_id                 VARCHAR(50)     NOT NULL,
    order_status                VARCHAR(20)     NULL,
    purchase_date               DATETIME        NULL,
    approved_date               DATETIME        NULL,
    carrier_pickup_date         DATETIME        NULL,
    delivered_date              DATETIME        NULL,
    estimated_delivery_date     DATETIME        NULL,
    data_quality_flag			VARCHAR(30)		NULL,
    delivery_duration_days      INT             NULL,   
    delivery_delay_days         INT             NULL,  
    delay_bucket                VARCHAR(20)     NULL,   
    delivery_outlier_flag       VARCHAR(25)     NULL,  
    PRIMARY KEY (order_id),
    FOREIGN KEY (customer_id)   REFERENCES customers(customer_id),
    INDEX idx_order_status      (order_status),
    INDEX idx_purchase_date     (purchase_date),
    INDEX idx_delay_bucket      (delay_bucket),
    INDEX idx_customer_id       (customer_id)
);


CREATE TABLE order_items (
    order_id                VARCHAR(50)     NOT NULL,
    order_item_id           INT             NOT NULL,  
    product_id              VARCHAR(50)     NOT NULL,
    seller_id               VARCHAR(50)     NOT NULL,
    shipping_limit_date     DATETIME        NULL,
    price                   DECIMAL(10,2)   NULL,
    freight_value           DECIMAL(10,2)   NULL,
	free_shipping_flag      VARCHAR(20)     NULL,       
    item_total_value        DECIMAL(10,2)   NULL,       
    PRIMARY KEY (order_id, order_item_id),
    FOREIGN KEY (order_id)   REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (seller_id)  REFERENCES sellers(seller_id),
    INDEX idx_oi_product (product_id),
    INDEX idx_oi_seller  (seller_id)
);


CREATE TABLE order_reviews (
    review_id               VARCHAR(50)     NOT NULL,
    order_id                VARCHAR(50)     NOT NULL,
    review_score            TINYINT         NOT NULL,   
    review_comment_title    TEXT            NULL,       
    review_comment_message  TEXT            NULL,       
    review_creation_date    DATETIME        NULL,
    review_answer_timestamp DATETIME        NULL,
    satisfaction_tier       VARCHAR(10)     NOT NULL,   
    PRIMARY KEY (review_id),
    FOREIGN KEY (order_id)  REFERENCES orders(order_id),
    INDEX idx_review_score  (review_score),
    INDEX idx_satisfaction  (satisfaction_tier),
    INDEX idx_review_date   (review_creation_date)
);


CREATE TABLE order_payments (
    order_id                VARCHAR(50)     NOT NULL,
    payment_sequential      INT             NOT NULL,   
    payment_type            VARCHAR(30)     NULL,
    payment_installments    INT             NULL,
    payment_value           DECIMAL(10,2)   NULL,
    zero_value_payment_flag         VARCHAR(20)     NULL,     
    PRIMARY KEY (order_id, payment_sequential),
    FOREIGN KEY (order_id)  REFERENCES orders(order_id),
    INDEX idx_payment_type  (payment_type)
);