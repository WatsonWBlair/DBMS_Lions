SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS user;
DROP TABLE IF EXISTS messages;
DROP TABLE IF EXISTS posts;
DROP TABLE IF EXISTS prescriptions;
CREATE DATABASE comments;
USE DATABASE phone_project;
CREATE TABLE user(
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    user_name NVARCHAR(100) UNIQUE,
    birth_year INT, 
    email NVARCHAR(100),
    gender ENUM ('male', 'female', 'non-binary'),
    Follow_id INT,
    message_id INT,
    post_id INT,
    foreign key (message_id) REFERENCES messages(message_id),
    foreign key (post_id) REFERENCES posts(post_id),
    foreign key (Follow_id) REFERENCES user(U_id)
);

CREATE TABLE messages(
    message_id INT  AUTO_INCREMENT PRIMARY KEY,
    content NVARCHAR(100),
    -- sender, recipient and reply receipient are all identified by IDs 
    from_user_id INT,
    to_user_id INT,
    reply_to_id INT,
    foreign key (from_user_id) REFERENCES user(user_id) ON DELETE CASCADE,
    foreign key (to_user_id) REFERENCES user(user_id) ON DELETE CASCADE,
    foreign key (reply_user_id) REFERENCES user(user_id) ON DELETE CASCADE
);

CREATE TABLE posts(
    post_id INT AUTO_INCREMENT PRIMARY KEY,
    user_post INT NOT NULL,
    post_content VARCHAR(250),
    likes_count INT DEFAULT 0,
    created_time TIMESTAMP,
    copied_posts_id INT,
    foreign key (user_post) REFERENCES user(user_id) ON DELETE CASCADE
    foreign key (copied_posts) REFERENCES posts(post_id)
);
CREATE TABLE comments(
    comment_id INT AUTO_INCREMENT PRIMARY KEY,
    post_id INT NOT NULL,
    user_id INT NOT NULL,
    likes_count INT DEFAULT 0,
    -- Using likes_count as opposed to identifying individual likes to reduce redundancy, since likes are identified and stored in another table
    parent_comment_id INT DEFAULT NULL,
    comment_content VARCHAR(250),
    create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    update_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    foreign key (post_id) REFERENCES posts(post_id),
    foreign key (user_id) REFERENCES user(user_id) ON DELETE CASCADE,
    foreign key (parent_comment_id) REFERENCES comments(comment_id)
);
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
);

CREATE TABLE archived_messages LIKE messages;
CREATE TABLE archived_posts LIKE posts:
CREATE TABLE archived_likes LIKE likes;

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

CREATE EVENT AGE_CHECK
ON SCHEDULE EVERY 1 WEEK
DO
    UPDATE USER
    SET age=TIMESTAMPDIFF(year, birth_date, CURDATE())

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