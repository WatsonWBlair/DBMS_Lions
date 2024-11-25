--   Users 表
CREATE TABLE Users (
    UserID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(100) NOT NULL, 
    Email VARCHAR(100), 
    Deleted TINYINT DEFAULT 0 --  Tag delete or not（标记是否删除），0为正常，1为删除
);

--   Posts 表
CREATE TABLE Posts (
    PostID INT PRIMARY KEY AUTO_INCREMENT,
    PosterID INT NOT NULL, 
    Thumbnail INT, 
    Content TEXT, 
    Deleted TINYINT DEFAULT 0, --  Tag delete or not（标记是否删除）
    Private TINYINT DEFAULT 0, -- Private or not（是否为私人）
    FOREIGN KEY (PosterID) REFERENCES Users(UserID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

--   SavedPosts 表
CREATE TABLE SavedPosts (
    UserID INT NOT NULL, 
    PostID INT NOT NULL, 
    Deactivated TINYINT DEFAULT 0, -- Mark if it is deactivated（标记是否删除）
    PRIMARY KEY (UserID, PostID),
    FOREIGN KEY (UserID) REFERENCES Users(UserID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (PostID) REFERENCES Posts(PostID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

--   FavoriatePosts 表
CREATE TABLE FavoriatePosts (
    UserID INT NOT NULL, 
    PostID INT NOT NULL, 
    Deactivated TINYINT DEFAULT 0, -- Mark if it is deactivated（标记是否删除）
    PRIMARY KEY (UserID, PostID),
    FOREIGN KEY (UserID) REFERENCES Users(UserID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (PostID) REFERENCES Posts(PostID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

--   Comments 表
CREATE TABLE Comments (
    CommentID INT PRIMARY KEY AUTO_INCREMENT, 
    OnPost INT NOT NULL, 
    ReplyTo INT, -- If NULL, it is a Level 1 comment（如果为 NULL，则是一级评论）
    FromID INT NOT NULL, 
    Content TEXT NOT NULL,
    Deleted TINYINT DEFAULT 0, --  Tag delete or not（标记是否删除）
    FOREIGN KEY (OnPost) REFERENCES Posts(PostID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (ReplyTo) REFERENCES Comments(CommentID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (FromID) REFERENCES Users(UserID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

--   Media 表
CREATE TABLE Media (
    MediaID INT PRIMARY KEY AUTO_INCREMENT, 
    UserID INT NOT NULL, 
    Timestamp DATETIME NOT NULL, 
    Media BLOB NOT NULL, 
    FOREIGN KEY (UserID) REFERENCES Users(UserID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

--   Messages 表
CREATE TABLE Messages (
    MessageID INT PRIMARY KEY AUTO_INCREMENT, 
    SenderID INT NOT NULL, 
    ReceiverID INT NOT NULL, 
    Message TEXT NOT NULL, 
    MediaID INT, 
    Deleted TINYINT DEFAULT 0, --  Tag delete or not（标记是否删除）
    FOREIGN KEY (SenderID) REFERENCES Users(UserID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (ReceiverID) REFERENCES Users(UserID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (MediaID) REFERENCES Media(MediaID)
        ON DELETE CASCADE ON UPDATE CASCADE
);
