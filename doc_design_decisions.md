# Design Decisions

## Overview

This document explains the key design decisions made in creating this e-commerce database schema, including trade-offs and rationale.

---

## 1. Surrogate Keys vs Natural Keys

**Decision:** Use surrogate keys (SERIAL) for all primary keys

**Rationale:**
- Stable - won't change if business identifiers change
- Efficient - 4-byte integers join faster than strings
- Simple - no composite keys needed
- Consistent - same pattern everywhere

**Trade-off:** Must maintain natural key uniqueness separately (e.g., `email`, `sku`)
```sql
-- Surrogate PK + natural key constraint
customer_id SERIAL PRIMARY KEY,
email VARCHAR(255) NOT NULL UNIQUE  -- Natural key preserved
```

---

## 2. Soft Deletes vs Hard Deletes

**Decision:** Soft deletes for customers and products; hard deletes elsewhere

**Where we use soft deletes:**
| Table | Column | Why |
|-------|--------|-----|
| customers | `deleted_at` | Preserve order history, enable account recovery |
| products | `deleted_at` | Preserve order history, SEO redirects |

**Where we use hard deletes:**
- `cart_items` - No business need to preserve
- `addresses` - CASCADE from customer delete

**Implementation:**
```sql
-- Application must filter:
SELECT * FROM customers WHERE deleted_at IS NULL;

-- Or use a view:
CREATE VIEW active_customers AS
SELECT * FROM customers WHERE deleted_at IS NULL;
```

---

## 3. Address Normalization

**Decision:** Separate `addresses` table with one-to-many relationship

**Alternatives considered:**
1. Embed address columns in `customers` table
2. Embed address JSON in `customers` table
3. Separate `addresses` table ✅

**Why separate table:**
- Customers often have multiple addresses (home, work, gift recipients)
- Shipping and billing can be different
- Addresses can be reused across orders
- Cleaner schema, easier updates

**Trade-off:** Extra JOIN for simple queries

---

## 4. Order Address Snapshots

**Decision:** Store address reference (FK) but also snapshot product details in order_items

**Problem:** If customer updates their address after ordering, what address do we ship to?

**Solution:**
```sql
-- Orders reference addresses at time of order
shipping_address_id INT REFERENCES addresses(address_id)

-- Order items snapshot product details
product_name VARCHAR(255),  -- Copied from products
unit_price NUMERIC(10,2)    -- Copied from products (prices change!)
```

**Why snapshot prices:**
- Products prices change (sales, inflation)
- Order history must reflect what customer actually paid
- Legal/accounting requirements

---

## 5. Category Hierarchy Pattern

**Decision:** Adjacency list (parent_id reference)

**Alternatives:**
| Pattern | Pros | Cons |
|---------|------|------|
| Adjacency List ✅ | Simple, flexible | Recursive queries needed |
| Nested Set | Fast reads | Complex writes |
| Materialized Path | Easy breadcrumbs | String manipulation |
| Closure Table | Fast all queries | Extra table, more storage |

**Why adjacency list:**
- Category trees are typically shallow (2-3 levels)
- PostgreSQL has recursive CTEs for tree queries
- Simplest to understand and maintain
- Updates are straightforward

**Example recursive query:**
```sql
WITH RECURSIVE category_tree AS (
    SELECT category_id, name, 1 AS level
    FROM categories WHERE parent_category_id IS NULL
    
    UNION ALL
    
    SELECT c.category_id, c.name, ct.level + 1
    FROM categories c
    JOIN category_tree ct ON c.parent_category_id = ct.category_id
)
SELECT * FROM category_tree;
```

---

## 6. ENUM Types vs Lookup Tables

**Decision:** PostgreSQL ENUM types for status fields

**Used ENUMs for:**
- `order_status` (pending, shipped, delivered, etc.)
- `payment_status` (pending, captured, refunded, etc.)
- `address_type` (billing, shipping, both)

**Pros:**
- Type safety at database level
- Self-documenting
- Efficient storage (4 bytes)
- Fast comparisons

**Cons:**
- Adding values requires ALTER TYPE
- Not portable to all databases

**When to use lookup tables instead:**
- Values change frequently
- Values have additional attributes
- Need cross-database compatibility

---

## 7. Generated Columns

**Decision:** Use PostgreSQL generated columns for calculated values

**Examples:**
```sql
-- Order total auto-calculated
total_amount NUMERIC(12,2) GENERATED ALWAYS AS (
    subtotal + tax_amount + shipping_amount - discount_amount
) STORED

-- Line item total
line_total NUMERIC(12,2) GENERATED ALWAYS AS (
    unit_price * quantity
) STORED
```

**Benefits:**
- Always consistent (can't forget to update)
- Computed once on write, not every read
- Can be indexed

---

## 8. JSONB for Flexible Data

**Decision:** Use JSONB for payment gateway responses
```sql
gateway_response JSONB  -- Store full response from Stripe/PayPal
```

**Why:**
- Gateway responses vary by provider
- Schema changes frequently
- Useful for debugging/support
- Can query with JSON operators if needed

**When NOT to use JSONB:**
- Core business data that needs constraints
- Frequently queried fields (extract to columns)
- Data that needs referential integrity

---

## 9. Audit Columns

**Decision:** Standard audit columns on all tables
```sql
created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
```

**Maintenance:** Use a trigger to auto-update `updated_at`:
```sql
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_timestamp
BEFORE UPDATE ON customers
FOR EACH ROW EXECUTE FUNCTION update_timestamp();
```

---

## 10. Constraint Naming Convention

**Decision:** Explicit, descriptive constraint names

**Pattern:**
| Type | Format | Example |
|------|--------|---------|
| Primary Key | `tablename_pkey` | `customers_pkey` |
| Foreign Key | `fk_child_parent` | `fk_orders_customer` |
| Unique | `uq_table_column` | `uq_customers_email` |
| Check | `chk_table_description` | `chk_orders_subtotal_nonneg` |
| Index | `ix_table_columns` | `ix_orders_status_date` |

**Why explicit names:**
- Easier to debug constraint violations
- Clear error messages
- Easier to modify/drop specific constraints
- Self-documenting schema

---

## 11. ON DELETE Behavior

**Decision:** Explicit ON DELETE for every foreign key

| Relationship | Behavior | Rationale |
|--------------|----------|-----------|
| addresses → customers | CASCADE | Addresses belong to customer |
| orders → customers | RESTRICT | Preserve order history |
| order_items → orders | CASCADE | Items are part of order |
| order_items → products | RESTRICT | Preserve order history |
| reviews → products | CASCADE | Reviews go with product |
| reviews → customers | CASCADE | Reviews go with customer |

**Rule of thumb:**
- CASCADE for "owned" relationships (parent owns child)
- RESTRICT for "reference" relationships (preserve history)
- SET NULL for optional relationships

---

## Summary

Good database design balances:
- **Integrity** - Constraints prevent bad data
- **Performance** - Indexes support queries
- **Flexibility** - Schema can evolve
- **Clarity** - Self-documenting structure

This schema prioritizes integrity and clarity, with strategic denormalization for performance where needed.
