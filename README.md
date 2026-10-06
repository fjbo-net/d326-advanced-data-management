# D326 - Advanced Data Management 
Project for the Performance Assessment for the course D326 Advanced Data Management.


## Set Up

Use the following steps to configure the pre-requisites for the project:
1. [Install PostgreSQL](https://neon.com/postgresql/postgresql-getting-started/install-postgresql)
0. Load the [DVD Rental Sample Database](https://neon.tech/unify?a=41263d5e-7865-4b0c-abb2-9efabc408393&n=postgresqltutorial/dvdrental.zip) into PostgreSQL

### Developer Set Up

To configure a provisioned lab:
1. Install Visual Studio Code
0. Install Git for Windows
0. Clone the repository

Or use the following command to setup the provisioned lab:
``` batch
CURL -L -o remote-setup.bat https://raw.githubusercontent.com/fjbo-net/d326-advanced-data-management/refs/heads/main/scripts/dev/remote-setup.bat && remote-setup.bat
```


## PostgreSQL

### Data Set
The following Entity-Relationship Diagram includes all entities in the DVD Rental Sample Database:

``` mermaid
---
title: DVD Rental Sample Database
---

erDiagram

	CATEGORY {
		int category_id PK
		string name
	}

	FILM_CATEGORY {
		int film_id PK, FK
		int category_id PK, FK
	}

	FILM {
		int film_id PK
		string title
		int language_id FK
		int rental_duration
		decimal rental_rate
		decimal replacement_cost
		string rating
	}

	LANGUAGE {
		int language_id PK
		string name
	}

	INVENTORY {
		int inventory_id PK
		int film_id FK
		int store_id FK
	}

	RENTAL {
		int rental_id PK
		datetime rental_date
		int inventory_id FK
		int customer_id FK
		datetime return_date
		int staff_id FK
	}

	PAYMENT {
		int payment_id PK
		int customer_id FK
		int staff_id FK
		int rental_id FK
		decimal amount
		datetime payment_date
	}

	CUSTOMER {
		int customer_id PK
		int store_id FK
		int address_id FK
		string first_name
		string last_name
		string email
		bool active
		date create_date
	}

	STAFF {
		int staff_id PK
		int address_id FK
		int store_id FK
		string first_name
		string last_name
		string email
		bool active
		string username
		string password
	}

	STORE {
		int store_id PK
		int manager_staff_id FK
		int address_id FK
	}

	ADDRESS {
		int address_id PK
		int city_id FK
		string address
		string address2
		string district
		string postal_code
		string phone
	}

	CITY {
		int city_id PK
		int country_id FK
		string city
	}

	COUNTRY {
		int country_id PK
		string country
	}

	ACTOR {
		int actor_id PK
		string first_name
		string last_name
	}

	FILM_ACTOR {
		int actor_id PK, FK
		int film_id PK, FK
	}

	%% Relationships
	CATEGORY ||--o{ FILM_CATEGORY: ""
	FILM ||--o{ FILM_CATEGORY: ""
	LANGUAGE ||--o{ FILM: ""
	FILM ||--o{ INVENTORY: ""
	INVENTORY ||--o{ RENTAL: ""
	CUSTOMER ||--o{ RENTAL: ""
	STAFF ||--o{ RENTAL: ""
	RENTAL ||--o{ PAYMENT: ""
	CUSTOMER ||--o{ PAYMENT: ""
	STAFF ||--o{ PAYMENT: ""

	STORE ||--o{ STAFF: ""
	STAFF ||--|| STORE: ""
	ADDRESS ||--o{ CUSTOMER: ""
	ADDRESS ||--o{ STAFF: ""
	ADDRESS ||--o{ STORE: ""
	CITY ||--o{ ADDRESS: ""
	COUNTRY ||--o{ CITY: ""

	FILM ||--o{ FILM_ACTOR: ""
	ACTOR ||--o{ FILM_ACTOR: ""

```

### PostgreSQL Command-Line Interface
PostgreSQL can be accessed via command-line interface using `psql`. The lab's default user is `postgres`.

To connect to PostgreSQL via CLI:
```batch
psql -U postgres -d dvdrental
```

To execute a SQL file:
``` batch
psql -U postgres -d dvdrental -f script.sql
```


## Business Analysis

### Business Question

Given the database data, I decided to answer the following question:

**Which film category generates the most rentals in each city where the business operates?**


### Business Value
The chosen business question provides valuable insights into regional customer preferences. This information can directly provide key business decisions and implement strategies like the optimization of inventory and help uncover patterns and trends.

Keeping a higher stock for the most popular film category for each region or branch could potentially maximize the revenue from each of the branches.

Business intelligence can help uncover patterns and trends by analyzing the resulting data from analyizing the most popular film categories for each of the branches, which could help craft more effective targeted marketing campaigns.

I believe the chosen Business Question is a solid foundation upon data analytics and business intelligence approaches can be built on.


### Source Tables

To answer the business question, the following tables from the DVD Rental database are required. They fall into two groups: the core dimension tables that directly hold the values being analyzed, and the bridge tables needed to connect them across the schema.

#### Core Tables

| Table | Key Fields Used | Role in Report |
|-------|----------------|----------------|
| `rental` | `rental_id`, `rental_date`, `inventory_id`, `customer_id` | Primary fact table. Every row represents one rental event. Rental counts aggregated from this table answer the "most rentals" part of the business question. |
| `category` | `category_id`, `name` | Provides the category name (e.g., Action, Comedy, Sports) that serves as one of the two grouping dimensions in both the detailed and summary tables. |
| `city` | `city_id`, `city` | Provides the city name that serves as the geographic grouping dimension in both the detailed and summary tables. |

#### Bridge Tables

These tables are required to connect the core tables through the schema's foreign key relationships.

| Table | Joins | Role in Report |
|-------|-------|----------------|
| `inventory` | `rental.inventory_id` → `inventory.inventory_id`; `inventory.film_id` → `film_category.film_id` | Links each rental to a specific film copy, which provides the `film_id` needed to reach the category dimension. Also provides `store_id` for potential store-level filtering. |
| `film_category` | `inventory.film_id` → `film_category.film_id`; `film_category.category_id` → `category.category_id` | Junction table that resolves the many-to-many relationship between films and categories. Required to map a rented film to its category. |
| `customer` | `rental.customer_id` → `customer.customer_id`; `customer.address_id` → `address.address_id` | Links each rental to the customer who made it, providing the `address_id` needed to reach the city dimension. |
| `address` | `customer.address_id` → `address.address_id`; `address.city_id` → `city.city_id` | Links customer records to their city, bridging the customer and city dimensions. |

#### Optional Enrichment Table

| Table | Key Fields Used | Role in Report |
|-------|----------------|----------------|
| `film` | `film_id`, `title` | Provides the film title for the detailed table, giving analysts a human-readable record of which specific film was rented. Not required for the summary aggregation. |

#### Full JOIN Path

```
rental
  ├── INNER JOIN inventory    ON rental.inventory_id  = inventory.inventory_id
  │     ├── INNER JOIN film           ON inventory.film_id     = film.film_id
  │     └── INNER JOIN film_category  ON inventory.film_id     = film_category.film_id
  │               └── INNER JOIN category  ON film_category.category_id = category.category_id
  └── INNER JOIN customer    ON rental.customer_id   = customer.customer_id
            └── INNER JOIN address   ON customer.address_id  = address.address_id
                      └── INNER JOIN city      ON address.city_id       = city.city_id
```

#### Why Each Table Is Necessary

| Table | Data Provided for the Detailed Table | Data Provided for the Summary Table |
|-------|--------------------------------------|-------------------------------------|
| `rental` | One row per rental event (`rental_id`, `rental_date`) | The rows counted to find the category with the most rentals in each city |
| `category` | The category `name` of each rental | The category being ranked within each city |
| `city` | The `city` of the customer who made each rental | The city used to group the rentals |
| `inventory` | Connects each rental to a film (`film_id`) | Connects each rental to a film so it can be assigned a category |
| `film_category` | Maps each rented film to its category | Assigns each counted rental to a category |
| `customer` | Identifies who made each rental (`customer_id`) | Connects each counted rental to a customer address |
| `address` | Connects each customer to a city | Connects each counted rental to a city |
| `film` | The film `title` of each rental (optional) | Not needed |

Together, the core and bridge tables supply every value the summary aggregation needs, and the detailed table draws on the same tables at the level of individual rentals.



### Detailed Table

The detailed table is the most granular section of the report: **one row per rental event**. No aggregation is applied, so every row can be traced back to a single transaction in the `rental` table. The summary table is produced by aggregating exactly these rows, which keeps both sections of the report consistent with one another.

#### Fields

| # | Field | Data Type | Source | Business Purpose |
|---|-------|-----------|--------|------------------|
| 1 | `rental_id` | `integer` | `rental.rental_id` | Unique identifier of the rental event. Guarantees every row of the detailed table is distinct and gives stakeholders an audit key to trace any number in the summary table back to the originating transaction. |
| 2 | `rental_date` | `timestamp without time zone` | `rental.rental_date` | The moment the rental occurred. Allows the report to be filtered or trended over a period, so a category's popularity can be evaluated for a specific season, quarter or year rather than over the whole history. |
| 3 | `return_date` | `timestamp without time zone` (nullable) | `rental.return_date` | The moment the copy was returned. `NULL` when the copy has not come back yet. Source value for the transformed `rental_status` field. |
| 4 | `rental_status` | `character varying(20)` — **transformed** | Derived from `rental.return_date` | Human-readable completion state of the rental (`Returned` / `Outstanding`). Replaces a `NULL` timestamp, which is meaningless to a nontechnical reader, with an explicit business label. See [Field Transformation](#field-transformation). |
| 5 | `city` | `character varying(50)` | `city.city` | The geographic dimension of the business question. Identifies the city of the customer who made the rental and is the field the summary table groups by. |
| 6 | `category_name` | `character varying(25)` | `category.name` | The category dimension of the business question (e.g. Action, Comedy, Sports). This is the value being counted and ranked per city in the summary table. |
| 7 | `film_title` | `character varying(255)` | `film.title` | The specific film that was rented. Lets an analyst see *which* titles are driving a category's popularity in a city, which is the level of detail needed to make a stocking decision. |
| 8 | `customer_id` | `smallint` | `rental.customer_id` | Identifies the customer behind each rental. Supports per-customer drill-down and makes it possible to tell a category driven by many customers from one driven by a single heavy renter. |
| 9 | `customer_name` | `character varying(91)` — **transformed** | Derived from `customer.first_name` and `customer.last_name` | The customer's full name as a single readable value, so stakeholders are not asked to mentally join two columns. See [Field Transformation](#field-transformation). |
| 10 | `store_id` | `smallint` | `inventory.store_id` | The branch that supplied the rented copy. Enables the report to be read per branch, which is where an inventory decision is ultimately acted on. |
