# Entity-Relationship Documentation

## Overview

This document describes the entities, attributes, and relationships in the e-commerce database schema.

---

## Entity Summary

| Entity | Description | Key Relationships |
|--------|-------------|-------------------|
| customers | Registered user accounts | Has many addresses, orders, reviews |
| addresses | Shipping/billing addresses | Belongs to customer |
| categories | Product category hierarchy | Self-referencing parent/child |
| products | Items for sale | Has many categories, reviews |
| orders | Purchase transactions | Belongs to customer, has many items |
| order_items | Line items in orders | Belongs to order and product |
| payments | Payment transactions | Belongs to order |
| reviews | Customer product reviews | Belongs to customer and product |
| cart_items | Shopping cart contents | Belongs to customer and product |

---

## Detailed Entity Descriptions

### customers
Primary entity for registered users.

| Attribute | Type | Nullable | Description |
|-----------|------|----------|-------------|
| customer_id | SERIAL | NO | Primary key |
| email | VARCHAR(255) | NO | Unique login identifier |
| password_hash | VARCHAR(255) | NO | Encrypted password |
| first_name | VARCHAR(100) | NO | Customer first name |
| last_name | VARCHAR(100) | NO | Customer last name |
| phone | VARCHAR(20) | YES | Contact phone |
| is_active | BOOLEAN | NO | Account status |
| email_verified | BOOLEAN | NO | Email confirmed |
| deleted_at | TIMESTAMP | YES | Soft delete marker |
| created_at | TIMESTAMP | NO | Record creation |
| updated_at | TIMESTAMP | NO | Last modification |

**Relationships:**
- ONE customer HAS MANY addresses
- ONE customer HAS MANY orders
- ONE customer HAS MANY reviews
- ONE customer HAS MANY cart_items

---

### addresses
Customer shipping and billing addresses.

| Attribute | Type | Nullable | Description |
|-----------|------|----------|-------------|
| address_id | SERIAL | NO | Primary key |
| customer_id | INT | NO | FK to customers |
| address_type | ENUM | NO | billing/shipping/both |
| address_line1 | VARCHAR(255) | NO | Street address |
| address_line2 | VARCHAR(255) | YES | Apt, suite, etc. |
| city | VARCHAR(100) | NO | City name |
| state | VARCHAR(100) | YES | State/province |
| postal_code | VARCHAR(20) | NO | ZIP/postal code |
| country | VARCHAR(100) | NO | Country name |
| is_default | BOOLEAN | NO | Default address flag |

**Relationships:**
- MANY addresses BELONG TO ONE customer
- ONE address CAN BE referenced by MANY orders

---

### categories
Hierarchical product categories.

| Attribute | Type | Nullable | Description |
|-----------|------|----------|-------------|
| category_id | SERIAL | NO | Primary key |
| parent_category_id | INT | YES | FK to self (parent) |
| name | VARCHAR(100) | NO | Display name |
| slug | VARCHAR(100) | NO | URL-friendly name |
| description | TEXT | YES | Category description |
| sort_order | INT | NO | Display ordering |
| is_active | BOOLEAN | NO | Visibility flag |

**Relationships:**
- ONE category HAS MANY subcategories (self-referencing)
- MANY categories HAVE MANY products (via product_categories)

---

### products
Items available for purchase.

| Attribute | Type | Nullable | Description |
|-----------|------|----------|-------------|
| product_id | SERIAL | NO | Primary key |
| sku | VARCHAR(50) | NO | Unique stock code |
| name | VARCHAR(255) | NO | Product name |
| description | TEXT | YES | Full description |
| unit_price | NUMERIC(10,2) | NO | Current price |
| compare_at_price | NUMERIC(10,2) | YES | Original price (for sales) |
| cost_price | NUMERIC(10,2) | YES | Wholesale cost |
| quantity_on_hand | INT | NO | Current inventory |
| reorder_level | INT | NO | Low stock threshold |
| is_active | BOOLEAN | NO | Available for sale |
| is_featured | BOOLEAN | NO | Homepage feature |
| deleted_at | TIMESTAMP | YES | Soft delete marker |

**Relationships:**
- MANY products HAVE MANY categories (via product_categories)
- ONE product HAS MANY order_items
- ONE product HAS MANY reviews
- ONE product HAS MANY cart_items

---

### product_categories
Junction table for many-to-many product/category relationship.

| Attribute | Type | Nullable | Description |
|-----------|------|----------|-------------|
| product_id | INT | NO | FK to products (PK) |
| category_id | INT | NO | FK to categories (PK) |
| is_primary | BOOLEAN | NO | Primary category flag |

**Relationships:**
- Links products and categories (many-to-many)

---

### orders
Purchase transaction headers.

