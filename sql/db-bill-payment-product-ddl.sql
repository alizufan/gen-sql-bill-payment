-- Bill Payment: Create Table Product Category
CREATE TABLE
  `t_bill_product_category` (
    `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Id',
    `secondary_category_code` varchar(10) NOT NULL COMMENT 'Secondary Category Code',
    `product_category_code` varchar(50) NOT NULL COMMENT 'Product Category Code',
    `aggregator` varchar(50) DEFAULT NULL COMMENT 'Aggregator',
    `variant` varchar(50) DEFAULT NULL COMMENT 'Product Category Variant: VOUCHER and DIGITAL',
    `name` varchar(50) DEFAULT NULL COMMENT 'Name',
    `description` varchar(50) DEFAULT NULL COMMENT 'Description',
    `country_code` varchar(2) DEFAULT NULL,
    `is_valid` varchar(2) NOT NULL COMMENT 'Is Valid:Y-yes;N-No',
    `created_by` varchar(64) NOT NULL COMMENT 'Created by',
    `created_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Created time',
    `updated_by` varchar(64) NOT NULL COMMENT 'Updated by',
    `updated_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Updated time',
    PRIMARY KEY (`id`) USING BTREE
  ) ENGINE = InnoDB DEFAULT CHARSET = utf8;

-- Bill Payment: Create Table Product Category Form Input
CREATE TABLE
  `t_bill_product_category_form` (
    `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Id',
    `secondary_category_code` varchar(10) NOT NULL COMMENT 'Secondary Category Code',
    `product_category_code` varchar(50) NOT NULL COMMENT 'Product Category Code',
    `aggregator` varchar(50) DEFAULT NULL COMMENT 'Aggregator',
    `form_key` varchar(100) DEFAULT NULL COMMENT 'Form Key',
    `form_type` varchar(100) DEFAULT NULL COMMENT 'Form Type',
    `form_condition` varchar(100) DEFAULT NULL COMMENT 'Form Condition: required or optional',
    `pattern_validation` varchar(100) DEFAULT NULL COMMENT 'Form Regexp Pattern Match Validation',
    `label` mediumtext COMMENT 'Form Label JSON Bilingual using ISO 639-1 Code',
    `description` mediumtext COMMENT 'Form Description JSON Bilingual using ISO 639-1 Code',
    `more_info` mediumtext COMMENT 'Form More Information JSON Bilingual using ISO 639-1 Code',
    `options` mediumtext COMMENT 'Form Options JSON Bilingual using ISO 639-1 Code',
    `is_valid` varchar(2) NOT NULL COMMENT 'Is Valid: Y-Yes and N-No',
    `sort_no` int(11) NOT NULL COMMENT 'Form Sequence Sort No',
    `created_by` varchar(64) NOT NULL COMMENT 'Created by',
    `created_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Created time',
    `updated_by` varchar(64) NOT NULL COMMENT 'Updated by',
    `updated_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Updated time',
    PRIMARY KEY (`id`) USING BTREE
  ) ENGINE = InnoDB DEFAULT CHARSET = utf8;

-- Bill Payment: Modify Column (bill_extra_info_one, bill_extra_info_two and bill_extra_info_three) type VARCHAR to MEDIUMTEXT on Table Bill Order
ALTER TABLE `t_bill_order` MODIFY `bill_extra_info_one` MEDIUMTEXT NULL;
ALTER TABLE `t_bill_order` MODIFY `bill_extra_info_two` MEDIUMTEXT NULL;
ALTER TABLE `t_bill_order` MODIFY `bill_extra_info_three` MEDIUMTEXT NULL;

-- IPG Base: Modify Column (param_key) type VARCHAR(50) to VARCHAR(255) on Table System Param
ALTER TABLE `t_system_param` MODIFY `param_key` VARCHAR(255) NULL;

-- IPG Base: Seed Record for Update SELL_PRICE and Comission Fee Product List Aggregator `LAPAK GAMING`
insert into `t_system_param` (`business_scenario_name`, `param_description`, `param_key`, `param_value`, `param_value_type`) values 
    ('Bill Payment', 'Configuration Commision Fee Lapak Gaming Price Less Than 50K', 'LAPAK_GAMING_COMMISION_FEE_FORMULA_GAME_VOUCHER_PRICE_LESS_THAN_50K', '5', 'Integer'),
    ('Bill Payment', 'Configuration Commision Fee Lapak Gaming Price Range 50K - 100K ', 'LAPAK_GAMING_COMMISION_FEE_FORMULA_GAME_VOUCHER_PRICE_50K_TO_100K', '5', 'Integer'),
    ('Bill Payment', 'Configuration Commision Fee Lapak Gaming Price Range 100K - 200K ', 'LAPAK_GAMING_COMMISION_FEE_FORMULA_GAME_VOUCHER_PRICE_100K_TO_200K', '6', 'Integer'),
    ('Bill Payment', 'Configuration Commision Fee Lapak Gaming Price Range 200K - 300K ', 'LAPAK_GAMING_COMMISION_FEE_FORMULA_GAME_VOUCHER_PRICE_200K_TO_300K', '6', 'Integer'),
    ('Bill Payment', 'Configuration Commision Fee Lapak Gaming Price Range 300K - 500K ', 'LAPAK_GAMING_COMMISION_FEE_FORMULA_GAME_VOUCHER_PRICE_300K_TO_500K', '7', 'Integer'),
    ('Bill Payment', 'Configuration Commision Fee Lapak Gaming Price Greater Than 500K', 'LAPAK_GAMING_COMMISION_FEE_FORMULA_GAME_VOUCHER_PRICE_GREATER_THAN_500K', '7', 'Integer');