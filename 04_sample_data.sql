-- ============================================================================
-- SAMPLE DATA
-- ============================================================================
-- PURPOSE: Populate tables with realistic test data for demonstration.
--
-- NOTE: Run after schema, constraints, and indexes are created.
-- ============================================================================

SET search_path TO ecommerce;

-- ============================================================================
-- CATEGORIES
-- ============================================================================

INSERT INTO categories (category_id, parent_category_id, name, slug, description, sort_order) VALUES
-- Top-level categories
(1, NULL, 'Electronics', 'electronics', 'Electronic devices and accessories', 1),
(2, NULL, 'Clothing', 'clothing', 'Apparel and fashion', 2),
(3, NULL, 'Home & Garden', 'home-garden', 'Home improvement and garden supplies', 3),
(4, NULL, 'Sports & Outdoors', 'sports-outdoors', 'Sporting goods and outdoor equipment', 4),

-- Electronics subcategories
(5, 1, 'Computers', 'computers', 'Laptops, desktops, and accessories', 1),
(6, 1, 'Smartphones', 'smartphones', 'Mobile phones and accessories', 2),
(7, 1, 'Audio', 'audio', 'Headphones, speakers, and audio equipment', 3),

-- Clothing subcategories
(8, 2, 'Men''s Clothing', 'mens-clothing', 'Apparel for men', 1),
(9, 2, 'Women''s Clothing', 'womens-clothing', 'Apparel for women', 2),
(10, 2, 'Shoes', 'shoes', 'Footwear for all', 3);

-- Reset sequence
SELECT setval('categories_category_id_seq', 10);


-- ============================================================================
-- CUSTOMERS
-- ============================================================================

INSERT INTO customers (customer_id, email, password_hash, first_name, last_name, phone, email_verified) VALUES
(1, 'john.smith@email.com', '$2a$10$abc123hashedpassword', 'John', 'Smith', '555-0101', true),
(2, 'sarah.johnson@email.com', '$2a$10$def456hashedpassword', 'Sarah', 'Johnson', '555-0102', true),
(3, 'mike.williams@email.com', '$2a$10$ghi789hashedpassword', 'Mike', 'Williams', '555-0103', true),
(4, 'emily.brown@email.com', '$2a$10$jkl012hashedpassword', 'Emily', 'Brown', '555-0104', false),
(5, 'david.jones@email.com', '$2a$10$mno345hashedpassword', 'David', 'Jones', '555-0105', true);

SELECT setval('customers_customer_id_seq', 5);


-- ============================================================================
-- ADDRESSES
-- ============================================================================

INSERT INTO addresses (address_id, customer_id, address_type, address_line1, address_line2, city, state, postal_code, country, is_default) VALUES
-- John's addresses
(1, 1, 'both', '123 Main Street', 'Apt 4B', 'New York', 'NY', '10001', 'United States', true),
(2, 1, 'shipping', '456 Work Avenue', 'Suite 100', 'New York', 'NY', '10002', 'United States', false),

-- Sarah's address
(3, 2, 'both', '789 Oak Lane', NULL, 'Los Angeles', 'CA', '90001', 'United States', true),

-- Mike's addresses
(4, 3, 'shipping', '321 Pine Road', NULL, 'Chicago', 'IL', '60601', 'United States', true),
(5, 3, 'billing', '654 Corporate Blvd', 'Floor 5', 'Chicago', 'IL', '60602', 'United States', false),

-- Emily's address
(6, 4, 'both', '987 Elm Street', NULL, 'Houston', 'TX', '77001', 'United States', true),

-- David's address
(7, 5, 'both', '147 Maple Drive', 'Unit 2', 'Phoenix', 'AZ', '85001', 'United States', true);

SELECT setval('addresses_address_id_seq', 7);


-- ============================================================================
-- PRODUCTS
-- ============================================================================

INSERT INTO products (product_id, sku, name, description, unit_price, compare_at_price, cost_price, quantity_on_hand, reorder_level, is_active, is_featured) VALUES
-- Electronics
(1, 'ELEC-LP-001', 'ProBook Laptop 15"', 'High-performance laptop with 16GB RAM and 512GB SSD', 999.99, 1199.99, 650.00, 50, 10, true, true),
(2, 'ELEC-PH-001', 'SmartPhone X12', 'Latest smartphone with 128GB storage and 5G capability', 799.99, NULL, 500.00, 100, 20, true, true),
(3, 'ELEC-HP-001', 'Wireless Headphones Pro', 'Noise-cancelling over-ear headphones', 249.99, 299.99, 120.00, 75, 15, true, false),
(4, 'ELEC-SP-001', 'Bluetooth Speaker Mini', 'Portable waterproof speaker', 79.99, NULL, 35.00, 200, 25, true, false),

