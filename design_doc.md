# Social Media Database Design

## Domain Constraints
- Users must be a minimum age to have an unrestricted account.
- Media should be preserved, media abandoned by users becomes the property of the platform
- Data structures should support lazy-loading approach, favoring partial replication of data to enable initial display while more complex queries are executed. This greatly increases the perceived performance of the platform.
- Users should be able to persist stings with non-western-european characters

## Assumed Application Functionality
- The app uses markdown language to insert media into string messages, and manages all https requests for persisting data appropriately.
- Users cannot do two actions in the same millisecond. eg: send a message, create a post, leave a comment, ect....
- If a given entity does not have a thumbnail, the app uses a default one, and submits request to update the attribute appropriately when the entities main media query is returned.

## Data Flow
- Users add content and entities to the system via OLTP tables which are optimized for data write operations
- Triggers act as ETL processes to propagate data from OLTP tables to OLAP tables
    - some triggers should be on entity creation(messaging), others at regular intervals(birthday messaging)


## Project Conventions
All of the tables and attributes follow a few conventions:
- Because discarding data is a bad practice, deletion is facilitated by a `deleted` or `disabled` attribute.
- `_metadata` JSON attributes are intended for use by internal or external working groups to store unstructured data specific to a particular business domain. This allows those teams to have flexible data structures without requiring updates to entities schemas.
- `thumbnail` BLOB attributes store slow-resolution preview assets.
- Tables and attributes use snake_case naming convention
- Triggers and functions use camelCase naming convention



## Tables
#### OLTP Tables
These tables are optimized for read operations. 
- Users
- Posts
- AbandonedMedia


#### OLAP Tables
These tables are optimized for write operations.
- Threads
- Messages
- SavedPosts
- FavoritePosts
- Comments
- Media


## Triggers
- Initialize calculated fields when instantiating a new user.
- Propagate thread membership when starting a new thread.
- Overwrite default deletion functionality for all tables

