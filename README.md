# Database Schema Design

## 📋 Overview

A complete e-commerce database design demonstrating relational modeling best practices, normalization, constraint strategy, and PostgreSQL-specific features. This project showcases the thinking process behind database design decisions.

---

## 🎯 Business Requirements

Design a database for an e-commerce platform that supports:
- Customer accounts and addresses
- Product catalog with categories
- Shopping cart functionality
- Order processing and history
- Inventory tracking
- Product reviews and ratings

---

## 🛠️ Technologies

- **PostgreSQL 15+**
- Concepts apply to any relational database

---

## 📊 Schema Overview
```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  customers  │────<│   orders    │────<│ order_items │
└─────────────┘     └─────────────┘     └─────────────┘
       │                   │                   │
       │                   │                   │
       ▼                   ▼                   ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  addresses  │     │  payments   │     │  products   │
└─────────────┘     └─────────────┘     └─────────────┘
                                              │
                                              │
                                        ┌─────┴─────┐
                                        ▼           ▼
                                 ┌──────────┐ ┌──────────┐
                                 │categories│ │ reviews  │
                                 └──────────┘ └──────────┘
```

---

## 🔧 Key Design Patterns

| Pattern | Implementation | Purpose |
|---------|----------------|---------|
| Surrogate Keys | SERIAL/BIGSERIAL PKs | Stable, efficient joins |
| Soft Deletes | `is_active` + `deleted_at` | Preserve history |
| Audit Columns | `created_at`, `updated_at` | Track changes |
| Junction Tables | `product_categories` | Many-to-many relationships |
| Address Normalization | Separate `addresses` table | Multiple addresses per customer |
| Status Enums | PostgreSQL ENUM types | Type-safe status values |

---

## 📁 Files

| File | Description |
|------|-------------|
| `sql/01_create_schema.sql` | Tables, types, and core structure |
| `sql/02_create_constraints.sql` | Foreign keys, checks, unique constraints |
| `sql/03_create_indexes.sql` | Performance indexes with rationale |
| `sql/04_sample_data.sql` | Realistic test data |
| `docs/design_decisions.md` | Detailed design rationale |
| `docs/erd_description.md` | Entity-relationship documentation |

---

## 🚀 Quick Start
```sql
-- Run scripts in order
\i sql/01_create_schema.sql
\i sql/02_create_constraints.sql
\i sql/03_create_indexes.sql
\i sql/04_sample_data.sql

-- Verify
SELECT table_name, 
       (SELECT COUNT(*) FROM information_schema.columns c 
        WHERE c.table_name = t.table_name) AS columns
FROM information_schema.tables t
WHERE table_schema = 'ecommerce'
ORDER BY table_name;
```

---

## 💡 Design Highlights

### Normalization (3NF)
- No repeating groups (1NF)
- No partial dependencies (2NF)
- No transitive dependencies (3NF)
- Selective denormalization for performance (e.g., `order_items.unit_price`)

### Referential Integrity
- All foreign keys explicitly defined
- CASCADE deletes only where appropriate
- RESTRICT to prevent orphaned records

### Data Quality
- NOT NULL on required fields
- CHECK constraints for valid ranges
- UNIQUE constraints on natural keys
- Domain-specific validation (email format, positive prices)

### Performance Considerations
- Indexes on all foreign keys
- Covering indexes for common queries
- Partial indexes for filtered queries
- Appropriate data types (VARCHAR lengths, NUMERIC precision)

---

## 🎓 Key Learnings

- Start with business requirements, not tables
- Normalize first, denormalize strategically
- Constraints are documentation AND enforcement
- Index design follows query patterns
- Soft deletes preserve audit trails
- Use database features (ENUMs, generated columns)
