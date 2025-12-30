-- ============================================================================
-- E-COMMERCE DATABASE SCHEMA
-- ============================================================================
-- PURPOSE: Create the core tables for an e-commerce platform.
--
-- DESIGN PRINCIPLES:
--   - Surrogate keys (SERIAL) for all tables
--   - Audit columns on every table (created_at, updated_at)
--   - Soft deletes where business requires history
--   - PostgreSQL-specific features (ENUM, GENERATED columns)
-- ============================================================================

-- Create dedicated schema
DROP SCHEMA IF EXISTS ecommerce CASCADE;
CREATE SCHEMA ecommerce;
SET search_path TO ecommerce;

-- ============================================================================
-- CUSTOM TYPES (PostgreSQL ENUMs)
-- ============================================================================
-- ENUMs provide type safety and self-documenting allowed values

CREATE TYPE order_status AS ENUM (
    'pending',
    'confirmed',
    'processing',
    'shipped',
    'delivered',
    'cancelled',
    'refunded'
);

CREATE TYPE payment_status AS ENUM (
    'pending',
    'authorized',
    'captured',
    'failed',
    'refunded'
);

CREATE TYPE address_type AS ENUM (
    'billing',
    'shipping',
    'both'
);

-- ============================================================================
-- CUSTOMERS TABLE
-- ============================================================================
-- Core customer information. Addresses stored separately for flexibility.

