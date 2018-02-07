-- MySQL dump 10.13  Distrib 5.5.31, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: d37433
-- ------------------------------------------------------
-- Server version	5.5.31-0ubuntu0.12.10.1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `blog`
--

DROP TABLE IF EXISTS `blog`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `blog` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `blog` text NOT NULL,
  `youtube_link` varchar(99) DEFAULT NULL,
  `datetime` datetime NOT NULL,
  `title` varchar(100) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `comment`
--

DROP TABLE IF EXISTS `comment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `comment` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `blog_id` int(10) unsigned NOT NULL,
  `comment` varchar(255) NOT NULL,
  `datetime` datetime NOT NULL,
  `name` varchar(200) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `blog_id` (`blog_id`),
  CONSTRAINT `comment_ibfk_1` FOREIGN KEY (`blog_id`) REFERENCES `blog` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ds_api`
--

DROP TABLE IF EXISTS `ds_api`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ds_api` (
  `name` varchar(100) NOT NULL DEFAULT '',
  `script` text NOT NULL,
  `active` tinyint(1) DEFAULT '1',
  `version` int(11) DEFAULT '1',
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `desc` varchar(500) NOT NULL,
  `signature` varchar(100) NOT NULL,
  `internal` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=27 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ds_api_datastructure`
--

DROP TABLE IF EXISTS `ds_api_datastructure`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ds_api_datastructure` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `desc` varchar(5000) DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ds_api_datastructure_elem`
--

DROP TABLE IF EXISTS `ds_api_datastructure_elem`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ds_api_datastructure_elem` (
  `api_datastructure_id` int(10) unsigned NOT NULL DEFAULT '0',
  `name` varchar(100) NOT NULL,
  `type` varchar(100) NOT NULL,
  `desc` varchar(500) NOT NULL,
  PRIMARY KEY (`api_datastructure_id`,`name`),
  CONSTRAINT `ds_api_datastructure_elem_ibfk_1` FOREIGN KEY (`api_datastructure_id`) REFERENCES `ds_api_datastructure` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ds_api_param`
--

DROP TABLE IF EXISTS `ds_api_param`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ds_api_param` (
  `api_id` int(10) NOT NULL DEFAULT '0',
  `name` varchar(100) NOT NULL,
  `type` varchar(100) NOT NULL,
  `desc` varchar(500) NOT NULL,
  UNIQUE KEY `index1` (`api_id`,`name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ds_card`
--

DROP TABLE IF EXISTS `ds_card`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ds_card` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `text` text NOT NULL,
  `img` varchar(100) DEFAULT NULL,
  `sound` varchar(100) DEFAULT NULL,
  `script` text,
  `user_id` int(10) unsigned DEFAULT NULL,
  `title` varchar(100) NOT NULL,
  `dir` varchar(100) NOT NULL,
  `final` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uc_title` (`user_id`,`title`),
  CONSTRAINT `user_fk` FOREIGN KEY (`user_id`) REFERENCES `ds_user` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=79 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ds_card_has_script`
--

DROP TABLE IF EXISTS `ds_card_has_script`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ds_card_has_script` (
  `game_id` int(10) unsigned NOT NULL DEFAULT '0',
  `card_id` int(10) unsigned NOT NULL DEFAULT '0',
  `onpickup` text,
  `onplay` text,
  PRIMARY KEY (`game_id`,`card_id`),
  KEY `card_id` (`card_id`),
  CONSTRAINT `ds_card_has_script_ibfk_1` FOREIGN KEY (`game_id`) REFERENCES `ds_game` (`id`),
  CONSTRAINT `ds_card_has_script_ibfk_2` FOREIGN KEY (`card_id`) REFERENCES `ds_card` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ds_deck`
--

