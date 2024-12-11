DROP DATABASE IF EXISTS try3;
CREATE DATABASE try3;
USE try3;
DROP TABLE IF EXISTS users;
CREATE TABLE users(
    uid int NOT NULL,
    name STRING NOT NULL,
    user_name STRING NOT NULL,
    email STRING NOT NULL,
    birth_year INT, 
    age INT, CHECK (age>18),
    gender STRING, CHECK gender IN ('male', 'female', 'non-binary'),
    birth_date Date-time,
    messages STRING,  
    posts STRING,
    deleted TINYINT(1), 
    PRIMARY KEY (uid)
);
DROP TABLE IF EXISTS posts;
CREATE TABLE posts(
    post_id int NOT NULL,
    poster_id int NOT NULL,
    content STRING,
    PRIMARY KEY (post_id),
    FOREIGN KEY (poster_id) REFERENCES users(uid)
);

DROP TABLE IF EXISTS saved_posts;
CREATE TABLE saved_posts(
    uid int NOT NULL,
    post_id int NOT NULL,
    deactivated TINYINT,
    PRIMARY KEY(uid, post_id)
);
DROP TABLE IF EXISTS favorite_posts;
CREATE TABLE favorite_posts(
    uid int NOT NULL,
    post_id int NOT NULL,
    deactivated TINYINT,
    PRIMARY KEY(uid, post_id)
);
DROP TABLE IF EXISTS messages;
CREATE TABLE messages(
    timestamp INT NOT NULL,
    sender_id INT NOT NULL,
    thread_id INT NOT NULL,
    message STRING,
    media_id INT NOT NULL,
    deleted TINYINT NOT NULL,
    PRIMARY KEY (timestamp, sender_id),
    FOREIGN KEY (media_id) REFERENCES media(media_id),
    FOREIGN KEY (sender_id) REFERENCES users(uid),
    FOREIGN KEY (thread_id) REFERENCES threads(thread_id)
);
DROP TABLE IF EXISTS likes;
CREATE TABLE likes(
    like_id INT PRIMARY KEY,
    post_id INT NOT NULL,
    user_id INT NOT NULL,
    comment_id INT NOT NULL,
    time_liked TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES posts(post_id),
    FOREIGN KEY (user_id) REFERENCES users(uid) ON DELETE CASCADE,
    FOREIGN KEY (comment_id) REFERENCES comments(comment_id),
    UNIQUE (user_id, post_id, comment_id)
);

INSERT INTO users(uid, name, user_name, email, birth_year, gender, messages,posts,deleted)
VALUES(1, 'Mike Griffin', 'mjg', 'hotmail@gmail.com', 1999, 'male', 0),
    (2, 'Watson Blair', 'WLB', 'gmail@compuserve.com', 1988, 'male', 0),
    (3, 'Leon Lion', 'llion', 'compuserve@compuserve.com', 2000, 'female', 0),
    (4, 'Will Torres', 'WWT', 'hotmail@gmail.com', 1996, 'non-binary',0),
    (5, 'Mack McGee', 'MMG', 'gmail@hotmail.com', 2001, 'male', 0);

INSERT INTO posts(post_id,poster_id,content) 
VALUES(1,11, NULL,'I enjoy eating ice cream'),
(2,12,'I do not enjoy riding the train'),
(3,13,'I am looking forward to Christmas'),
(4,14,'我喜欢看胖女人吃双层芝士汉堡'),
(5,15,'أريد السفر إلى المريخ');

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


--QUERIES FOR PART 1--

--Query using 'WHERE' and 'OR'--
UPDATE users 
SET gender = 'non-binary'
WHERE uid = 1 OR birth_year = 1996;

--Query using 'ORDER BY'--
SELECT * FROM comment
ORDER BY reply_to ASC;

--Query using GROUP BY--
SELECT COUNT(uid)
FROM users
GROUP BY birth_year;

--Query using Having--
Select COUNT(uid), advertisement_metadata,
FROM users
GROUP BY advertisement_metadata
HAVING COUNT(uid)>2;

--Query using between and AND--
Select content FROM posts
WHERE post_id BETWEEN 1 AND 3
AND poster_id >11;

--Views--
create view legal_info as
select uid, name, birth_year, gender
from users;

create view LANGUAGE as
select content
from posts
AND
select content
from comments
AND
select message
from messages;