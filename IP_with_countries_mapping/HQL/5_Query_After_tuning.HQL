---------------------------------------------------------------------------------------------------
-- Query after tuning.

SET hive.exec.dynamic.partition.mode=nonstrict;
SET hive.exec.max.dynamic.partitions=1000;
SET hive.exec.max.dynamic.partitions.pernode=300;
SET hive.auto.convert.join=false;


---------------------------------------------------------------------------------------------------
SET hivevar:ACC_ID = '140137_3';
SET hivevar:ACC_START_DT = '20200805';


---------------------------------------------------------------------------------------------------
INSERT INTO TEST_DW.ACC_IP_CNTRY_MAPP PARTITION (ACC_ID, ACC_START_DT)
SELECT H.IP_ADDR
     , G.CNTRY_CD
     , G.CNTRY_NM
     , H.ACC_ID
     , H.ACC_START_DT
  FROM (
        SELECT IP_ADDR
             , COALESCE(SPLIT(IP_ADDR,'\\.')[0], '_')   AS IP_OCTET1
             , CAST( SPLIT(IP_ADDR,'\\.')[0] AS BIGINT) * 16777216 +
               CAST( SPLIT(IP_ADDR,'\\.')[1] AS BIGINT) * 65536 +
               CAST( SPLIT(IP_ADDR,'\\.')[2] AS BIGINT) * 256 +
               CAST( SPLIT(IP_ADDR,'\\.')[3] AS BIGINT) AS IP_ADDR_NUMT
             , ${ACC_ID}         AS ACC_ID
             , ${ACC_START_DT}   AS ACC_START_DT
             , CONCAT( SPLIT(IP_ADDR,'\\.')[0], '.', SPLIT(IP_ADDR,'\\.')[1], '.', SPLIT(IP_ADDR,'\\.')[2] ) AS IP_OCTET123_DIV
          FROM TEST_ODS.ACC_LOG
         WHERE ACC_ID       = ${ACC_ID}
           AND ACC_START_DT = ${ACC_START_DT}
         GROUP BY IP_ADDR
     ) H
 INNER JOIN
       (
        SELECT IP_OCTET1
             , IP_OCTET123_DIV
             , PART_START_IP_NUMT
             , PART_END_IP_NUMT
             , CNTRY_CD
             , CNTRY_NM
          FROM TEST_DW.CNTRY_IP_RANGE_EXTENT
     ) G
    ON H.IP_OCTET1       = G.IP_OCTET1
   AND H.IP_OCTET123_DIV = G.IP_OCTET123_DIV 
 WHERE H.IP_ADDR_NUMT BETWEEN G.PART_START_IP_NUMT AND G.PART_END_IP_NUMT
;