| Attribute | Type | Nullable | Description |
|-----------|------|----------|-------------|
| order_id | SERIAL | NO | Primary key |
| customer_id | INT | NO | FK to customers |
| order_number | VARCHAR(50) | NO | Human-readable ID |
| status | ENUM | NO | Order status |
| shipping_address_id | INT | YES | FK to addresses |
| billing_address_id | INT | YES | FK to addresses |
| subtotal | NUMERIC(12,2) | NO | Sum of line items |
| tax_amount | NUMERIC(12,2) | NO | Tax charged |
| shipping_amount | NUMERIC(12,2) | NO | Shipping cost |
| discount_amount | NUMERIC(12,2) | NO | Discounts applied |
| total_amount | NUMERIC(12,2) | NO | **Generated:** Final total |
| ordered_at | TIMESTAMP | NO | Order placed time |
| shipped_at | TIMESTAMP | YES | Shipment time |
| delivered_at | TIMESTAMP | YES | Delivery time |

**Relationships:**
- MANY orders BELONG TO ONE customer
- ONE order HAS MANY order_items
- ONE order HAS MANY payments

---

### order_items
Line items within an order.

| Attribute | Type | Nullable | Description |
|-----------|------|----------|-------------|
| item_id | SERIAL | NO | Primary key |
| order_id | INT | NO | FK to orders |
| product_id | INT | NO | FK to products |
| product_name | VARCHAR(255) | NO | Snapshot of name |
| sku | VARCHAR(50) | NO | Snapshot of SKU |
| unit_price | NUMERIC(10,2) | NO | Snapshot of price |
| quantity | INT | NO | Quantity ordered |
| line_total | NUMERIC(12,2) | NO | **Generated:** price × qty |

**Relationships:**
- MANY order_items BELONG TO ONE order
- MANY order_items REFERENCE ONE product

---

### payments
Payment transactions for orders.

| Attribute | Type | Nullable | Description |
|-----------|------|----------|-------------|
| payment_id | SERIAL | NO | Primary key |
| order_id | INT | NO | FK to orders |
| payment_method | VARCHAR(50) | NO | credit_card, paypal, etc. |
| status | ENUM | NO | Payment status |
| amount | NUMERIC(12,2) | NO | Amount charged |
| transaction_id | VARCHAR(255) | YES | Gateway reference |
| gateway_response | JSONB | YES | Full gateway response |
| processed_at | TIMESTAMP | YES | Processing time |

**Relationships:**
- MANY payments BELONG TO ONE order

---

### reviews
Customer product reviews.

| Attribute | Type | Nullable | Description |
|-----------|------|----------|-------------|
| review_id | SERIAL | NO | Primary key |
| product_id | INT | NO | FK to products |
| customer_id | INT | NO | FK to customers |
| rating | SMALLINT | NO | 1-5 stars |
| title | VARCHAR(255) | YES | Review headline |
| body | TEXT | YES | Review content |
| is_verified | BOOLEAN | NO | Verified purchase |
| is_approved | BOOLEAN | NO | Moderation status |

**Relationships:**
- MANY reviews BELONG TO ONE product
- MANY reviews BELONG TO ONE customer
- UNIQUE constraint: one review per customer per product

---

### cart_items
Persistent shopping cart for logged-in users.

| Attribute | Type | Nullable | Description |
|-----------|------|----------|-------------|
| cart_item_id | SERIAL | NO | Primary key |
| customer_id | INT | NO | FK to customers |
| product_id | INT | NO | FK to products |
| quantity | INT | NO | Items in cart |

**Relationships:**
- MANY cart_items BELONG TO ONE customer
- MANY cart_items REFERENCE ONE product
- UNIQUE constraint: one entry per customer per product

---

## Relationship Diagram (Text)
```
┌─────────────────────────────────────────────────────────────────────┐
│                                                                     │
│  CUSTOMERS ─────────────────┬──────────────────┬──────────────────┐ │
│      │                      │                  │                  │ │
│      │ 1:N                  │ 1:N              │ 1:N              │ │
│      ▼                      ▼                  ▼                  ▼ │
│  ADDRESSES              ORDERS             REVIEWS          CART_ITEMS
│                            │                  │                  │ │
│                            │ 1:N              │                  │ │
│                            ▼                  │                  │ │
│                       ORDER_ITEMS             │                  │ │
│                            │                  │                  │ │
│                            │ N:1              │ N:1              │ │
│                            ▼                  ▼                  ▼ │
│  CATEGORIES ◄──────── PRODUCTS ◄─────────────┴──────────────────┘ │
│      │           N:M      │                                       │
│      │ (self)             │ 1:N                                   │
│      ▼                    ▼                                       │
│  (subcategories)      PAYMENTS                                    │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Cardinality Summary

| Relationship | Cardinality | Description |
|--------------|-------------|-------------|
| customer → addresses | 1:N | Customer has many addresses |
| customer → orders | 1:N | Customer places many orders |
| customer → reviews | 1:N | Customer writes many reviews |
| customer → cart_items | 1:N | Customer has many cart items |
| order → order_items | 1:N | Order contains many items |
| order → payments | 1:N | Order can have multiple payments |
| product → order_items | 1:N | Product appears in many orders |
| product → reviews | 1:N | Product has many reviews |
| product ↔ categories | N:M | Many-to-many via junction |
| category → category | 1:N | Self-referencing hierarchy |
