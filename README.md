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

### Database Provisioning
The database objects the report depends on (currently the data transformation functions) are provisioned by `scripts\setup-db.bat`. It runs the SQL scripts in `scripts/sql` against the `dvdrental` database as the `postgres` user and stops with an error if any of them fails.

To provision the database:
``` batch
scripts\setup-db.bat
```

`psql` asks for the password of the `postgres` user; set the `PGPASSWORD` environment variable beforehand to skip the prompt. If `psql` is not found, run `scripts\dev\setup-user-path.bat` and open a new terminal.


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

#### Data Types

The detailed table draws on four kinds of data. Every type below is the native PostgreSQL type of the source column, except for the two derived fields, whose types are the return types of the user-defined functions that produce them.

| Kind of Data | Fields | PostgreSQL Type | Notes |
|--------------|--------|-----------------|-------|
| Numeric identifiers | `rental_id`, `customer_id`, `store_id` | `integer`, `smallint` | Whole numbers used as keys, never as measures. `rental_id` is an `integer`; `customer_id` and `store_id` are `smallint` in the source schema. They are never summed — only counted or used to join. |
| Date and time values | `rental_date`, `return_date` | `timestamp without time zone` | Microsecond-precision timestamps with no time zone offset. `return_date` is the only nullable field in the table, which is why it is transformed before being shown. |
| Descriptive text | `city`, `category_name`, `film_title` | `character varying(50)`, `character varying(25)`, `character varying(255)` | Variable-length strings carrying the labels a nontechnical reader actually reads. These are the grouping dimensions of the report, so they are shown as names rather than as the underlying surrogate keys. |
| Derived text | `rental_status`, `customer_name` | `character varying(20)`, `character varying(91)` | Produced at query time by user-defined functions rather than read from a column. `character varying(91)` accommodates the longest possible full name: two `character varying(45)` names plus a separating space. |

No numeric measures appear in the detailed table. The report's single measure — the rental count — is a product of aggregation and therefore belongs to the summary table, not to the row-level detail.

#### Field Transformation

Two fields of the detailed table cannot be read straight out of a column and require a custom transformation implemented as a PostgreSQL user-defined function.

##### `rental_status` — primary transformation

| | |
|---|---|
| **Source field** | `rental.return_date` (`timestamp without time zone`, nullable) |
| **Transformed into** | `rental_status` (`character varying(20)`) |
| **Function** | `fn_rental_status(return_date timestamp) RETURNS character varying(20)` |
| **Output values** | `Returned`, `Outstanding` |

The raw `return_date` is `NULL` for every rental whose copy has not been brought back. A `NULL` cell is not a neutral absence of information to a nontechnical stakeholder — it reads as a data error, as a blank that may have been dropped by the report, or as nothing at all. It also cannot be filtered or sorted in a spreadsheet the way a word can.

This field should be transformed with a user-defined function for three reasons:

1. **Readability.** A raw timestamp such as `2007-02-15 22:25:46.996577` tells a stakeholder only that *something* happened, and a blank tells them nothing. `Returned` and `Outstanding` state the fact of the matter in the vocabulary the business already uses.
2. **Consistency.** The same labelling rule is needed wherever rentals are reported. Encapsulating it in a function means the detailed table, the summary table and any future report all derive the status from one definition, so the wording can never drift between sections — and if the business later wants a third state such as `Overdue`, the rule changes in exactly one place.
3. **Business value.** `Outstanding` is directly actionable: it marks a copy that is off the shelf and therefore unavailable to rent. Because the detailed table also carries `city`, `category_name` and `store_id`, a reader can immediately see whether a popular category in a given city is being held back by copies that never came back — which is a stocking problem the summary count alone would hide.

##### `customer_name` — supporting transformation

| | |
|---|---|
| **Source fields** | `customer.first_name`, `customer.last_name` (`character varying(45)` each) |
| **Transformed into** | `customer_name` (`character varying(91)`) |
| **Function** | `fn_customer_name(first_name character varying, last_name character varying) RETURNS character varying(91)` |

The schema stores a person's name across two columns, which is correct for storage and wrong for a report: it costs the reader two columns of width and asks them to assemble the name themselves. The function combines both parts into a single field and normalizes capitalization, so the output reads the same way regardless of how a record was keyed in at the counter. A user-defined function is the right place for this because the rule — which part comes first, how the parts are separated, how casing is normalized — is a presentation decision that should be stated once and reused, not repeated inside every query that happens to need a name.

#### Business Use of the Detailed Table

The summary table answers the business question; the detailed table is what makes the answer usable and trustworthy.

