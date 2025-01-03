/* 1. Import Dataset */
PROC IMPORT DATAFILE="\\apporto.com\dfs\STVN\Users\riska_stvn\Desktop\crashdata2011-2021.csv"
    OUT=CrashData
    DBMS=CSV
    REPLACE;
    GETNAMES=YES;
RUN;

/* 2. Data Cleaning */
DATA CrashData_Clean;
    SET CrashData;

    /* Recode binary flags */
    SpeedingFlag = (PrimaryCollisionFactor = "Speeding");
    HitAndRunFlag = (CollisionType = "Hit and Run");
    CityDamageFlag_Num = (CityDamageFlag = "TRUE");

    /* Replace missing values */
    IF MinorInjuries = . THEN MinorInjuries = 0;
    IF ModerateInjuries = . THEN ModerateInjuries = 0;
    IF FatalInjuries = . THEN FatalInjuries = 0;

    /* Log transformation for Distance */
    IF Distance > 0 THEN Log_Distance = LOG(Distance);
    ELSE Log_Distance = .;

    /* Extract Year from CrashDateTime */
    IF CrashDateTime NE '' THEN DO;
        DateTime = INPUT(CrashDateTime, ANYDTDTM.);
        Year = YEAR(DateTime);
    END;
    ELSE Year = .;
RUN;

/* 3. Impute Missing Values */
PROC STDIZE DATA=CrashData_Clean OUT=CrashData_Clean METHOD=MEAN REPLACE;
    VAR Log_Distance IntersectionNumber CityDamageFlag_Num;
RUN;

/* 4. Remove Records with No Injuries */
DATA CrashData_Clean;
    SET CrashData_Clean;
    IF MinorInjuries + ModerateInjuries + FatalInjuries > 0;
RUN;

/* 5. Descriptive Statistics */
PROC MEANS DATA=CrashData_Clean N MEAN STD MIN MAX;
    VAR MinorInjuries ModerateInjuries FatalInjuries Log_Distance;
RUN;

PROC FREQ DATA=CrashData_Clean;
    TABLES SpeedingFlag HitAndRunFlag CityDamageFlag_Num;
RUN;

/* 6. Line Chart: Crash Frequency Over Years */
PROC SQL;
    CREATE TABLE Yearly_Crash AS
    SELECT Year, COUNT(*) AS CrashCount
    FROM CrashData_Clean
    WHERE NOT MISSING(Year)
    GROUP BY Year;
QUIT;

PROC SGPLOT DATA=Yearly_Crash;
    TITLE "Crash Frequency Over Years";
    SERIES X=Year Y=CrashCount / MARKERS;
RUN;

/* 7. Factor Analysis */
PROC FACTOR DATA=CrashData_Clean
    METHOD=PRIN
    ROTATE=VARIMAX
    NFACTORS=2
    OUT=FactorOutput;
    VAR CityDamageFlag_Num Log_Distance IntersectionNumber;
RUN;

/* 8. Multiple Regression Analysis */

/* Regression for Minor Injuries */
PROC REG DATA=CrashData_Clean PLOTS(MAXPOINTS=NONE);
    MODEL MinorInjuries = CityDamageFlag_Num 
                          Log_Distance 
                          IntersectionNumber;
    TITLE "Multiple Regression Analysis for Minor Injuries";
RUN;
QUIT;

/* Regression for Moderate Injuries */
PROC REG DATA=CrashData_Clean PLOTS(MAXPOINTS=NONE);
    MODEL ModerateInjuries = CityDamageFlag_Num 
                             Log_Distance 
                             IntersectionNumber;
    TITLE "Multiple Regression Analysis for Moderate Injuries";
RUN;
QUIT;

/* Regression for Fatal Injuries */
PROC REG DATA=CrashData_Clean PLOTS(MAXPOINTS=NONE);
    MODEL FatalInjuries = CityDamageFlag_Num 
                          Log_Distance 
                          IntersectionNumber;
    TITLE "Multiple Regression Analysis for Fatal Injuries";
RUN;
QUIT;

/* 9. Cluster Analysis */
PROC FASTCLUS DATA=CrashData_Clean MAXCLUSTERS=3 OUT=ClusterResults;
    VAR Log_Distance CityDamageFlag_Num MinorInjuries ModerateInjuries FatalInjuries;
RUN;

/* Print First 20 Cluster Results */
PROC PRINT DATA=ClusterResults (OBS=20);
    TITLE "Cluster Analysis Results (First 20 Observations)";
RUN;
