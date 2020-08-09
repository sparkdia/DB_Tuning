---------------------------------------------------------------------------------------------------
SET hive.exec.dynamic.partition.mode=nonstrict;
SET hive.exec.max.dynamic.partitions=1000;
SET hive.exec.max.dynamic.partitions.pernode=300;
SET hive.mapred.mode='strict';
SET hive.strict.checks.cartesian.product=false;
SET hive.auto.convert.join=false;

---------------------------------------------------------------------------------------------------
INSERT INTO TABLE TEST_TMP.CNTRY_IP_RANGE_GAP PARTITION (IP_OCTET1)
SELECT CNTRY_CD
     , CNTRY_NM
     , START_IP
     , END_IP
     , START_IP_NUMT
     , END_IP_NUMT
     , CAST( SPLIT(END_IP,'\\.')[1] AS BIGINT) - CAST( SPLIT(START_IP,'\\.')[1] AS BIGINT) + 1     AS OCTET2_GAP
     , IF ( CAST( SPLIT(END_IP,'\\.')[1] AS BIGINT) - CAST( SPLIT(START_IP,'\\.')[1] AS BIGINT) > 0
           , IF(CAST( SPLIT(END_IP,'\\.')[2] AS BIGINT) - CAST( SPLIT(START_IP,'\\.')[2] AS BIGINT) = 255, 1, -1)
           , CAST( SPLIT(END_IP,'\\.')[2] AS BIGINT) - CAST( SPLIT(START_IP,'\\.')[2] AS BIGINT) +1 ) AS OCTET3_GAP
     , IP_OCTET1
  FROM TEST_DW.CNTRY_IP_RANGE
;



---------------------------------------------------------------------------------------------------
INSERT INTO TABLE TEST_TMP.CNTRY_IP_RANGE_EXTENT_OCTET2_NUMT PARTITION(IP_OCTET1)
SELECT C.CNTRY_CD
     , C.CNTRY_NM
     , C.START_IP
     , C.END_IP
     , C.START_IP_NUMT
     , C.END_IP_NUMT
     , C.OCTET2_GAP
     , C.OCTET3_GAP
     , D.DUMMY_SEQ  AS PART_SEQ
     , CASE WHEN D.DUMMY_SEQ = 1
            THEN C.START_IP_NUMT
            ELSE C.START_IP_NUMT - (C.START_IP_NUMT % 65536) + ((D.DUMMY_SEQ - 1) * 65536)
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
             , OCTET3_GAP
             , IP_OCTET1
          FROM TEST_TMP.CNTRY_IP_RANGE_GAP
     ) C
  JOIN (
        SELECT DUMMY_SEQ
          FROM TEST_TMP.DUMMY
         WHERE DUMMY_SEQ <= 256
     ) D
 WHERE C.OCTET2_GAP >= D.DUMMY_SEQ
;




---------------------------------------------------------------------------------------------------
INSERT INTO TABLE TEST_TMP.CNTRY_IP_RANGE_EXTENT_OCTET2 PARTITION(IP_OCTET1)
SELECT CNTRY_CD
     , CNTRY_NM
     , START_IP
     , END_IP
     , START_IP_NUMT
     , END_IP_NUMT
     , OCTET2_GAP
     , CASE WHEN OCTET3_GAP = -1 OR (OCTET3_GAP = 1 AND OCTET2_GAP > 1)
            THEN CAST(SPLIT(PART_END_IP,'\\.')[2] AS BIGINT) - CAST(SPLIT(PART_START_IP,'\\.')[2] AS BIGINT) + 1
            ELSE OCTET3_GAP
        END AS OCTET3_GAP
     , PART_SEQ
     , PART_START_IP
     , PART_END_IP
     , PART_START_IP_NUMT
     , PART_END_IP_NUMT
     , IP_OCTET1
  FROM (
        SELECT C.CNTRY_CD
             , C.CNTRY_NM
             , C.START_IP
             , C.END_IP
             , C.START_IP_NUMT
             , C.END_IP_NUMT
             , C.OCTET2_GAP
             , C.OCTET3_GAP
             , C.PART_SEQ
             , CASE WHEN C.PART_SEQ = 1 
                    THEN C.START_IP
                    ELSE CONCAT(C.IP_OCTET1, '.'
                                , CAST( CAST( C.CURR_IP_NUMT % 16777216 / 65536 AS BIGINT) AS STRING)
                                , '.0.0')
                END AS PART_START_IP
             , CASE WHEN C.PART_SEQ = C.OCTET2_GAP 
                    THEN C.END_IP
                    ELSE CONCAT(C.IP_OCTET1, '.'
                                , CAST( CAST( C.CURR_IP_NUMT % 16777216 / 65536 AS BIGINT) AS STRING)
                                , '.255.255')
                END AS PART_END_IP
             , CASE WHEN C.PART_SEQ = 1
                    THEN C.START_IP_NUMT
                    ELSE CAST( C.CURR_IP_NUMT - (C.CURR_IP_NUMT % 65536) AS BIGINT)
                END AS PART_START_IP_NUMT
             , CASE WHEN C.PART_SEQ = C.OCTET2_GAP
                    THEN C.END_IP_NUMT
                    ELSE CAST( C.CURR_IP_NUMT - (C.CURR_IP_NUMT % 65536) + 65535 AS BIGINT)
                END AS PART_END_IP_NUMT
             , C.IP_OCTET1
          FROM TEST_TMP.CNTRY_IP_RANGE_EXTENT_OCTET2_NUMT C
     ) Z
;


---------------------------------------------------------------------------------------------------
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
             , OCTET3_GAP
             , PART_SEQ
             , PART_START_IP
             , PART_END_IP
             , PART_START_IP_NUMT
             , PART_END_IP_NUMT
             , IP_OCTET1
          FROM TEST_TMP.CNTRY_IP_RANGE_EXTENT_OCTET2
     ) C
  JOIN (
        SELECT DUMMY_SEQ
          FROM TEST_TMP.DUMMY
         WHERE DUMMY_SEQ <= 256
     ) D
 WHERE C.OCTET3_GAP >= D.DUMMY_SEQ
;


---------------------------------------------------------------------------------------------------
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
;
