SET FOREIGN_KEY_CHECKS = 0;

-- Authors:
    -- Leo Lub
    -- Michael Griffin
    -- Watson Blair

-- JSON Datatype
-- https://learn.microsoft.com/en-us/sql/relational-databases/json/json-data-sql-server?view=sql-server-ver16 

-- OLTP Tables: optimized for write opperations
-- OLAP Tables: optimized for read opperations

-- Data Flow:
-- Data flows into the system via OLTP tables, which are highly normalized
-- Triggers translate OLTP attributes into OLAP JSON objects

-- OLAP Tables: optimize for read operations
-- users
-- abandoned media

-- The `Users` table is our main data structure. all other tables
-- are week entityies that define interactions between a given
-- user and the social media platform described.
DROP TABLE IF EXISTS users;
CREATE TABLE users(
    user_id int NOT NULL,
    name NVARCHAR(255), -- NVARCHAR allows for non-western-eruopean characters.
    email NVARCHAR(255),

    advertisement_metadata JSON,
    user_meatadata JSON,
        -- {create_timestamp: int, birth_date: int, perental_restrictions: bool, ect.... }
        -- using the JSON data type here allows us to more easily develop this property
        -- as domain constrains around user pertection and data collection evolve. 

    deleted TINYINT(1), 
        -- It is best practice to retain `deleted` data. null/0 is active, 1 is deleted
    
    messages JSON,
        -- {[{thread_id, subject}],} - creates bidirectional link between users and messages via threads.
        -- NOTE that this property is updated via ETL processes, update cycles generate a fresh RDD instance.
    posts JSON, liked_posts JSON,
        -- {[{id: int, thumbnail: int}]}
        -- enables `lazy loading` by providing basic information for immediate display
        -- thumbnail refrences a small image resource for the post.

    PRIMARY KEY (user_id)
)

-- Users add content to the social media platform via post entities.
-- application logic manages storing media assets separately.
DROP TABLE IF EXISTS posts;
CREATE TABLE posts(
    post_id int NOT NULL,
    poster_id int NOT NULL,
    thumbnail int,
    content NVARCHAR(255), -- this content string includes markup language to accommodate text and media content.
    deleted TINYINT(1),
    private TINYINT(1),
    PRIMARY KEY (post_id),
    FOREIGN KEY (poster_id) REFERENCES user(user_id)
)
-- Join Tables allow us define relationships between OLTP tables
-- without violating normalization constraints.
DROP TABLE IF EXISTS savedPosts;
CREATE TABLE savedPosts(
    user_id int NOT NULL,
    post_id int NOT NULL,
    deactivated TINYINT(1),
    PRIMARY KEY(user_id, post_id)
)
DROP TABLE IF EXISTS favoriate_posts;
CREATE TABLE favoriatePosts(
    user_id int NOT NULL,
    post_id int NOT NULL,
    deactivated TINYINT(1),
    PRIMARY KEY(user_id, post_id)
)
DROP TABLE IF EXISTS comments;
CREATE TABLE comments(
    comment_id int NOT NULL,
    on_post int NOT NULL,
    reply_to int NOT NULL,
    content JSON,
    deleted TINYINT(1),
    PRIMARY KEY (user_id),
    FOREIGN KEY (from_id) REFERENCES users(user_id),
)
DROP TABLE IF EXISTS media;
CREATE TABLE media(
    user_id int NOT NULL,
    timestamp int NOT NULL, -- when the media was uploaded
    mediaMetadata JSON NOT NULL,
        -- {creator: user_id, creationTimestamp: int,  }
    media BLOB NOT NULL,
    PRIMARY KEY(user_id, timestamp)
)
DROP TABLE IF EXISTS abandonedMedia; -- Media uploaded by users who have deactivated their account.
CREATE TABLE abandonedMedia(
    media_id int NOT NULL,
    media_metadata JSON NOT NULL,
        -- {creator: user_id, creationTimestamp: int, deletionTimestamp: int, }
    media BLOB NOT NULL,
)


-- The threads entity links groups of users to a common message thread.
DROP TABLE IF EXISTS threads;
CREATE TABLE threads(
    thread_id int NOT NULL,
    members JSON NOT NULL,
        -- {[ids]}
    PRIMARY KEY(thread_id)
)
-- Messages are entities that represent communication between groups of users.
DROP TABLE IF EXISTS messages;
CREATE TABLE messages(
    timestamp int NOT NULL,
    sender_id int NOT NULL,
    thread_id int NOT NULL,

    message NVARCHAR(255), -- String portion of the message
    media int NOT NULL, -- Media message, ID refrences entry in S3 bucket.
    
    deleted TINYINT(1) NOT NULL,
    
    PRIMARY KEY (timestamp, sender_id),
    FOREIGN KEY (sender_id) REFERENCES users(user_id),
    FOREIGN KEY (thread_id) REFERENCES threads(thread_id)
)


-- Table Template:
-- DROP TABLE IF EXISTS ;
-- CREATE TABLE (
--     user id,
--     id,
--     deleted TINYINT(1),
--     PRIMARY KEY(user, )
-- )

-- Trigger:
-- When a post is deleted:
    -- update all of the comments on that post to be a common [deleted] post.
-- When a thread is created:
    -- add thread to messages array for all thread members
-- 


