-- MySQL dump 10.13  Distrib 5.5.31, for debian-linux-gnu (i686)
--
-- Host: localhost    Database: d37433
-- ------------------------------------------------------
-- Server version	5.5.31-0ubuntu0.12.04.1

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
  PRIMARY KEY (`id`),
  UNIQUE KEY `uc_title` (`user_id`,`title`),
  CONSTRAINT `user_fk` FOREIGN KEY (`user_id`) REFERENCES `ds_user` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=32 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ds_card`
--

LOCK TABLES `ds_card` WRITE;
/*!40000 ALTER TABLE `ds_card` DISABLE KEYS */;
INSERT INTO `ds_card` VALUES (17,'You enter the room','','','',NULL,'1',''),(18,'You enter the room.','','','',20,'2','anders'),(19,'This is another test card with a lot of information.','spelare.jpg','','',20,'3','anders'),(20,'Bla bla bla','','','',20,'4','anders'),(21,'card','absolutely_nothing_road_sign_lg.jpg','','',20,'5','anders'),(22,'a card, a card 2','spelare.jpg','',NULL,20,'dfg','anders'),(23,'','queenofspades.jpg','',NULL,20,'Queen of spades','anders'),(24,'','kingofspades.jpg','',NULL,20,'King of spades','anders'),(25,'','knightofspades.jpg','',NULL,20,'Knight of spades','anders'),(26,'','tenofspades.png','',NULL,20,'Ten of spades','anders'),(27,'','nineofspades.jpg','',NULL,20,'Nine of spades','anders'),(28,'test','Baby Seal 3..jpg','',NULL,20,'test',''),(29,'','babyseal.jpg','',NULL,20,'seal',''),(30,'','Baby Seal..jpg','',NULL,20,'seal2','');
/*!40000 ALTER TABLE `ds_card` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2013-05-24 16:33:36