DROP TABLE IF EXISTS `ds_deck`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ds_deck` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `user_id` int(10) unsigned DEFAULT NULL,
  `public` tinyint(1) DEFAULT '0',
  `final` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name_unasd` (`name`,`user_id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `ds_deck_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `ds_user` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ds_deck_card`
--

DROP TABLE IF EXISTS `ds_deck_card`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ds_deck_card` (
  `card_id` int(10) unsigned NOT NULL,
  `deck_id` int(10) unsigned NOT NULL,
  `nr` int(10) unsigned NOT NULL,
  PRIMARY KEY (`card_id`,`deck_id`),
  KEY `deck_id` (`deck_id`),
  CONSTRAINT `ds_deck_card_ibfk_1` FOREIGN KEY (`card_id`) REFERENCES `ds_card` (`id`),
  CONSTRAINT `ds_deck_card_ibfk_2` FOREIGN KEY (`deck_id`) REFERENCES `ds_deck` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ds_game`
--

DROP TABLE IF EXISTS `ds_game`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ds_game` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(100) DEFAULT NULL,
  `description` varchar(1000) DEFAULT NULL,
  `init_script` text CHARACTER SET latin1,
  `user_id` int(10) unsigned DEFAULT NULL,
  `public` tinyint(1) DEFAULT NULL,
  `max_players` int(11) NOT NULL,
  `min_players` int(11) NOT NULL,
  `hands` int(11) DEFAULT '1',
  `player_slots` int(11) DEFAULT '0',
  `table_slots` int(11) DEFAULT '1',
  `tables` int(11) DEFAULT '1',
  `onpickup_all` varchar(10000) DEFAULT '',
  `onplay_all` varchar(10000) DEFAULT '',
  `onendturn` text,
  `onbeginturn` text,
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_id` (`user_id`,`name`),
  CONSTRAINT `ds_game_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `ds_user` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ds_game_has_deck`
--

DROP TABLE IF EXISTS `ds_game_has_deck`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ds_game_has_deck` (
  `game_id` int(10) unsigned DEFAULT NULL,
  `deck_id` int(10) unsigned DEFAULT NULL,
  `nr` int(11) DEFAULT '1',
  UNIQUE KEY `deck_id` (`deck_id`,`game_id`),
  KEY `game_id` (`game_id`),
  CONSTRAINT `ds_game_has_deck_ibfk_1` FOREIGN KEY (`game_id`) REFERENCES `ds_game` (`id`),
  CONSTRAINT `ds_game_has_deck_ibfk_2` FOREIGN KEY (`deck_id`) REFERENCES `ds_deck` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ds_game_session`
--

DROP TABLE IF EXISTS `ds_game_session`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ds_game_session` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `comment` varchar(500) DEFAULT NULL,
  `password` varchar(100) DEFAULT NULL,
  `user_id` int(10) unsigned DEFAULT NULL,
  `public` tinyint(1) DEFAULT '1',
  `port` int(11) NOT NULL,
  `started` datetime DEFAULT '0000-00-00 00:00:00',
  `ended` datetime DEFAULT '0000-00-00 00:00:00',
  `created` datetime NOT NULL,
  `game_id` int(10) unsigned DEFAULT NULL,
  `debug` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `game_id` (`game_id`),
  KEY `fk1` (`user_id`),
  CONSTRAINT `ds_game_session_ibfk_2` FOREIGN KEY (`game_id`) REFERENCES `ds_game` (`id`),
  CONSTRAINT `fk1` FOREIGN KEY (`user_id`) REFERENCES `ds_user` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1401 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ds_participates`
--

DROP TABLE IF EXISTS `ds_participates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ds_participates` (
  `game_session_id` int(10) unsigned NOT NULL DEFAULT '0',
  `user_id` int(10) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`game_session_id`,`user_id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `ds_participates_ibfk_1` FOREIGN KEY (`game_session_id`) REFERENCES `ds_game_session` (`id`),
  CONSTRAINT `ds_participates_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `ds_user` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ds_session`
--

DROP TABLE IF EXISTS `ds_session`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ds_session` (
  `deck_id` int(10) unsigned DEFAULT NULL,
  `datetime` datetime NOT NULL,
  `user_id` int(10) unsigned DEFAULT NULL,
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`),
  UNIQUE KEY `deckuser` (`deck_id`,`user_id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `ds_session_ibfk_1` FOREIGN KEY (`deck_id`) REFERENCES `ds_deck` (`id`),
  CONSTRAINT `ds_session_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `ds_user` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ds_session_card`
--

DROP TABLE IF EXISTS `ds_session_card`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ds_session_card` (
  `session_id` int(10) unsigned DEFAULT NULL,
  `card_id` int(10) unsigned DEFAULT NULL,
  `nr` int(10) unsigned DEFAULT NULL,
  UNIQUE KEY `session_card` (`session_id`,`card_id`),
  KEY `card_id` (`card_id`),
  CONSTRAINT `ds_session_card_ibfk_1` FOREIGN KEY (`session_id`) REFERENCES `ds_session` (`id`),
  CONSTRAINT `ds_session_card_ibfk_2` FOREIGN KEY (`card_id`) REFERENCES `ds_card` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ds_user`
--

DROP TABLE IF EXISTS `ds_user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ds_user` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `username` varchar(100) NOT NULL,
  `password` varchar(50) NOT NULL,
  `email` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=32 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ds_user_cookie`
--

DROP TABLE IF EXISTS `ds_user_cookie`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ds_user_cookie` (
  `user_id` int(10) unsigned DEFAULT NULL,
  `datetime` datetime NOT NULL,
  `login_session_id` int(10) unsigned NOT NULL,
  KEY `user_id` (`user_id`,`login_session_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2013-07-12 23:23:34
