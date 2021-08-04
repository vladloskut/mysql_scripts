SELECT DBName,
  CONCAT(LPAD(FORMAT(SDSize/POWER(1024,pw),3),17,' '),' ',SUBSTR(' KMGTP',pw+1,1),'B') "Data Size",
  CONCAT(LPAD(FORMAT(SXSize/POWER(1024,pw),3),17,' '),' ',SUBSTR(' KMGTP',pw+1,1),'B') "Index Size",
  CONCAT(LPAD(FORMAT(STSize/POWER(1024,pw),3),17,' '),' ',SUBSTR(' KMGTP',pw+1,1),'B') "Total Size" 
FROM (
  SELECT IFNULL(DB,'All Databases') DBName,
  SUM(DSize) SDSize,
  SUM(XSize) SXSize,
  SUM(TSize) STSize 
  FROM (
    SELECT table_schema DB,
      data_length DSize,
      index_length XSize,
      data_length+index_length TSize 
    FROM information_schema.tables 
    WHERE table_schema NOT IN ('mysql','information_schema','performance_schema')) AAA 
    GROUP BY DB WITH ROLLUP
) AA,
(SELECT 2 pw) BB 
ORDER BY (SDSize+SXSize);
