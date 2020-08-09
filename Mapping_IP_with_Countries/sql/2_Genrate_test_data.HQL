----------------------------------------------------------------------------------------------------
-- Test Data Generation.

SET hive.exec.dynamic.partition.mode=nonstrict;
SET hive.exec.max.dynamic.partitions=1000;
SET hive.exec.max.dynamic.partitions.pernode=300;
SET hive.mapred.mode='strict';
SET hive.strict.checks.cartesian.product=false;
SET hive.auto.convert.join=false;

----------------------------------------------------------------------------------------------------
INSERT INTO TABLE TEST_DW.CNTRY_IP_RANGE PARTITION(IP_OCTET1)
SELECT I.CNTRY_CD
     , COALESCE(C.NAME, I.CNTRY_CD)    AS CNTRY_NM
     , I.START_IP
     , I.END_IP
     , CAST( CAST( SPLIT(I.START_IP,'\\.')[0] AS BIGINT) * 16777216 +
             CAST( SPLIT(I.START_IP,'\\.')[1] AS BIGINT) * 65536 +
             CAST( SPLIT(I.START_IP,'\\.')[2] AS BIGINT) * 256 +
             CAST( SPLIT(I.START_IP,'\\.')[3] AS BIGINT) AS STRING)  AS START_IP_NUMT
     , CAST( CAST( SPLIT(I.END_IP,'\\.')[0] AS BIGINT) * 16777216 +
             CAST( SPLIT(I.END_IP,'\\.')[1] AS BIGINT) * 65536 +
             CAST( SPLIT(I.END_IP,'\\.')[2] AS BIGINT) * 256 +
             CAST( SPLIT(I.END_IP,'\\.')[3] AS BIGINT) AS STRING)    AS END_IP_NUMT
     , SPLIT(I.START_IP,'\\.')[0]     AS IP_OCTET1
  FROM (
        SELECT START_IP
             , END_IP
             , CNTRY_CD
          FROM TEST_ODS.CNTRY_IP_RANGE_EXT
     ) I
  LEFT OUTER JOIN (
        SELECT CODE
             , NAME
          FROM TEST_ODS.CNTRY_CD_EXT
     ) C
    ON I.CNTRY_CD = C.CODE 
;


----------------------------------------------------------------------------------------------------
INSERT INTO TEST_TMP.DUMMY
SELECT ROW_NUMBER() OVER(ORDER BY CNTRY_CD) AS DUMMY_SEQ 
  FROM TEST_DW.CNTRY_IP_RANGE
;


----------------------------------------------------------------------------------------------------
INSERT INTO TABLE TEST_ODS.ACC_LOG PARTITION(ACC_START_DT)
SELECT CONCAT(DATE_FORMAT(CURRENT_TIMESTAMP(), 'HHmmss'), '_', CAST((RAND() * 10)% 5 + 1 AS INT) ) AS ACC_ID
     , CURRENT_TIMESTAMP()                                                                AS ACC_START_TS
     , CONCAT( CAST(CAST(R.RAND_NUM / 16777216 AS INT)    AS STRING) , '.',
               CAST(CAST(R.RAND_NUM / 65536 % 256 AS INT) AS STRING) , '.',
               CAST(CAST(R.RAND_NUM / 256 % 256 AS INT)   AS STRING) , '.',
               CAST(CAST(R.RAND_NUM % 256 AS INT) AS STRING) 
             ) AS IP_ADDR
     , DATE_FORMAT(CURRENT_DATE(), 'yyyyMMdd')      AS ACC_START_DT
  FROM (
        SELECT CAST(RAND() * 10000000000 % 3741253374 + 16843009 AS INT)     AS RAND_NUM
          FROM TEST_TMP.DUMMY D
          JOIN (SELECT DUMMY_SEQ FROM TEST_TMP.DUMMY LIMIT 55) D2   -- you can adjust count of acc_log table.
     ) R
;



