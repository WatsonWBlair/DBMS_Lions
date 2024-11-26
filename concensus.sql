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
    birth_date DATETIME,
    advertisement_metadata JSON,
    user_metadata JSON,
        -- {create_timestamp: int, birth_date: int, parental_restrictions: bool, ect.... }
        -- using the JSON data type here allows us to more easily develop this property
        -- as domain constrains around user protection and data collection evolve. 
    messages JSON,
        -- {[{thread_id, subject}],} - creates bidirectional link between users and messages via threads.
        
    posts JSON, liked_posts JSON,
        -- {[{id: int, thumbnail: blob}]}
        -- enables `lazy loading` by providing basic information for immediate display
        -- thumbnail refrences a small image resource for the post.
    deleted TINYINT(1), 
    PRIMARY KEY (user_id)
);

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
    FOREIGN KEY (poster_id) REFERENCES users(user_id)
);

-- OLTP Tables
DROP TABLE IF EXISTS media;
CREATE TABLE media(
    media_id int NOT NULL,
    user_id int NOT NULL,
    timestamp int NOT NULL,
    mediaMetadata JSON NOT NULL,
        -- {creator: user_id, creationTimestamp: int, etc...}
    media BLOB NOT NULL,
    thumbnail BLOB NOT NULL,
    PRIMARY KEY(media_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

DROP TABLE IF EXISTS saved_posts;
CREATE TABLE saved_posts(
    user_id int NOT NULL,
    post_id int NOT NULL,
    deactivated TINYINT(1),
    PRIMARY KEY(user_id, post_id)
);
DROP TABLE IF EXISTS favorite_posts;
CREATE TABLE favorite_posts(
    user_id int NOT NULL,
    post_id int NOT NULL,
    deactivated TINYINT(1),
    PRIMARY KEY(user_id, post_id)
);
DROP TABLE IF EXISTS comments;
CREATE TABLE comments(
    comment_id int NOT NULL,
    on_post int NOT NULL,
    reply_to int NOT NULL,
    user_id int NOT NULL,
    content JSON,
    deleted TINYINT(1),
    PRIMARY KEY (comment_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);


DROP TABLE IF EXISTS threads;
CREATE TABLE threads(
    thread_id int NOT NULL,
    members JSON NOT NULL,
        -- {[ids]}
    PRIMARY KEY(thread_id)
);
DROP TABLE IF EXISTS messages;
CREATE TABLE messages(
    timestamp INT NOT NULL,
    sender_id INT NOT NULL,
    thread_id INT NOT NULL,
    message NVARCHAR(255),
    media_id INT NOT NULL,
    deleted TINYINT(1) NOT NULL,
    PRIMARY KEY (timestamp, sender_id),
    FOREIGN KEY (media_id) REFERENCES media(media_id),
    FOREIGN KEY (sender_id) REFERENCES users(user_id),
    FOREIGN KEY (thread_id) REFERENCES threads(thread_id)
);
-- added from Mike's individual work to create a separate table independently storing unique likes
DROP TABLE IF EXISTS likes;
CREATE TABLE likes(
    like_id INT PRIMARY KEY,
    post_id INT NOT NULL,
    user_id INT NOT NULL,
    comment_id INT NOT NULL,
    time_liked TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES posts(post_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (comment_id) REFERENCES comments(comment_id),
    UNIQUE (user_id, post_id, comment_id)
);
-- added archived data tables to store data from deleted users
DROP TABLE IF EXISTS archived_messages;
CREATE TABLE archived_messages LIKE messages;
DROP TABLE IF EXISTS archived_saved_posts;
CREATE TABLE archived_saved_posts LIKE saved_posts;
DROP TABLE IF EXISTS archived_favorite_posts;
CREATE TABLE archived_favorite_posts LIKE favorite_posts;
DROP TABLE IF EXISTS archived_likes;
CREATE TABLE archived_likes LIKE likes;
DROP TABLE IF EXISTS archived_media;
CREATE TABLE archived_media LIKE media;

-- Triggers and Procedures
-- Trigger that converts DOB into age using TIMESTAMPDIFF function
DELIMITER //
-- When Inserting a user record, calculate their age.
DROP TRIGGER IF EXISTS ageCalc//
CREATE TRIGGER ageCalc 
AFTER INSERT ON user
FOR EACH ROW
BEGIN
    UPDATE user 
    SET age = TIMESTAMPDIFF(YEAR, NEW.birth_date, CURDATE()) 
    WHERE user_id = NEW.user_id;
END//

-- custom deletion implementation:

-- OLAP tables have a `deleted` indicator
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

-- OLTP tables have archived_ companion tables
DROP TRIGGER IF EXISTS deleteMessages
CREATE TRIGGER deleteMessages
AFTER DELETE ON media, 
BEGIN
    INSERT INTO archived_messages OLD;
END//
DROP TRIGGER IF EXISTS deleteSavedPosts
CREATE TRIGGER deleteSavedPosts
AFTER DELETE ON saved_posts, 
BEGIN
    INSERT INTO archived_saved_posts OLD;
END//
DROP TRIGGER IF EXISTS deleteFavoritePosts
CREATE TRIGGER deleteFavoritePosts
AFTER DELETE ON favorite_posts, 
BEGIN
    INSERT INTO archived_favorite_posts OLD;
END//
DROP TRIGGER IF EXISTS deleteLikes
CREATE TRIGGER deleteLikes
AFTER DELETE ON likes, 
BEGIN
    INSERT INTO archived_likes OLD;
END//
DROP TRIGGER IF EXISTS deleteMedia
CREATE TRIGGER deleteMedia
AFTER DELETE ON media, 
BEGIN
    INSERT INTO archived_media OLD;
END//

-- Data Propagation:
-- our schema includes some data replication, these triggers ensure entity integrity.
-- note that replicated data points are not critical to platform operation.
DROP TRIGGER IF EXISTS threadPropagation
CREATE TRIGGER threadPropagation
AFTER INSERT ON threads
BEGIN
    DECLARE @user_ids;
    SELECT @user_ids = JSON_VALUE(messages,'$.') from NEW;
    UPDATE users 
    SET messages = JSON_MODIFY(users.messages, 'append $.', NEW.thread_id) WHERE users.user_id IN @user_ids;
END//

DROP TRIGGER IF EXISTS likePropagation
CREATE TRIGGER likePropagation
AFTER INSERT ON likes
BEGIN
    DECLARE @post_id;
    DECLARE @user_id;
    SELECT @user_id = user_id, @post_id = post_id from NEW;
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
    DECLARE @post_id;
    DECLARE @user_id;
    SELECT @user_id = user_id, @post_id = post_id from NEW;
    UPDATE users
    SET posts = JSON_MODIFY(
        users.posts,
        'append $.',
        '{post_id:',NEW.thread_id,',thumbnail:',SELECT thumbnail FROM posts where post_id = @post_id ,'}') WHERE users.user_id = @user_id;
END//



-- Update event that checks against the previous trigger weekly to ensure all ages are up to date
DROP EVENT IF EXISTS ageCheck;
CREATE EVENT IF NOT EXISTS ageCheck
ON SCHEDULE EVERY 1 WEEK
DO
    UPDATE USER
    SET age=TIMESTAMPDIFF(year, birth_date, CURDATE());//
END//

-- Procedure to move data from users being deleted from the database into an archive table
CREATE PROCEDURE archiveUser(IN user_id INT)
BEGIN
    INSERT INTO archived_messages SELECT * FROM messages WHERE user_id={user_id};
    INSERT INTO archived_posts SELECT * FROM posts WHERE user_id={user_id};
    INSERT INTO archived_likes SELECT * FROM likes WHERE user_id={user_id};
    UPDATE posts SET user_id=NULL WHERE user_id={user_id};
    UPDATE messages SET user_id=NULL WHERE user_id={user_id};
    UPDATE likes SET user_id=NULL WHERE user_id={user_id};
END//

DELIMITER ;

INSERT INTO users(user_id,name, user_name, email, birth_year, gender,advertisement_metadata JSON,user_metadata JSON,messages JSON,posts JSON, liked_posts JSON,deleted)
VALUES(1, 'Mike Griffin', 'mjg', 'hotmail@gmail.com', 1999, 'male', 
    '{"interests": ["books", "sports"], "targeting": {"ads_enabled": true, "category": "premium"}}', 
    '{"create_timestamp": 1698316800, "birth_date": 19850101, "parental_restrictions": false}', 
    '[{"thread_id": 1001, "subject": "Welcome!"}]', 
    '[{"id": 1, "thumbnail": null}, {"id": 2, "thumbnail": null}]', 
    '[{"id": 3, "thumbnail": null}]', 
    0),
    (2, 'Watson Blair', 'WLB', 'gmail@compuserve.com', 1988, 'male', 
    '{"interests": ["tech", "running"], "targeting": {"ads_enabled": true, "category": "premium"}}', 
    '{"create_timestamp": 1698316800, "birth_date": 19880101, "parental_restrictions": false}', 
    '[{"thread_id": 1001, "subject": "Welcome!"}]', 
    '[{"id": 1, "thumbnail": null}, {"id": 2, "thumbnail": null}]', 
    '[{"id": 3, "thumbnail": null}]', 
    0),
    (3, 'Leon Lion', 'llion', 'compuserve@compuserve.com', 2000, 'female', 
    '{"interests": ["TV", "Video Games"], "targeting": {"ads_enabled": true, "category": "premium"}}', 
    '{"create_timestamp": 1698316800, "birth_date": 20000101, "parental_restrictions": false}', 
    '[{"thread_id": 1001, "subject": "Welcome!"}]', 
    '[{"id": 1, "thumbnail": null}, {"id": 2, "thumbnail": null}]', 
    '[{"id": 3, "thumbnail": null}]', 
    0),
    (4, 'Will Torres', 'WWT', 'hotmail@gmail.com', 1996, 'non-binary', 
    '{"interests": ["metal music", "Queens"], "targeting": {"ads_enabled": true, "category": "premium"}}', 
    '{"create_timestamp": 1698316800, "birth_date": 19960101, "parental_restrictions": false}', 
    '[{"thread_id": 1001, "subject": "Welcome!"}]', 
    '[{"id": 1, "thumbnail": null}, {"id": 2, "thumbnail": null}]', 
    '[{"id": 3, "thumbnail": null}]', 
    0),
    (5, 'Mack McGee', 'MMG', 'gmail@hotmail.com', 2001, 'male', 
    '{"interests": ["fishing", "hunting"], "targeting": {"ads_enabled": true, "category": "premium"}}', 
    '{"create_timestamp": 1698316800, "birth_date": 20010101, "parental_restrictions": false}', 
    '[{"thread_id": 1001, "subject": "Welcome!"}]', 
    '[{"id": 1, "thumbnail": null}, {"id": 2, "thumbnail": null}]', 
    '[{"id": 3, "thumbnail": null}]', 
    0);

INSERT INTO posts(post_id,poster_id,thumbnail,content,deleted,private,commentCount,likeCount) 
VALUE(1,11, NULL,'I enjoy eating ice cream',0,0,1,1,1),
(2,12,'I do not enjoy riding the train',0,0,1,1,1),
(3,13,'I am looking forward to Christmas',0,0,1,2,2),
(4,14,'我喜欢看胖女人吃双层芝士汉堡',0,0,2,2,2),
(5,15,'أريد السفر إلى المريخ',1,1,1,1,1);

INSERT INTO media (user_id,timestamp,mediaMetadata,media,thumbnail) 
VALUES
(1, 1698316800, 
    '{"creator": 1, "creationTimestamp": 1698316800, "description": "User profile picture", "tags": ["profile", "picture"]}', 
    x'89504E470D0A1A0A0000000D49484452', 
    x'FFD8FFE000104A464946'),
(2, 1698320400, 
    '{"creator": 2, "creationTimestamp": 1698320400, "description": "Event photo", "tags": ["event", "photo"]}', 
    x'89504E470D0A1A0A0000000D49484452', 
    x'FFD8FFE000104A464946'),
(3, 1698324000, 
    '{"creator": 3, "creationTimestamp": 1698324000, "description": "Product image", "tags": ["product", "advertisement"]}', 
    x'89504E470D0A1A0A0000000D49484452', 
    x'FFD8FFE000104A464946'),
(4, 1698327600, 
    '{"creator": 4, "creationTimestamp": 1698327600, "description": "Vacation video thumbnail", "tags": ["vacation", "video"]}', 
    x'89798F470D0A1A0A0000000D49484452', 
    x'FFD8FGE000104A464946'),
(5, 1698331200, 
    '{"creator": 5, "creationTimestamp": 1698331200, "description": "Marketing banner", "tags": ["marketing", "banner"]}', 
    x'89504E470D0A1A0A0003450D49484452', 
    x'FFD8FFE234104A464946');

INSERT INTO saved_posts (user_id,post_id,deactivated) 
VALUES
(1, 11, 0),
(2,12,0),
(3,13,0),
(4,14,0),
(5,15,0);

INSERT INTO favorite_posts(user_id,post_id,deactivated) 
VALUES
(1, 11, 0),
(2,12,0),
(3,13,0),
(4,14,0),
(5,15,0);

INSERT INTO comments (comment_id,on_post,reply_to,content,deleted,from_id) 
VALUES
(1, 101, 0, '{"text": "I enjoy peanut butter", "likes": 1}', 0, 1), 
(2, 101, 1, '{"text": "I also enjoy peanut butter.", "likes": 2}', 0, 2), 
(3, 102, 0, '{"text": "I do not enjoy peanut butter", "likes": 10}', 0, 3), 
(4, 102, 3, '{"text": "People who like peanut butter make me sick.", "likes": 4}', 1, 1), 
(5, 103, 0, '{"text": "I enjoy covering my body in peanut butter.", "likes": 3}', 1, 4); 

INSERT INTO threads (thread_id,members) 
VALUES
(1, '{"ids": [1, 2, 3]}'),
(2,'{"ids": [1, 3, 4]}'),
(3,'{"ids": [4, 2, 3]}'),
(4,'{"ids": [4]}'),
(5,'{"ids": [3]}');

INSERT INTO messages (timestamp,sender_id,thread_id,message,media,deleted) 
VALUES
(1698316800, 1, 1, 'Hello, how are you?', 1, 0),
(1698316800, 2, 1, 'Im doing okay, how are you?', 1, 0),
(1698316800, 3, 1, 'Not too bad, how are you?', 1, 0),
(1698316800, 4, 1, 'You already asked me that', 1, 1),
(1698316800, 5, 1, 'Im doing well, how are you?', 1, 0);

INSERT INTO likes (post_id,user_id,comment_id,time_liked) 
VALUES
(101, 1, 1, '2024-11-25 14:30:00'), 
(102, 2, 3, '2024-11-25 15:00:00'), 
(101, 3, 2, '2024-11-25 15:30:00'), 
(103, 4, 5, '2024-11-25 16:00:00'), 
(104, 1, 4, '2024-11-25 16:30:00'); 