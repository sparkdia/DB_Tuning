SET hive.exec.dynamic.partition.mode=nonstrict;
SET hive.exec.max.dynamic.partitions=1000;
SET hive.exec.max.dynamic.partitions.pernode=300;
SET hive.mapred.mode='strict';
SET hive.strict.checks.cartesian.product=false;
SET hive.auto.convert.join=false;


INSERT INTO TABLE TEST_TMP.CNTRY_IP_RANGE_EXTENT_NUMT PARTITION(IP_OCTET1)
SELECT C.CNTRY_CD
     , C.CNTRY_NM
     , C.START_IP
     , C.END_IP
     , C.START_IP_NUMT
     , C.END_IP_NUMT
     , C.OCTET2_GAP
     , C.OCTET3_GAP
     , C.PART_SEQ   AS PART_OCTET2_SEQ
     , D.DUMMY_SEQ  AS PART_OCTET3_SEQ
     , C.PART_START_IP
     , C.PART_END_IP
     , C.PART_START_IP_NUMT
     , C.PART_END_IP_NUMT
     , CASE WHEN D.DUMMY_SEQ = 1
            THEN C.PART_START_IP_NUMT
            ELSE C.PART_START_IP_NUMT - (C.START_IP_NUMT%256) + ((D.DUMMY_SEQ - 1) * 256)
        END AS CURR_IP_NUMT
     , C.IP_OCTET1
  FROM (
        SELECT CNTRY_CD
             , CNTRY_NM
             , START_IP
             , END_IP
             , START_IP_NUMT
             , END_IP_NUMT
             , OCTET2_GAP
             , IF( OCTET3_GAP = -1
                , CAST(SPLIT(PART_END_IP,'\\.')[2] AS BIGINT) - CAST(SPLIT(PART_START_IP,'\\.')[2] AS BIGINT) + 1
                , OCTET3_GAP
                ) AS OCTET3_GAP
             , PART_SEQ
             , PART_START_IP
             , PART_END_IP
             , PART_START_IP_NUMT
             , PART_END_IP_NUMT
             , IP_OCTET1
          FROM TEST_TMP.CNTRY_IP_RANGE_EXTENT_OCTET2
         WHERE OCTET3_GAP NOT IN (1, 2, 4, 8, 16, 32, 64, 128, 256)
     ) C
  JOIN (
        SELECT DUMMY_SEQ
          FROM TEST_TMP.DUMMY
         WHERE DUMMY_SEQ <= 256 
     ) D
 WHERE C.OCTET3_GAP >= D.DUMMY_SEQ
;
