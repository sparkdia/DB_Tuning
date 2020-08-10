SET hive.exec.dynamic.partition.mode=nonstrict;
SET hive.exec.max.dynamic.partitions=1000;
SET hive.exec.max.dynamic.partitions.pernode=300;
SET hive.mapred.mode='strict';
SET hive.strict.checks.cartesian.product=false;

set hive.auto.convert.join=false;
INSERT INTO TABLE TEST_DW.CNTRY_IP_RANGE_EXTENT PARTITION(IP_OCTET1)
SELECT L.CNTRY_CD
     , L.CNTRY_NM
     , L.START_IP
     , L.END_IP
     , L.START_IP_NUMT
     , L.END_IP_NUMT
     , L.OCTET2_GAP
     , L.OCTET3_GAP
     , L.PART_OCTET2_SEQ
     , L.PART_OCTET3_SEQ
     , CASE WHEN L.PART_OCTET3_SEQ = 1 
            THEN L.PART_START_IP
            ELSE CONCAT(  L.IP_OCTET1, '.'
                        , SPLIT(L.PART_START_IP, '\\.')[1], '.'
                        , CAST( CAST(L.CURR_IP_NUMT % 65536 / 256 AS BIGINT) AS STRING)
                        , '.0')
        END AS PART_START_IP
     , CASE WHEN L.PART_OCTET3_SEQ = L.OCTET3_GAP
            THEN L.PART_END_IP
            ELSE CONCAT(  L.IP_OCTET1, '.'
                        , SPLIT(L.PART_END_IP, '\\.')[1], '.'
                        , CAST( CAST(L.CURR_IP_NUMT % 65536 / 256 AS BIGINT) AS STRING)
                        , '.255')
        END AS PART_END_IP
     , CASE WHEN L.PART_OCTET3_SEQ = 1
            THEN L.PART_START_IP_NUMT
            ELSE CAST( L.CURR_IP_NUMT - (L.CURR_IP_NUMT % 256) AS BIGINT)
        END AS PART_START_IP_NUMT
     , CASE WHEN L.PART_OCTET3_SEQ = L.OCTET3_GAP
            THEN L.PART_END_IP_NUMT
            ELSE CAST( L.CURR_IP_NUMT - (L.CURR_IP_NUMT % 256) + 65535 AS BIGINT)
        END AS PART_END_IP_NUMT
     , CASE WHEN L.PART_OCTET3_SEQ = 1 
            THEN CONCAT(  L.IP_OCTET1, '.'
                        , SPLIT(L.PART_START_IP, '\\.')[1], '.' 
                        , SPLIT(L.PART_START_IP, '\\.')[2] )
            ELSE CONCAT(  L.IP_OCTET1, '.'
                        , SPLIT(L.PART_START_IP, '\\.')[1], '.'
                        , CAST( CAST(L.CURR_IP_NUMT % 65536 / 256 AS BIGINT) AS STRING) )
        END AS IP_OCTET123_DIV
     , L.IP_OCTET1
  FROM TEST_TMP.CNTRY_IP_RANGE_EXTENT_NUMT L
 WHERE L.IP_OCTET1 = ${hivevar:VAR_OCTET1}
;