-- Clothing
(5, 'CLTH-MS-001', 'Classic Oxford Shirt', '100% cotton button-down shirt', 59.99, NULL, 20.00, 150, 30, true, false),
(6, 'CLTH-WD-001', 'Summer Dress Collection', 'Floral print midi dress', 89.99, 119.99, 35.00, 80, 15, true, true),
(7, 'CLTH-SH-001', 'Running Shoes Elite', 'Lightweight performance running shoes', 129.99, NULL, 55.00, 60, 12, true, false),

-- Home & Garden
(8, 'HOME-LM-001', 'Smart LED Lamp', 'WiFi-enabled color-changing lamp', 49.99, 69.99, 18.00, 120, 20, true, false),
(9, 'HOME-PT-001', 'Indoor Plant Set', 'Set of 3 low-maintenance indoor plants', 39.99, NULL, 15.00, 40, 10, true, false),

-- Sports
(10, 'SPRT-YM-001', 'Yoga Mat Premium', 'Extra-thick non-slip yoga mat', 34.99, NULL, 12.00, 90, 20, true, false);

SELECT setval('products_product_id_seq', 10);


-- ============================================================================
-- PRODUCT_CATEGORIES
-- ============================================================================

INSERT INTO product_categories (product_id, category_id, is_primary) VALUES
-- Laptop -> Electronics, Computers
(1, 1, false),
(1, 5, true),

-- Phone -> Electronics, Smartphones
(2, 1, false),
(2, 6, true),

-- Headphones -> Electronics, Audio
(3, 1, false),
(3, 7, true),

-- Speaker -> Electronics, Audio
(4, 1, false),
(4, 7, true),

-- Shirt -> Clothing, Men's
(5, 2, false),
(5, 8, true),

-- Dress -> Clothing, Women's
(6, 2, false),
(6, 9, true),

-- Shoes -> Clothing, Shoes
(7, 2, false),
(7, 10, true),

-- Lamp -> Home & Garden
(8, 3, true),

-- Plants -> Home & Garden
(9, 3, true),

-- Yoga Mat -> Sports
(10, 4, true);


-- ============================================================================
-- ORDERS
-- ============================================================================

INSERT INTO orders (order_id, customer_id, order_number, status, shipping_address_id, billing_address_id, subtotal, tax_amount, shipping_amount, discount_amount, ordered_at, shipped_at, delivered_at, customer_notes) VALUES
-- John's orders
(1, 1, 'ORD-2024-00001', 'delivered', 1, 1, 1249.98, 109.37, 0.00, 0.00, '2024-01-15 10:30:00', '2024-01-16 14:00:00', '2024-01-19 11:00:00', NULL),
(2, 1, 'ORD-2024-00005', 'shipped', 2, 1, 79.99, 7.00, 5.99, 0.00, '2024-03-01 15:45:00', '2024-03-02 09:00:00', NULL, 'Please leave at door'),

-- Sarah's order
(3, 2, 'ORD-2024-00002', 'delivered', 3, 3, 889.98, 77.87, 0.00, 50.00, '2024-01-20 09:15:00', '2024-01-21 10:00:00', '2024-01-24 14:30:00', NULL),

-- Mike's orders
(4, 3, 'ORD-2024-00003', 'processing', 4, 5, 164.98, 14.44, 5.99, 0.00, '2024-02-10 11:00:00', NULL, NULL, NULL),
(5, 3, 'ORD-2024-00006', 'pending', 4, 5, 999.99, 87.50, 0.00, 100.00, '2024-03-05 16:30:00', NULL, NULL, 'Gift wrap please'),

-- Emily's order
(6, 4, 'ORD-2024-00004', 'cancelled', 6, 6, 59.99, 5.25, 5.99, 0.00, '2024-02-25 14:20:00', NULL, NULL, NULL);

SELECT setval('orders_order_id_seq', 6);


