-- OLAP Tables
DROP TABLE IF EXISTS users;
CREATE TABLE users(
    user_id int NOT NULL,
    name NVARCHAR(255) NOT NULL, -- NVARCHAR allows for non-western-european characters.
    email NVARCHAR(255) NOT NULL,
    birth_year INT, 
    age INT CHECK (age>18),
    gender ENUM ('male', 'female', 'non-binary'),
    advertisement_metadata JSON,
    user_metadata JSON,
        -- {create_timestamp: int, birth_date: int, perental_restrictions: bool, ect.... }
        -- using the JSON data type here allows us to more easily develop this property
        -- as domain constrains around user pertection and data collection evolve. 

    deleted TINYINT(1), 
    
    messages JSON,
        -- {[{thread_id, subject}],} - creates bidirectional link between users and messages via threads.
        -- NOTE that this property is updated via ETL processes, update cycles generate a fresh RDD instance.
    posts JSON, liked_posts JSON,
        -- {[{id: int, thumbnail: int}]}
        -- enables `lazy loading` by providing basic information for immediate display
        -- thumbnail refrences a small image resource for the post.

    PRIMARY KEY (user_id)
)

DROP TABLE IF EXISTS posts;
CREATE TABLE posts(
    post_id int NOT NULL,
    poster_id int NOT NULL,
    thumbnail BLOB,
    content NVARCHAR(255), -- this content string includes markup language to accommodate text and media content.
    deleted TINYINT(1),
    private TINYINT(1),
    commentCount int,
    likeCount int,
    PRIMARY KEY (post_id),
    FOREIGN KEY (poster_id) REFERENCES user(user_id)
)
-- This table was create by Watson, but we are going to add the archive tables that can be filled using the function below
-- -- Media uploaded by users who have deactivated their account.
-- DROP TABLE IF EXISTS abandonedMedia;
-- CREATE TABLE abandonedMedia(
--     media_id int NOT NULL,
--     media_metadata JSON NOT NULL,
--         -- {creator: user_id, creationTimestamp: int, deletionTimestamp: int, }
--     media BLOB NOT NULL,
)



-- OLTP Tables
DROP TABLE IF EXISTS media;
CREATE TABLE media(
    user_id int NOT NULL,
    timestamp int NOT NULL,
    mediaMetadata JSON NOT NULL,
        -- {creator: user_id, creationTimestamp: int,  }
    media BLOB NOT NULL,
    thumbnail BLOB NOT NULL, -- queries can be made that do not select the media blob, this will help keep packet size low if just the thumbnail is requested.
    PRIMARY KEY(user_id, timestamp)
)

DROP TABLE IF EXISTS savedPosts;
CREATE TABLE savedPosts(
    user_id int NOT NULL,
    post_id int NOT NULL,
    deactivated TINYINT(1),
    PRIMARY KEY(user_id, post_id)
)
DROP TABLE IF EXISTS favorite_posts;
CREATE TABLE favoritePosts(
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


DROP TABLE IF EXISTS threads;
CREATE TABLE threads(
    thread_id int NOT NULL,
    members JSON NOT NULL,
        -- {[ids]}
    PRIMARY KEY(thread_id)
)
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
-- added from Mike's individual work to create a separate table independently storing unique likes
CREATE TABLE likes(
    like_id INT AUTO INCREMENT PRIMARY KEY,
    post_id INT NOT NULL,
    user_id INT NOT NULL,
    comment_id INT NOT NULL,
    time_liked TIMESTAMP DEFAULT CURRENT TIMESTAMP,
    foreign key (post_id) REFERENCES posts(post_id),
    foreign key (user_id) REFERENCES user(user_id) ON DELETE CASCADE
    foreign key (comment_id) REFERENCES comments(comment_id),
    UNIQUE (user_id, post_id, comment_id)
)
-- added archived data tables to store data from deleted users
CREATE TABLE archived_messages LIKE messages;
CREATE TABLE archived_saved_posts LIKE savedPosts:
CREATE TABLE archived_favorite_posts LIKE favorite_posts;
CREATE TABLE archived_likes LIKE likes;



-- Triggers and Procedures
-- Trigger that converts DOB into age using TIMESTAMPDIFF function
DELIMITER //
CREATE TRIGGER agecalc
AFTER INSERT ON user
FOR EACH ROW
BEGIN
UPDATE user
SET age = TIMESTAMPDIFF(year, birth_date, CURDATE())
WHERE user_id = NEW.user_id;
END //
DELIMITER ;
-- Update event that checks against the previous trigger weekly to ensure all ages are up to date
CREATE EVENT AGE_CHECK
ON SCHEDULE EVERY 1 WEEK
DO
    UPDATE USER
    SET age=TIMESTAMPDIFF(year, birth_date, CURDATE())

-- Procedure to move data from users being deleted from the database into an archive table
CREATE PROCEDURE delete_user(IN user_id INT)
BEGIN
INSERT INTO archived_messages SELECT * FROM messages WHERE user_id={user_id};
INSERT INTO archived_posts SELECT * FROM posts WHERE user_id={user_id};
INSERT INTO archived_likes SELECT * FROM likes WHERE user_id={user_id};
UPDATE posts SET user_id=NULL WHERE user_id={user_id};
UPDATE messages SET user_id=NULL WHERE user_id={user_id};
UPDATE likes SET user_id=NULL WHERE user_id={user_id};
DELETE FROM user where user_id={user_id};
END;