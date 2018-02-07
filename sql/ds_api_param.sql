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
-- Dumping data for table `ds_api_param`
--

LOCK TABLES `ds_api_param` WRITE;
/*!40000 ALTER TABLE `ds_api_param` DISABLE KEYS */;
INSERT INTO `ds_api_param` VALUES (1,'deck_id','int','Id of deck.'),(2,'deck_id','int',''),(2,'nr','int','number of cards to pick.'),(2,'player_nr','int','nr of player to put card in.'),(3,'deck','deck','(use get_deck to get deck from a deck id)'),(4,'deck_id','int','id of deck. Deck must have been added to game.'),(4,'table_slot','int','id of slot, ranging from 1 to number of total slots.'),(5,'action_name','string','name of action. Supported actions are \"pick_card\".'),(5,'target','string','target kind. Supported kinds are \"deck\".'),(5,'target_id','int','id of target. If target kind is \"deck\", target_id would correspond to deck_id.'),(6,'table','table','any table'),(8,'table','table','any array-like table (like {1, 2, 3} or {\"a\", \"b\", \"c\"})');
/*!40000 ALTER TABLE `ds_api_param` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2013-05-27 14:05:22