- **It makes the answer verifiable.** Any figure in the summary table is a count of rows that exist in the detailed table. A regional manager who doubts that Sports really is the top category in their city can filter the detail to that city and category and see the individual rentals behind the number. An answer that can be checked is an answer a decision can be based on.
- **It turns a category into a buying list.** Knowing that Comedy leads in a city does not tell a buyer what to order. The detailed table carries `film_title` alongside `city` and `category_name`, so the same data shows which specific titles produced that lead — the level at which a purchase order is actually written.
- **It localizes the decision to a branch.** `store_id` identifies the branch that supplied each rented copy, so demand concentrated in one location is not mistaken for demand across the city. Inventory is held per store, so this is the level at which a stocking change is made.
- **It exposes supply problems the summary hides.** A category's rental count measures what customers *did* rent, not what they *wanted* to rent. Reading `rental_status` next to `category_name` and `store_id` shows where popular stock is sitting unreturned, which flags a title that should be reordered rather than simply restocked.
- **It supports targeted marketing.** `customer_id` and `customer_name` make each rental attributable, so a campaign for a category that is strong in a city can be aimed at the customers who already rent from it instead of at the city at large.
- **It separates breadth from volume.** A category can lead a city because many customers rent from it or because a few customers rent from it heavily. Those two situations call for opposite responses, and only the row-level detail distinguishes them.


### Summary Table

