--- CREATE DATABASE IF NOT EXISTS `redactatron`;
--- use `redactatron`;

CREATE TABLE `gn_data` (
    `gnd_key` varchar(64) NOT NULL,
    `gnd_value` blob NOT NULL,
    PRIMARY KEY (`gnd_key`)
) Engine=InnoDB CHARSET=utf8;

