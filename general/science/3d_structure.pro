;+
;NAME:
;   3d_structure
;PURPOSE: 
;   Documentation for the 3d structure.
;   This is NOT a procedure or a function. It is ONLY Documentation. don't
;   try to run it!
;   The 3d structure is the standard structure that contains all information
;   necessary to do data analysis on a particle distribution function.
;   The following is an example structure obtained from the WIND data set:
;
;** Structure <1b689b0>, 29 tags, length=35304, refs=1:
;   PROJECT_NAME    STRING    'Wind 3D Plasma'
;   DATA_NAME       STRING    'Eesa Low'
;   UNITS_NAME      STRING    'Counts'           Current Units.
;   TIME            DOUBLE       8.2313292e+08   Sample start. Secs since 1970
;   END_TIME        DOUBLE       8.2313292e+08   Sample End. Secs since 1970.
;   INTEG_T         DOUBLE           3.0000000   Integration Time.  Seconds.
;   NBINS           INT             88           number of angle bins.
;   NENERGY         INT             15           number of energy bins.
;   MAP             INT       Array(32, 32)      bin map (req'd only for plot3d_new)
;   DATA            FLOAT     Array(15, 88)
;   ENERGY          FLOAT     Array(15, 88)
;   THETA           FLOAT     Array(15, 88)
;   PHI             FLOAT     Array(15, 88)
;   GEOM            FLOAT     Array(15, 88)      Req'd by convert_esa_units
;   DENERGY         FLOAT     Array(15, 88)
;   DTHETA          FLOAT     Array(15, 88)
;   DPHI            FLOAT     Array(15, 88)
;   DOMEGA          FLOAT     Array(15, 88)
;   EFF             FLOAT     Array(15, 88)      Req'd by convert_esa_units
;   FEFF            FLOAT     Array(15, 88)      Req'd by convert_esa_units 
;   MASS            DOUBLE       5.6856593e-06
;   GEOMFACTOR      DOUBLE       0.00039375000   Req'd by convert_esa_units
;   VALID           LONG                 1
;   SPIN            LONG             17152       (Optional)
;   UNITS_PROCEDURE STRING    'convert_esa_units'
;   MAGF            FLOAT     Array(3)           (Optional magnetic field vec.)
;   VSW             FLOAT     Array(3)           (Optional flow velocity vec.)
;
;
;The following functions will return a 3d structure:
;
;  For the WIND data set:            ("LOAD_3DP_DATA" must be called first.)
;    "GET_EL", "GET_PL","GET_EH","GET_PH","GET_PLB","GET_PHB","GET_ELB",
;    "GET_EHS","GET_SF","GET_SO","GET_SFB","GET_SOB"
;
;  For the GIOTTO data set:
;    "GET_GI"
;
;  For the CLUSTER data set:
;    In Progress....
;
;  For the FAST data set:
;    In Progress....
;
;Once the 3d structure is obtained then it can be displayed with the following
;routines:
;    "SPEC3D", "PLOT3D", "CONT3D"
;
;The following routines are useful for manipulating the data:
;    "CONV_UNITS", "CONVERT_VFRAME", "PAD"
;
;-


