-- ============================================================================
-- INDEXES
-- ============================================================================
-- PURPOSE: Create indexes to support query performance.
--
-- PHILOSOPHY:
--   - Every foreign key gets an index (PostgreSQL doesn't auto-create these)
--   - Common query patterns get supporting indexes
--   - Partial indexes for filtered queries
--   - Covering indexes for high-frequency queries
--
-- NOTE: Primary keys and UNIQUE constraints auto-create indexes
-- ============================================================================

SET search_path TO ecommerce;

-- ============================================================================
-- FOREIGN KEY INDEXES
-- ============================================================================
-- Critical for JOIN performance - without these, JOINs cause sequential scans

-- Addresses
CREATE INDEX ix_addresses_customer_id 
ON addresses(customer_id);

-- Product_Categories (composite PK handles product_id, category_id)
-- No additional indexes needed

-- Orders
CREATE INDEX ix_orders_customer_id 
ON orders(customer_id);

CREATE INDEX ix_orders_shipping_address 
ON orders(shipping_address_id) 
WHERE shipping_address_id IS NOT NULL;

CREATE INDEX ix_orders_billing_address 
ON orders(billing_address_id) 
WHERE billing_address_id IS NOT NULL;

-- Order_Items
CREATE INDEX ix_orderitems_order_id 
ON order_items(order_id);

CREATE INDEX ix_orderitems_product_id 
ON order_items(product_id);

-- Payments
CREATE INDEX ix_payments_order_id 
ON payments(order_id);

-- Reviews
CREATE INDEX ix_reviews_product_id 
ON reviews(product_id);

CREATE INDEX ix_reviews_customer_id 
ON reviews(customer_id);

-- Cart_Items
CREATE INDEX ix_cartitems_customer_id 
ON cart_items(customer_id);

CREATE INDEX ix_cartitems_product_id 
ON cart_items(product_id);

-- Categories (self-reference)
CREATE INDEX ix_categories_parent_id 
ON categories(parent_category_id) 
WHERE parent_category_id IS NOT NULL;


-- ============================================================================
-- QUERY PATTERN INDEXES
-- ============================================================================
-- Based on expected application queries

-- Customer lookup by email (login)
-- Already covered by UNIQUE constraint on email

-- Orders by status (admin dashboard, order processing)
CREATE INDEX ix_orders_status 
ON orders(status);

-- Orders by date range (reporting, recent orders)
CREATE INDEX ix_orders_ordered_at 
ON orders(ordered_at DESC);

-- Combined: Recent orders by status (common admin query)
CREATE INDEX ix_orders_status_date 
ON orders(status, ordered_at DESC);

-- Products by active status (storefront)
CREATE INDEX ix_products_active 
ON products(is_active) 
WHERE is_active = true;

-- Featured products (homepage)
CREATE INDEX ix_products_featured 
ON products(is_featured) 
WHERE is_featured = true AND is_active = true;

-- Products by price range (filtering)
CREATE INDEX ix_products_price 
ON products(unit_price);

-- Low stock alert (inventory management)
CREATE INDEX ix_products_low_stock 
ON products(quantity_on_hand) 
WHERE quantity_on_hand <= reorder_level AND is_active = true;

-- Reviews by product with rating (product page)
CREATE INDEX ix_reviews_product_rating 
ON reviews(product_id, rating DESC) 
WHERE is_approved = true;

-- Payment by status (reconciliation)
CREATE INDEX ix_payments_status 
ON payments(status);


-- ============================================================================
-- COVERING INDEXES
-- ============================================================================
-- Include extra columns to enable index-only scans

-- Order listing (avoid heap access for common query)
CREATE INDEX ix_orders_customer_covering 
ON orders(customer_id, ordered_at DESC) 
INCLUDE (order_number, status, total_amount);

-- Product listing for category page
CREATE INDEX ix_products_listing 
ON products(is_active, created_at DESC) 
INCLUDE (name, unit_price, quantity_on_hand)
WHERE is_active = true;


-- ============================================================================
-- TEXT SEARCH INDEXES (Optional)
-- ============================================================================
-- For product search functionality

-- Full-text search on product name and description
CREATE INDEX ix_products_search 
ON products 
USING GIN (to_tsvector('english', name || ' ' || COALESCE(description, '')));

-- Trigram index for fuzzy matching (requires pg_trgm extension)
-- CREATE EXTENSION IF NOT EXISTS pg_trgm;
-- CREATE INDEX ix_products_name_trgm ON products USING GIN (name gin_trgm_ops);


-- ============================================================================
-- VERIFY INDEXES
-- ============================================================================

SELECT 
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'ecommerce'
  AND indexname NOT LIKE '%_pkey'  -- Exclude auto-created PK indexes
ORDER BY tablename, indexname;


-- ============================================================================
-- INDEX DOCUMENTATION
-- ============================================================================
/*
INDEX STRATEGY SUMMARY:

| Index Type          | Use Case                          | Example                    |
|---------------------|-----------------------------------|----------------------------|
| B-tree (default)    | Equality, range, sorting          | ix_orders_status           |
| Partial             | Queries with consistent filter    | ix_products_active         |
| Covering (INCLUDE)  | Avoid heap access                 | ix_orders_customer_covering|
| GIN                 | Full-text search, arrays, JSONB   | ix_products_search         |
| Expression          | Functions in WHERE clause         | (not shown - see SARGable) |

MAINTENANCE NOTES:
- Run ANALYZE after bulk inserts to update statistics
- Monitor with pg_stat_user_indexes for unused indexes
- Consider REINDEX if bloat becomes significant
- Watch for index-only scan opportunities in EXPLAIN output
*/
