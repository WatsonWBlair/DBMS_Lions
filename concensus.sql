-- OLAP Tables
DROP TABLE IF EXISTS users;
CREATE TABLE users(
    user_id int NOT NULL,
    name NVARCHAR(255) NOT NULL,
    user_name NVARCHAR(255) NOT NULL,
    email NVARCHAR(255) NOT NULL,
    birth_year INT, 
    age INT CHECK (age>18),
    gender ENUM ('male', 'female', 'non-binary'),
    advertisement_metadata JSON,
    user_metadata JSON,
        -- {create_timestamp: int, birth_date: int, perental_restrictions: bool, ect.... }
        -- using the JSON data type here allows us to more easily develop this property
        -- as domain constrains around user protection and data collection evolve. 
    messages JSON,
        -- {[{thread_id, subject}],} - creates bidirectional link between users and messages via threads.
        
    posts JSON, liked_posts JSON,
        -- {[{id: int, thumbnail: int}]}
        -- enables `lazy loading` by providing basic information for immediate display
        -- thumbnail refrences a small image resource for the post.
    deleted TINYINT(1), 
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

-- OLTP Tables
DROP TABLE IF EXISTS media;
CREATE TABLE media(
    user_id int NOT NULL,
    timestamp int NOT NULL,
    mediaMetadata JSON NOT NULL,
        -- {creator: user_id, creationTimestamp: int, etc...}
    media BLOB NOT NULL,
    thumbnail BLOB NOT NULL,
    PRIMARY KEY(user_id, timestamp)
)

DROP TABLE IF EXISTS saved_posts;
CREATE TABLE saved_posts(
    user_id int NOT NULL,
    post_id int NOT NULL,
    deactivated TINYINT(1),
    PRIMARY KEY(user_id, post_id)
)
DROP TABLE IF EXISTS favorite_posts;
CREATE TABLE favorite_posts(
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
    PRIMARY KEY (comment_id),
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

    message NVARCHAR(255),
        -- String portion of the message
    media int NOT NULL,
    
    deleted TINYINT(1) NOT NULL,

    PRIMARY KEY (timestamp, sender_id),
    FOREIGN KEY (media) REFERENCES media(media_id)
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
CREATE TABLE archived_media LIKE media;

-- Triggers and Procedures
-- Trigger that converts DOB into age using TIMESTAMPDIFF function
DELIMITER //
DROP TRIGGER IF EXISTS ageCalc
CREATE TRIGGER ageCalc
AFTER INSERT ON user
BEGIN
UPDATE user SET age = TIMESTAMPDIFF(year, birth_date, CURDATE()) WHERE user_id = NEW.user_id;
END //


DROP TRIGGER IF EXISTS deleteUser
CREATE TRIGGER deleteUser
INSTEAD OF DELETE ON user
BEGIN
UPDATE users SET deleted=1 WHERE user_id = OLD.user_id;
archiveUser(OLD.user_id);
END//

DROP TRIGGER IF EXISTS deletePost
CREATE TRIGGER deletePost
INSTEAD OF DELETE ON posts, 
BEGIN
UPDATE posts SET deleted=1 WHERE post_id = OLD.post_id;
END//

DROP TRIGGER IF EXISTS deleteMessages
CREATE TRIGGER deleteMessages
AFTER DELETE ON media, 
BEGIN
INSERT INTO archived_messages OLD 
END//
DROP TRIGGER IF EXISTS deleteSavedPosts
CREATE TRIGGER deleteSavedPosts
AFTER DELETE ON saved_posts, 
BEGIN
INSERT INTO archived_saved_posts OLD 
END//
DROP TRIGGER IF EXISTS deleteFavoritePosts
CREATE TRIGGER deleteFavoritePosts
AFTER DELETE ON favorite_posts, 
BEGIN
INSERT INTO archived_favorite_posts OLD 
END//
DROP TRIGGER IF EXISTS deleteLikes
CREATE TRIGGER deleteLikes
AFTER DELETE ON likes, 
BEGIN
INSERT INTO archived_likes OLD 
END//
DROP TRIGGER IF EXISTS deleteMedia
CREATE TRIGGER deleteMedia
AFTER DELETE ON media, 
BEGIN
INSERT INTO archived_media OLD 
END//


DROP TRIGGER IF EXISTS threadPropagation
CREATE TRIGGER threadPropagation
AFTER INSERT ON threads
BEGIN
DECLARE @user_ids
SELECT @user_ids = JSON_VALUE(messages,'$.') from NEW
UPDATE users 
SET messages = JSON_MODIFY(users.messages, 'append $.', NEW.thread_id) WHERE users.user_id IN @user_ids;
END//

DROP TRIGGER IF EXISTS likePropagation
CREATE TRIGGER likePropagation
AFTER INSERT ON likes
BEGIN
DECLARE @post_id
DECLARE @user_id
SELECT @user_id = user_id, @post_id = post_id from NEW
UPDATE users 
SET liked_posts = JSON_MODIFY(
    users.liked_posts,
    'append $.',
    '{post_id:',@post_id,',thumbnail:',SELECT thumbnail FROM posts where post_id = @post_id ,'}') WHERE users.user_id = @user_id;
END//

DROP TRIGGER IF EXISTS postPropagation
CREATE TRIGGER likePropagation
AFTER INSERT ON posts
BEGIN
DECLARE @post_id
DECLARE @user_id
SELECT @user_id = user_id, @post_id = post_id from NEW
UPDATE users 
SET posts = JSON_MODIFY(
    users.posts,
    'append $.',
    '{post_id:',NEW.thread_id,',thumbnail:',SELECT thumbnail FROM posts where post_id = @post_id ,'}') WHERE users.user_id = @user_id;
END//

DELIMITER ;

-- Update event that checks against the previous trigger weekly to ensure all ages are up to date
DROP EVENT IF EXISTS ageCheck
CREATE EVENT IF NOT EXISTS ageCheck
ON SCHEDULE EVERY 1 WEEK
DO
    UPDATE USER
    SET age=TIMESTAMPDIFF(year, birth_date, CURDATE())

-- Procedure to move data from users being deleted from the database into an archive table
CREATE PROCEDURE archiveUser(IN user_id INT)
BEGIN
INSERT INTO archived_messages SELECT * FROM messages WHERE user_id={user_id};
INSERT INTO archived_posts SELECT * FROM posts WHERE user_id={user_id};
INSERT INTO archived_likes SELECT * FROM likes WHERE user_id={user_id};
UPDATE posts SET user_id=NULL WHERE user_id={user_id};
UPDATE messages SET user_id=NULL WHERE user_id={user_id};
UPDATE likes SET user_id=NULL WHERE user_id={user_id};
END;