CREATE TABLE customers (
    customer_id         SERIAL PRIMARY KEY,
    email               VARCHAR(255) NOT NULL,
    password_hash       VARCHAR(255) NOT NULL,
    first_name          VARCHAR(100) NOT NULL,
    last_name           VARCHAR(100) NOT NULL,
    phone               VARCHAR(20),
    
    -- Account status
    is_active           BOOLEAN NOT NULL DEFAULT true,
    email_verified      BOOLEAN NOT NULL DEFAULT false,
    
    -- Soft delete support
    deleted_at          TIMESTAMP,
    
    -- Audit columns
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE customers IS 'Registered customer accounts';
COMMENT ON COLUMN customers.password_hash IS 'Bcrypt or similar hash - never store plaintext!';


-- ============================================================================
-- ADDRESSES TABLE
-- ============================================================================
-- Normalized addresses - customers can have multiple shipping/billing addresses

CREATE TABLE addresses (
    address_id          SERIAL PRIMARY KEY,
    customer_id         INT NOT NULL,
    address_type        address_type NOT NULL DEFAULT 'both',
    
    -- Address fields
    address_line1       VARCHAR(255) NOT NULL,
    address_line2       VARCHAR(255),
    city                VARCHAR(100) NOT NULL,
    state               VARCHAR(100),
    postal_code         VARCHAR(20) NOT NULL,
    country             VARCHAR(100) NOT NULL DEFAULT 'United States',
    
    -- Flags
    is_default          BOOLEAN NOT NULL DEFAULT false,
    
    -- Audit
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE addresses IS 'Customer shipping and billing addresses';


-- ============================================================================
-- CATEGORIES TABLE
-- ============================================================================
-- Hierarchical product categories using adjacency list pattern

CREATE TABLE categories (
    category_id         SERIAL PRIMARY KEY,
    parent_category_id  INT,                    -- NULL = top-level category
    name                VARCHAR(100) NOT NULL,
    slug                VARCHAR(100) NOT NULL,  -- URL-friendly name
    description         TEXT,
    
    -- Display
    sort_order          INT NOT NULL DEFAULT 0,
    is_active           BOOLEAN NOT NULL DEFAULT true,
    
    -- Audit
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE categories IS 'Hierarchical product categories';
COMMENT ON COLUMN categories.slug IS 'URL-friendly identifier (e.g., "mens-shoes")';


-- ============================================================================
-- PRODUCTS TABLE
-- ============================================================================
-- Core product catalog

CREATE TABLE products (
    product_id          SERIAL PRIMARY KEY,
    sku                 VARCHAR(50) NOT NULL,   -- Stock Keeping Unit
    name                VARCHAR(255) NOT NULL,
    description         TEXT,
    
    -- Pricing
    unit_price          NUMERIC(10,2) NOT NULL,
    compare_at_price    NUMERIC(10,2),          -- Original price for "sale" display
    cost_price          NUMERIC(10,2),          -- What we paid (for margin calc)
    
    -- Inventory
    quantity_on_hand    INT NOT NULL DEFAULT 0,
    reorder_level       INT NOT NULL DEFAULT 10,
    
    -- Status
    is_active           BOOLEAN NOT NULL DEFAULT true,
    is_featured         BOOLEAN NOT NULL DEFAULT false,
    
    -- SEO
    meta_title          VARCHAR(255),
    meta_description    VARCHAR(500),
    
    -- Soft delete
    deleted_at          TIMESTAMP,
    
    -- Audit
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE products IS 'Product catalog';
COMMENT ON COLUMN products.sku IS 'Unique stock keeping unit for inventory';
COMMENT ON COLUMN products.compare_at_price IS 'Strike-through price for sale items';


-- ============================================================================
-- PRODUCT_CATEGORIES (Junction Table)
-- ============================================================================
-- Many-to-many: Products can belong to multiple categories

CREATE TABLE product_categories (
    product_id          INT NOT NULL,
    category_id         INT NOT NULL,
    is_primary          BOOLEAN NOT NULL DEFAULT false,  -- Primary category for breadcrumbs
    
    PRIMARY KEY (product_id, category_id)
);

COMMENT ON TABLE product_categories IS 'Many-to-many relationship between products and categories';


-- ============================================================================
-- ORDERS TABLE
-- ============================================================================
-- Order header - one record per order

CREATE TABLE orders (
    order_id            SERIAL PRIMARY KEY,
    customer_id         INT NOT NULL,
    order_number        VARCHAR(50) NOT NULL,   -- Human-readable order number
    
    -- Status
    status              order_status NOT NULL DEFAULT 'pending',
    
    -- Addresses (denormalized snapshot at time of order)
    shipping_address_id INT,
    billing_address_id  INT,
    
    -- Totals
    subtotal            NUMERIC(12,2) NOT NULL DEFAULT 0,
    tax_amount          NUMERIC(12,2) NOT NULL DEFAULT 0,
    shipping_amount     NUMERIC(12,2) NOT NULL DEFAULT 0,
    discount_amount     NUMERIC(12,2) NOT NULL DEFAULT 0,
    total_amount        NUMERIC(12,2) GENERATED ALWAYS AS (
                            subtotal + tax_amount + shipping_amount - discount_amount
                        ) STORED,
    
    -- Dates
    ordered_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    shipped_at          TIMESTAMP,
    delivered_at        TIMESTAMP,
    cancelled_at        TIMESTAMP,
    
    -- Notes
    customer_notes      TEXT,
    internal_notes      TEXT,
    
    -- Audit
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE orders IS 'Order headers';
COMMENT ON COLUMN orders.order_number IS 'Human-readable order number (e.g., ORD-2024-00001)';
COMMENT ON COLUMN orders.total_amount IS 'Auto-calculated from components';


-- ============================================================================
-- ORDER_ITEMS TABLE
-- ============================================================================
-- Order line items - products in each order

CREATE TABLE order_items (
    item_id             SERIAL PRIMARY KEY,
    order_id            INT NOT NULL,
    product_id          INT NOT NULL,
    
    -- Snapshot at time of order (prices can change!)
    product_name        VARCHAR(255) NOT NULL,
    sku                 VARCHAR(50) NOT NULL,
    unit_price          NUMERIC(10,2) NOT NULL,
    
    -- Quantity
    quantity            INT NOT NULL,
    
    -- Calculated
    line_total          NUMERIC(12,2) GENERATED ALWAYS AS (unit_price * quantity) STORED,
    
    -- Audit
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE order_items IS 'Order line items';
COMMENT ON COLUMN order_items.unit_price IS 'Price at time of order - intentionally denormalized';


-- ============================================================================
-- PAYMENTS TABLE
-- ============================================================================
-- Payment records for orders (one order can have multiple payment attempts)

CREATE TABLE payments (
    payment_id          SERIAL PRIMARY KEY,
    order_id            INT NOT NULL,
    
    -- Payment details
    payment_method      VARCHAR(50) NOT NULL,   -- 'credit_card', 'paypal', etc.
    status              payment_status NOT NULL DEFAULT 'pending',
    amount              NUMERIC(12,2) NOT NULL,
    
    -- Gateway reference
    transaction_id      VARCHAR(255),           -- From payment processor
    gateway_response    JSONB,                  -- Full response for debugging
    
    -- Timestamps
    processed_at        TIMESTAMP,
    
    -- Audit
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE payments IS 'Payment transactions for orders';
COMMENT ON COLUMN payments.gateway_response IS 'Full JSON response from payment processor';


-- ============================================================================
-- REVIEWS TABLE
-- ============================================================================
-- Customer product reviews

CREATE TABLE reviews (
    review_id           SERIAL PRIMARY KEY,
    product_id          INT NOT NULL,
    customer_id         INT NOT NULL,
    
    -- Review content
    rating              SMALLINT NOT NULL,
    title               VARCHAR(255),
    body                TEXT,
    
    -- Moderation
    is_verified         BOOLEAN NOT NULL DEFAULT false,  -- Verified purchase
    is_approved         BOOLEAN NOT NULL DEFAULT false,  -- Moderation passed
    
    -- Audit
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE reviews IS 'Customer product reviews';
COMMENT ON COLUMN reviews.is_verified IS 'True if customer actually purchased this product';


-- ============================================================================
-- CART TABLE (Optional - for persistent carts)
-- ============================================================================
-- Shopping cart for logged-in users

CREATE TABLE cart_items (
    cart_item_id        SERIAL PRIMARY KEY,
    customer_id         INT NOT NULL,
    product_id          INT NOT NULL,
    quantity            INT NOT NULL DEFAULT 1,
    
    -- Audit
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE cart_items IS 'Persistent shopping cart for logged-in users';


-- ============================================================================
-- VERIFY TABLES CREATED
-- ============================================================================

SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'ecommerce'
ORDER BY table_name;
