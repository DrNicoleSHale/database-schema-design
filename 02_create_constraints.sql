-- ============================================================================
-- CONSTRAINTS
-- ============================================================================
-- PURPOSE: Add foreign keys, unique constraints, and check constraints.
--
-- WHY SEPARATE FILE?
--   - Tables must exist before FK references
--   - Easier to manage/modify constraints independently
--   - Clear documentation of relationships
-- ============================================================================

SET search_path TO ecommerce;

-- ============================================================================
-- FOREIGN KEY CONSTRAINTS
-- ============================================================================
-- Naming convention: fk_childtable_parenttable

-- Addresses → Customers
ALTER TABLE addresses
ADD CONSTRAINT fk_addresses_customer
FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
ON DELETE CASCADE;  -- Delete addresses when customer is deleted

-- Categories (self-referencing for hierarchy)
ALTER TABLE categories
ADD CONSTRAINT fk_categories_parent
FOREIGN KEY (parent_category_id) REFERENCES categories(category_id)
ON DELETE SET NULL;  -- Orphan subcategories become top-level

-- Product_Categories → Products
ALTER TABLE product_categories
ADD CONSTRAINT fk_prodcat_product
FOREIGN KEY (product_id) REFERENCES products(product_id)
ON DELETE CASCADE;

-- Product_Categories → Categories
ALTER TABLE product_categories
ADD CONSTRAINT fk_prodcat_category
FOREIGN KEY (category_id) REFERENCES categories(category_id)
ON DELETE CASCADE;

-- Orders → Customers
ALTER TABLE orders
ADD CONSTRAINT fk_orders_customer
FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
ON DELETE RESTRICT;  -- Don't delete customers with orders!

-- Orders → Addresses (shipping)
ALTER TABLE orders
ADD CONSTRAINT fk_orders_shipping_address
FOREIGN KEY (shipping_address_id) REFERENCES addresses(address_id)
ON DELETE SET NULL;

-- Orders → Addresses (billing)
ALTER TABLE orders
ADD CONSTRAINT fk_orders_billing_address
FOREIGN KEY (billing_address_id) REFERENCES addresses(address_id)
ON DELETE SET NULL;

-- Order_Items → Orders
ALTER TABLE order_items
ADD CONSTRAINT fk_orderitems_order
FOREIGN KEY (order_id) REFERENCES orders(order_id)
ON DELETE CASCADE;  -- Delete items when order is deleted

-- Order_Items → Products
ALTER TABLE order_items
ADD CONSTRAINT fk_orderitems_product
FOREIGN KEY (product_id) REFERENCES products(product_id)
ON DELETE RESTRICT;  -- Don't delete products that were ordered

-- Payments → Orders
ALTER TABLE payments
ADD CONSTRAINT fk_payments_order
FOREIGN KEY (order_id) REFERENCES orders(order_id)
ON DELETE CASCADE;

-- Reviews → Products
ALTER TABLE reviews
ADD CONSTRAINT fk_reviews_product
FOREIGN KEY (product_id) REFERENCES products(product_id)
ON DELETE CASCADE;

-- Reviews → Customers
ALTER TABLE reviews
ADD CONSTRAINT fk_reviews_customer
FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
ON DELETE CASCADE;

-- Cart_Items → Customers
ALTER TABLE cart_items
ADD CONSTRAINT fk_cartitems_customer
FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
ON DELETE CASCADE;

-- Cart_Items → Products
ALTER TABLE cart_items
ADD CONSTRAINT fk_cartitems_product
FOREIGN KEY (product_id) REFERENCES products(product_id)
ON DELETE CASCADE;


-- ============================================================================
-- UNIQUE CONSTRAINTS
-- ============================================================================
-- Naming convention: uq_table_column(s)

-- Customer email must be unique
ALTER TABLE customers
ADD CONSTRAINT uq_customers_email
UNIQUE (email);

-- Category slug must be unique (for URLs)
ALTER TABLE categories
ADD CONSTRAINT uq_categories_slug
UNIQUE (slug);

-- Product SKU must be unique
ALTER TABLE products
ADD CONSTRAINT uq_products_sku
UNIQUE (sku);

-- Order number must be unique
ALTER TABLE orders
ADD CONSTRAINT uq_orders_number
UNIQUE (order_number);

-- One review per customer per product
ALTER TABLE reviews
ADD CONSTRAINT uq_reviews_customer_product
UNIQUE (customer_id, product_id);

-- One cart entry per customer per product
ALTER TABLE cart_items
ADD CONSTRAINT uq_cartitems_customer_product
UNIQUE (customer_id, product_id);


-- ============================================================================
-- CHECK CONSTRAINTS
-- ============================================================================
-- Naming convention: chk_table_description

-- Prices must be positive
ALTER TABLE products
ADD CONSTRAINT chk_products_price_positive
CHECK (unit_price >= 0);

ALTER TABLE products
ADD CONSTRAINT chk_products_compare_price
CHECK (compare_at_price IS NULL OR compare_at_price >= unit_price);

ALTER TABLE products
ADD CONSTRAINT chk_products_cost_positive
CHECK (cost_price IS NULL OR cost_price >= 0);

-- Inventory cannot be negative
ALTER TABLE products
ADD CONSTRAINT chk_products_quantity_nonneg
CHECK (quantity_on_hand >= 0);

-- Order amounts must be non-negative
ALTER TABLE orders
ADD CONSTRAINT chk_orders_subtotal_nonneg
CHECK (subtotal >= 0);

ALTER TABLE orders
ADD CONSTRAINT chk_orders_tax_nonneg
CHECK (tax_amount >= 0);

ALTER TABLE orders
ADD CONSTRAINT chk_orders_shipping_nonneg
CHECK (shipping_amount >= 0);

ALTER TABLE orders
ADD CONSTRAINT chk_orders_discount_nonneg
CHECK (discount_amount >= 0);

-- Order item quantity must be positive
ALTER TABLE order_items
ADD CONSTRAINT chk_orderitems_quantity_pos
CHECK (quantity > 0);

ALTER TABLE order_items
ADD CONSTRAINT chk_orderitems_price_nonneg
CHECK (unit_price >= 0);

-- Payment amount must be positive
ALTER TABLE payments
ADD CONSTRAINT chk_payments_amount_pos
CHECK (amount > 0);

-- Review rating must be 1-5
ALTER TABLE reviews
ADD CONSTRAINT chk_reviews_rating_range
CHECK (rating BETWEEN 1 AND 5);

-- Cart quantity must be positive
ALTER TABLE cart_items
ADD CONSTRAINT chk_cartitems_quantity_pos
CHECK (quantity > 0);

-- Email format validation (basic)
ALTER TABLE customers
ADD CONSTRAINT chk_customers_email_format
CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');


-- ============================================================================
-- VERIFY CONSTRAINTS
-- ============================================================================

SELECT 
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type
FROM information_schema.table_constraints tc
WHERE tc.table_schema = 'ecommerce'
ORDER BY tc.table_name, tc.constraint_type, tc.constraint_name;
