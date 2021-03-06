
LIBNAME RIMA "S:\File Storage\RIMA\MCT\SAS Teaching2021\Scripts";

DATA RIMA.CUSTOMER;
 INPUT CUSTOMER_ID P_DATE DATE9. AMOUNT ;
DATALINES;
1001 1JAN2020  200 
1001 4JAN2020  120
1001 28DEC2019  50
1001 22DEC2019  50
1001 26NOV2019  70
1001 22nov2019  50
1002 02JAN2020 200 
1002 04DEC2019 120
1002 28DEC2019 150
1002 22DEC2019  50
1002 26NOV2019  70
1002 22nov2019  50
1002 1JAN2020  200 
1002 4JAN2020   20
1002 28DEC2019  50
1002 22DEC2019  20
1002 26NOV2019  10
1003 07JAN2020  35
1004 16DEC2019  20
1004 12JAN2019  20
1004 12JAN2019  25
1005 24DEC2019 100
1005 16DEC2019  30
1005 12JAN2019  20
1005 28DEC2019  29
1006 07DEC2019  20
1006 01DEC2019  36
1007 01JAN2020 100
1007 07DEC2019  20
1007 01DEC2019  20
1008 19NOV2019 950
1009 05DEC2019 450
1009 07DEC2019 150
1009 01DEC2019 150
1009 01JAN2020 100
1009 07DEC2019 100
1009 01DEC2019 120
1009 29NOV2019 100
1009 22NOV2019 100
1009 17NOV2019 120
1009 15NOV2019 150
1009 12NOV2019 150
1009 08NOV2019 450
1009 01NOV2019 200
1009 30OCT2019 100
1009 29OCT2019 190
1010 29DEC019  100
1010 12JAN2019  31
1010 24DEC2019  10
1010 16DEC2019  30
1010 12JAN2019  20
1011 05JAN2020 150
1011 01NOV2019 200
1011 30OCT2019 100
1011 29OCT2019 190
1011 29DEC019  100
1011 12JAN2019  50
1011 24DEC2019  10
1011 16DEC2019  45
1012 07JAN2020 400
1012 29DEC2019 200
1012 01JAN2019 100
1012 24DEC2019 150
1012 16DEC2019 150
1012 12DEC2019 150
1012 01JAN2020 150
1012 01NOV2019 210
1013 12DEC2019  20
1013 29OCT2019  20
1013 29DEC2019  14
1014 21DEC2019  20
1014 12DEC2019  20
1015 03JAN2020  25
;
RUN;

PROC PRINT DATA = RIMA.CUSTOMER;
 FORMAT P_DATE DATE9.;
RUN;

PROC CONTENTS DATA = RIMA.CUSTOMER SHORT VARNUM;RUN;

*CUSTOMER_ID P_DATE AMOUNT;

*CALCULATE RECENCY AND ITS SCORE;
*CALCULATE FREQUENCY AND ITS SCORE;
*CALUCLATE MONETARY AND ITS SCORE;

*RECENCY;
*FIXED DATE : TODAY();

PROC SQL;
 CREATE TABLE R1 AS
 SELECT  CUSTOMER_ID,P_DATE FORMAT DATE9.
 FROM RIMA.CUSTOMER
 GROUP BY CUSTOMER_ID
 ORDER BY CUSTOMER_ID,P_DATE DESC
 ;
QUIT;

DATA R2;
 SET R1;
 BY CUSTOMER_ID;
 IF FIRST.CUSTOMER_ID;
 RECENCY = INTCK('DAY',P_DATE,"8JAN2020"D);
RUN;

*RANK DAYS INTO 5 CATERGORIES;
*SCORE TOP 1-3 DAYS : 5 RECENCEY POINTS
		   4-6 DAYS : 4
		   7-9 DAYS : 3
			10-12 DAYS : 2
			13-15 DAYS : 1;

DATA R3;
 SET R2;
 IF RECENCY IN (1,2,3) THEN RECENCY_SCORE = 5;
 ELSE IF RECENCY IN (4,5,6) THEN RECENCY_SCORE = 4;
  ELSE IF RECENCY IN (7,8,9) THEN RECENCY_SCORE = 3;
   ELSE IF RECENCY IN (10,11,12) THEN RECENCY_SCORE = 2;
    ELSE RECENCY_SCORE = 1;
RUN ;

PROC FREQ DATA = R3;
 TABLE RECENCY_SCORE;
RUN;

*FREQUENCY;
PROC SQL;
 CREATE TABLE F1 AS
 SELECT CUSTOMER_ID, COUNT(P_DATE) AS FREQUENCY
 FROM RIMA.CUSTOMER
 GROUP BY CUSTOMER_ID
 ;
 QUIT;

 *OR;
 DATA F1A;
  SET RIMA.CUSTOMER;
  BY CUSTOMER_ID;
  IF FIRST.CUSTOMER_ID THEN FREQUENCY = 0;
   FREQUENCY+1;*SUM STATEMENT;
 IF LAST.CUSTOMER_ID;
 DROP P_DATE AMOUNT;
 RUN;

*FREQUENCY SCORE CRITERIA;
*SCORE TOP 1-3  : 5 FREQ POINTS
		   4-6  : 4
		   7-9  : 3
		   10-12  : 2
		   13-15  : 1;
DATA F2;
 SET F1;
 IF FREQUENCY IN (1,2,3) THEN FREQUENCY_SCORE = 5;
 ELSE IF FREQUENCY IN (4,5,6) THEN FREQUENCY_SCORE = 4;
  ELSE IF FREQUENCY IN (7,8,9) THEN FREQUENCY_SCORE = 3;
   ELSE IF FREQUENCY IN (10,11,12) THEN FREQUENCY_SCORE = 2;
    ELSE IF FREQUENCY IN (13,14,15) THEN FREQUENCY_SCORE = 1;
RUN;

*MONETARY;
PROC SQL;
 CREATE TABLE M1 AS
 SELECT CUSTOMER_ID, SUM(AMOUNT) AS MONETARY
 FROM RIMA.CUSTOMER
 GROUP BY CUSTOMER_ID
 ;
 QUIT;
*MONETARY SCORE;

DATA M2;
 SET M1;
 IF  2000 <= MONETARY < 3000 THEN MONETARY_SCORE = 5;
 ELSE IF 1500 <= MONETARY < 2000  THEN MONETARY_SCORE = 4;
  ELSE IF 1000 <= MONETARY < 1500  THEN MONETARY_SCORE = 3;
   ELSE IF 500 <= MONETARY < 1000  THEN MONETARY_SCORE = 2;
    ELSE IF MONETARY LE 500 THEN MONETARY_SCORE = 1;
RUN;

*COMBINED ALL THREE DATA SETS : R2,F2 AND M2;
PROC SQL;
 CREATE TABLE RFM AS
 SELECT A.CUSTOMER_ID,
		A.RECENCY_SCORE, 
		B.FREQUENCY_SCORE,
		C.MONETARY_SCORE
 FROM R3 AS A LEFT JOIN F2 AS B 
 ON A.CUSTOMER_ID = B.CUSTOMER_ID
 LEFT JOIN M2 AS C
 ON A.CUSTOMER_ID = C.CUSTOMER_ID
 ;
 QUIT;

 *FIND MEAN SCORE OF R,F,M;
 *THEN GROUP INTO ;