-- ============================================================================
-- ORDER_ITEMS
-- ============================================================================

INSERT INTO order_items (item_id, order_id, product_id, product_name, sku, unit_price, quantity) VALUES
-- Order 1: Laptop + Headphones
(1, 1, 1, 'ProBook Laptop 15"', 'ELEC-LP-001', 999.99, 1),
(2, 1, 3, 'Wireless Headphones Pro', 'ELEC-HP-001', 249.99, 1),

-- Order 2: Speaker
(3, 2, 4, 'Bluetooth Speaker Mini', 'ELEC-SP-001', 79.99, 1),

-- Order 3: Phone + Dress
(4, 3, 2, 'SmartPhone X12', 'ELEC-PH-001', 799.99, 1),
(5, 3, 6, 'Summer Dress Collection', 'CLTH-WD-001', 89.99, 1),

-- Order 4: Shoes + Yoga Mat
(6, 4, 7, 'Running Shoes Elite', 'CLTH-SH-001', 129.99, 1),
(7, 4, 10, 'Yoga Mat Premium', 'SPRT-YM-001', 34.99, 1),

-- Order 5: Laptop
(8, 5, 1, 'ProBook Laptop 15"', 'ELEC-LP-001', 999.99, 1),

-- Order 6: Shirt (cancelled)
(9, 6, 5, 'Classic Oxford Shirt', 'CLTH-MS-001', 59.99, 1);

SELECT setval('order_items_item_id_seq', 9);


-- ============================================================================
-- PAYMENTS
-- ============================================================================

INSERT INTO payments (payment_id, order_id, payment_method, status, amount, transaction_id, processed_at) VALUES
(1, 1, 'credit_card', 'captured', 1359.35, 'TXN-CC-001', '2024-01-15 10:31:00'),
(2, 2, 'credit_card', 'captured', 92.98, 'TXN-CC-002', '2024-03-01 15:46:00'),
(3, 3, 'paypal', 'captured', 917.85, 'TXN-PP-001', '2024-01-20 09:16:00'),
(4, 4, 'credit_card', 'captured', 185.41, 'TXN-CC-003', '2024-02-10 11:01:00'),
(5, 5, 'credit_card', 'authorized', 987.49, 'TXN-CC-004', '2024-03-05 16:31:00'),
(6, 6, 'credit_card', 'refunded', 71.23, 'TXN-CC-005', '2024-02-25 14:21:00');

SELECT setval('payments_payment_id_seq', 6);


-- ============================================================================
-- REVIEWS
-- ============================================================================

INSERT INTO reviews (review_id, product_id, customer_id, rating, title, body, is_verified, is_approved) VALUES
(1, 1, 1, 5, 'Excellent laptop!', 'Fast, reliable, and great battery life. Highly recommend!', true, true),
(2, 3, 1, 4, 'Great sound quality', 'Noise cancellation is impressive. Slightly tight fit.', true, true),
(3, 2, 2, 5, 'Best phone I''ve owned', 'Camera is amazing and 5G is super fast.', true, true),
(4, 6, 2, 4, 'Beautiful dress', 'Lovely pattern, runs slightly large.', true, true),
(5, 7, 3, 5, 'Perfect running shoes', 'Very comfortable for long runs.', true, true);

SELECT setval('reviews_review_id_seq', 5);


-- ============================================================================
-- CART_ITEMS (current shopping carts)
-- ============================================================================

INSERT INTO cart_items (cart_item_id, customer_id, product_id, quantity) VALUES
(1, 4, 8, 2),   -- Emily has 2 lamps in cart
(2, 4, 9, 1),   -- Emily has 1 plant set in cart
(3, 5, 3, 1);   -- David has headphones in cart

SELECT setval('cart_items_cart_item_id_seq', 3);


-- ============================================================================
-- VERIFY DATA LOAD
-- ============================================================================

SELECT 'categories' AS table_name, COUNT(*) AS row_count FROM categories
UNION ALL SELECT 'customers', COUNT(*) FROM customers
UNION ALL SELECT 'addresses', COUNT(*) FROM addresses
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'product_categories', COUNT(*) FROM product_categories
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'payments', COUNT(*) FROM payments
UNION ALL SELECT 'reviews', COUNT(*) FROM reviews
UNION ALL SELECT 'cart_items', COUNT(*) FROM cart_items
ORDER BY table_name;