The summary table is the section of the report that answers the business question directly: **one row per city and film category**, carrying the rental count that decides which category leads where. Every row is an aggregation of the rows of the [Detailed Table](#detailed-table) — the same joins, over the same rental events — so the two sections of the report can never disagree with one another.

Where the detailed table is read a row at a time by an analyst, the summary table is read whole by a stakeholder: the business question is answered by the rows where `category_rank` is `1`, and the rest of the rows supply the context needed to judge how firm that answer is.

Grouping is performed on `city.city_id` and `category.category_id`, with the names carried through for readability, so each group is tied to a geographic and a catalog record rather than to a text match.

#### Grouping Dimension Fields

The fields the report aggregates **by**. Together they define the grain of the table — one row per pair.

| # | Field | Data Type | Nullable | Source | Business Purpose |
|---|-------|-----------|----------|--------|------------------|
| 1 | `city` | `character varying(50)` | `NOT NULL` | `city.city` | The geographic dimension of the business question — the "in each city" half. Each city is a market the business serves, and inventory decisions are made market by market, so this is the level the report is grouped at. |
| 2 | `category_name` | `character varying(25)` | `NOT NULL` | `category.name` | The category dimension of the business question — the "which film category" half. One of the sixteen categories in the catalog (Action, Comedy, Sports, ...), and the value being ranked within each city. |

#### Aggregated Measure Fields

The fields the report aggregates. Each is computed over the detailed-table rows belonging to the city and category of its row.

| # | Field | Data Type | Nullable | Derivation | Business Purpose |
|---|-------|-----------|----------|------------|------------------|
| 3 | `rental_count` | `integer` | `NOT NULL` | `COUNT(rental_id)` per city and category | **The measure that answers the business question.** The number of rental events recorded for the category in the city. "Most rentals" is this field at its maximum within a city. |
| 4 | `category_rank` | `integer` | `NOT NULL` | `DENSE_RANK()` over `rental_count` descending, partitioned by city | The category's position within its city, `1` being the most rented. States the answer outright instead of asking the reader to sort a table and compare numbers, and makes the report filterable down to one row per city. A tie leaves two categories sharing rank `1`, which is itself a finding. |
| 5 | `city_rental_total` | `integer` | `NOT NULL` | `SUM(rental_count)` partitioned by city | Total rentals recorded in the city across all categories. Sizes the market behind the ranking, so a leading category in a city with a handful of rentals is not acted on as though it were a leading category in a busy one. |
| 6 | `share_of_city_rentals` | `numeric(5,2)` | `NOT NULL` | `rental_count` as a percentage of `city_rental_total` | How much of the city's rental activity the category accounts for, from `0.00` to `100.00`. Separates a decisive lead from a near tie: 40% of a city's rentals is a stocking mandate, while 9% against a second place of 8% is noise. |
| 7 | `distinct_customers` | `integer` | `NOT NULL` | `COUNT(DISTINCT customer_id)` per city and category | How many different customers produced those rentals. Distinguishes broad local appetite for a category from a few heavy renters, which call for opposite responses — more copies in the first case, a loyalty or recommendation play in the second. |
| 8 | `outstanding_rentals` | `integer` | `NOT NULL` | Count of rows whose `rental_status` is `Outstanding` | How many of the category's copies are off the shelf and not yet returned. Read next to `rental_count`, it shows a popular category whose demand is being throttled by unavailable stock — a signal to reorder rather than merely restock. |
| 9 | `latest_rental_date` | `date` | `NOT NULL` | `MAX(rental_date)` cast to a date | The most recent rental of the category in the city. Tells the reader whether a leading position is current or historical, so a category that led a year ago and has since gone quiet is not restocked on the strength of a stale count. |

#### Data Types

The summary table draws on five kinds of data. The two dimensions keep the native PostgreSQL types of their source columns; the seven measures do not exist in the source schema at all, so their types are chosen for the values the aggregation can actually produce.

| Kind of Data | Fields | PostgreSQL Type | Notes |
|--------------|--------|-----------------|-------|
| Descriptive text dimensions | `city`, `category_name` | `character varying(50)`, `character varying(25)` | Declared at the same lengths as `city.city` and `category.name`, so no value can be truncated on its way into the summary. Carried as names rather than as the underlying `city_id` and `category_id` keys, because the summary table is read by stakeholders who recognize `Sports`, not `15`. |
| Whole-number counts | `rental_count`, `city_rental_total`, `distinct_customers`, `outstanding_rentals` | `integer` | Counts of rows and of distinct customers — whole, non-negative, and never fractional, so an integer type rather than a decimal one. |
| Ordinal position | `category_rank` | `integer` | A rank is a position, not a quantity: it is sorted and filtered (`= 1`) but never summed or averaged. Typed as an `integer` for consistency with the counters above, even though it is bounded by the sixteen categories in the catalog. |
| Percentage measure | `share_of_city_rentals` | `numeric(5,2)` | An exact decimal share. Five total digits with two to the right of the decimal point — three digits ahead of it — which covers the full `0.00` to `100.00` range the field can hold. |
| Calendar date | `latest_rental_date` | `date` | A day, with no time of day. |

##### Why These Types

- **`integer` rather than `bigint` for the counters.** PostgreSQL's `COUNT()` and `SUM()` return `bigint`, and `DENSE_RANK()` returns `bigint`, so each of these fields is an explicit narrowing of the aggregate's own type. It is a safe narrowing: the whole `rental` table is on the order of sixteen thousand rows, and `city_rental_total` — the largest value any of these fields can hold — is bounded by that total, four orders of magnitude below the `integer` ceiling of 2,147,483,647. A `bigint` would spend eight bytes per value to store a number that never needs more than four, in a table that stakeholders read as a grid of numbers.
- **`integer` rather than `smallint` for `category_rank`.** A `smallint` would hold a rank of at most 16 comfortably. Keeping every counter in the table one type is worth more than the two bytes, because it means a reader never has to ask why one numeric column is declared differently from its neighbours.
- **`numeric(5,2)` rather than `double precision` for the share.** `numeric` is exact, so the shares of a city's categories add up to the figure a reader expects instead of to a floating-point approximation of it, and a published report never shows `9.600000000000001`. The scale of `2` is set deliberately: a hundredth of a percent is finer than any stocking decision needs, and it is enough to break the visual tie between two categories that both round to the same whole percent.
- **An explicit decimal cast is required to compute the share.** Both operands are integers, and integer division in PostgreSQL truncates — `42 / 181` evaluates to `0`, not to `0.23`. The numerator is therefore multiplied by `100.0`, a `numeric` literal, before the division, so the whole expression is evaluated in exact decimal arithmetic and then rounded to two places.
- **`date` rather than `timestamp without time zone` for `latest_rental_date`.** The detailed table carries `rental_date` as a microsecond-precision timestamp, which is right for a row that describes a single transaction. A summary row describes many transactions, and the minute and second of the last one is noise in that context: what a reader wants from the field is whether the category was rented recently, which a calendar date answers.

##### Nullability

**Every field of the summary table is `NOT NULL`**, and this is a property of how the table is built rather than a constraint imposed on top of it:

- A row exists only because at least one rental produced it, so every aggregate has at least one value to compute from. There are no empty groups to return a `NULL` count or a `NULL` maximum.
- The source columns behind the fields — `city.city`, `category.name`, `rental.rental_id`, `rental.customer_id` and `rental.rental_date` — are all `NOT NULL` in the DVD Rental schema, so nothing nullable enters the aggregation in the first place.
- `rental.return_date`, the one nullable column the report touches, never reaches the summary table as a date. It is absorbed into `outstanding_rentals`, where a missing return is counted as a `1` instead of being displayed as a blank. The transformation described in [Field Transformation](#field-transformation) is what makes that possible, and it is the reason the summary table can promise a reader that no cell in it is ever empty.

A city and category pair with no rentals produces **no row**, rather than a row of zeros. The summary table reports observed demand, and a missing pair means no rental of that category was recorded in that city — which may mean there was no appetite for it or that no copies were ever stocked there. The summary table cannot tell those two apart; `store_id` in the detailed table is where that question is settled.

#### Data Dictionary

A single reference for the fields of the summary table, to be read alongside the field tables of the [Detailed Table](#detailed-table).

| Field | PostgreSQL Type | Null | Role | Domain of Values | Example |
|-------|-----------------|------|------|------------------|---------|
| `city` | `character varying(50)` | `NOT NULL` | Dimension — part of the grain | Any city name present in `city` (600 in the sample database) | `Woodridge` |
| `category_name` | `character varying(25)` | `NOT NULL` | Dimension — part of the grain | One of the 16 names in `category`: Action, Animation, Children, Classics, Comedy, Documentary, Drama, Family, Foreign, Games, Horror, Music, New, Sci-Fi, Sports, Travel | `Sports` |
| `rental_count` | `integer` | `NOT NULL` | Measure — primary | `1` and above; a pair with no rentals produces no row | `42` |
| `category_rank` | `integer` | `NOT NULL` | Measure — ordinal | `1` to `16`; `1` is the most rented category in the city, and ties share a rank | `1` |
| `city_rental_total` | `integer` | `NOT NULL` | Measure — context | `1` and above; equals the sum of `rental_count` across the city's rows | `181` |
| `share_of_city_rentals` | `numeric(5,2)` | `NOT NULL` | Measure — derived percentage | `0.01` to `100.00`; the city's rows sum to `100.00` | `23.20` |
| `distinct_customers` | `integer` | `NOT NULL` | Measure — breadth | `1` to `rental_count` | `19` |
| `outstanding_rentals` | `integer` | `NOT NULL` | Measure — availability | `0` to `rental_count` | `3` |
| `latest_rental_date` | `date` | `NOT NULL` | Measure — recency | Any date within the range covered by `rental.rental_date` | `2007-02-14` |

Notes on reading the dictionary:

- **Grain.** The pair (`city`, `category_name`) identifies a row. Every other field is an aggregate measured over that pair, so no two rows of the table describe the same city and category.
- **Role.** `Dimension` fields are the ones the report groups by and are carried straight from the source tables; `Measure` fields are produced by the aggregation and exist only in this table.
- **Derived fields.** `share_of_city_rentals`, `category_rank` and `city_rental_total` are computed from `rental_count` within the city, so they will always reconcile with it rather than being independent figures that could drift.
- **Example values** are illustrative of the shape and the units of each field, not output of a query.

#### Business Use of the Summary Table

The summary table is the section a decision is made from. It compresses every rental the business has recorded into one small grid — a row per city and category instead of thousands of transactions — which is what makes it readable by the people who authorize a purchase rather than only by the people who query the database.

- **It answers the business question in a single read.** Filtering to `category_rank = 1` returns exactly one row per city: the category that generates the most rentals there. No sorting, no mental arithmetic, and no SQL on the reader's part.
- **It turns the answer into a stocking rule per market.** The report is grouped at the city level because that is the level inventory is allocated at. A regional manager reads their own row and knows which category to weight the next order toward, and head office reads the whole table and sees how that weighting differs market by market instead of applying one national assortment everywhere.
- **It tells a mandate apart from a coin flip.** `share_of_city_rentals` is what keeps the ranking honest. A category holding 40% of a city's rentals justifies shifting shelf space toward it; a category leading by one rental over the runner-up does not, and acting on the rank alone would move stock on the strength of statistical noise.
- **It sizes the opportunity before money is spent.** `city_rental_total` shows how much business the city actually does. A commanding lead in a city with a dozen rentals is worth less than a narrow lead in the busiest market, so the two leads should not receive the same shipment. Ranking cities by this field also shows where the business is strong and where it is barely present — a question the business question did not ask, but one the same table answers.
- **It separates a broad audience from a few heavy renters.** Comparing `distinct_customers` against `rental_count` shows whether a category leads because the city at large rents it or because a handful of customers rent it repeatedly. The first calls for more copies; the second calls for keeping those customers and recommending the category to others, and spending on inventory instead would be spending on the wrong problem.
- **It flags demand that is being throttled by supply.** `outstanding_rentals` against `rental_count` identifies a leading category whose copies are off the shelf and unreturned. That is a category where the recorded rental count understates real appetite, and where the right response is more copies rather than more promotion.
- **It shows whether the lead is still current.** `latest_rental_date` distinguishes a category that leads because it is rented today from one that leads on the strength of a run that has since ended, which prevents the business from restocking against last year's taste.
- **It gives marketing a targeting list.** Each row is a city paired with a category and a measure of how strongly that pairing performs, which is exactly the input a regional campaign needs. The detailed table then supplies the customers and titles behind the chosen rows.
- **It makes the report monitorable over time.** Because the table is small and refreshed from the same detail, the same figures can be compared between refreshes. A category changing rank in a city, or a city's total falling, is visible at a glance in a way it never would be in sixteen thousand rental records.

Read together, the two sections divide the work: the summary table says *what to do and where*, and the detailed table says *with which titles, for which customers, and at which branch*.
