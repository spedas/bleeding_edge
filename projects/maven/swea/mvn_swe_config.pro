;+
;PROCEDURE:   mvn_swe_config
;PURPOSE:
;  Maintains SWEA configuration changes in a common block (mvn_swe_com).
;  Sweep table updates are handled by checksums (see mvn_swe_sweep) - times
;  are recorded here as documentation.
;
;  Mission phases are as follows:
;
;    Event       Time (UTC)             Mission Phase
;    -----------------------------------------------------------------------
;    Launch      2013-11-18/18:28  - 
;                                   |-> Cruise
;    MOI         2014-09-22/01:50  -
;                                   |-> Transition (Commissioning)
;    Sci Ops     2014-11-15/00:00  -
;                                   |-> Primary Mission    (PDS R1 - R4)
;    Ext Ops 1   2015-11-15/00:00  -
;                                   |-> Extended Mission 1 (PDS R5 - R7.5)
;    Ext Ops 2   2016-10-01/00:00  - 
;                                   |-> Extended Mission 2 (PDS R7.5 - R16)
;    Ext Ops 3   2018-10-01/00:00  -
;                                   |-> Extended Mission 3 (PDS R17 - R20)
;    Ext Ops 4   2019-10-01/00:00  - 
;    -----------------------------------------------------------------------
;
;USAGE:
;  mvn_swe_config
;
;INPUTS:
;
;KEYWORDS:
;
;    LIST:          List all configuration changes.
;
;    TIMEBAR:       Overplot vertical dotted lines at the times of configuration
;                   changes in a tplot window (assumed to exist).
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2018-07-31 10:55:30 -0700 (Tue, 31 Jul 2018) $
; $LastChangedRevision: 25530 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_config.pro $
;
;CREATED BY:    David L. Mitchell  03-29-13
;FILE: mvn_swe_config.pro
;-
pro mvn_swe_config, list=list, timebar=timebar

  @mvn_swe_com

; Sweep table update.  Replace tables 1 and 2 with tables 3 and 4, respectively.
; Tables 3 and 4 are used for all cruise data from March 19 to the MOI moratorium.
; See mvn_swe_sweep for definitions of all sweep tables.

  t_swp = time_double('2014-03-19/14:00:00')  ; sweep tables 3 and 4 upload

; Stowed MAG1-to-SWE rotation matrix.  SWEA was launched with a MAG1-to-SWEA rotation
; matrix for a deployed boom.  This matrix is used by FSW to create optimal cuts 
; through the 3D distributions to create PADs.  This update loads the rotation matrix
; for a stowed boom (135-deg rotation about the spacecraft Y axis).
;
; Because of an undetected error in the MICD, this matrix and the previous one are 
; incorrect by a 90-degree rotation in SWEA azimuth.

  t_mtx = time_double('2014-04-02/14:26:02')  ; stowed boom matrix upload #1

; Deflection scale factor update.  This introduced an error (DSF's too small), but 
; at least deflection bins 0 and 1 were set to zero.

  t_dsf = time_double('2014-04-23/17:21:30')  ; deflection scale factor update #1

; Deflection scale factor update.  This corrected the mistake from the previous
; update.  Now DSF's are 0, 0, 1, 1, 1, 1 -- as desired.

  t_dsf = [t_dsf, time_double('2014-04-30/18:06:21')]  ; deflection scale factor update #2

; Stowed MAG1-to-SWE rotation matrix update.  This compensates for error in the MICD.
; From this time until the MOI moratorium, the MAG1-to-SWE rotation matrix is correct.

  t_mtx = [t_mtx, time_double('2014-06-30/17:09:19')]  ; stowed boom matrix upload #2

; Sweep table update.  Replace tables 3 and 4 with tables 5 and 6, respectively.
; Tables 5 and 6 are used for all data from transition onward.

  t_swp = [t_swp, time_double('2014-10-06/12:00:00')]  ; sweep table 5 and 6 upload

; Deployed MAG1-to-SWE rotation matrix, with corrected MICD.
;   Deployed boom matrix was uploaded as part of EEPROM load executed on 2014-09-22
;   Boom separation nut pyro was fired at 2014-10-10/15:08:14.684
;   Boom shows evidence for motion a few seconds later
;   Boom fully deployed by about 2014-10-10/15:09:30

  t_mtx = [t_mtx, time_double('2014-10-10/15:08:40')]  ; deployed boom matrix upload

; MCP bias adjustment times.  These are used by mvn_swe_crosscal.

; 2013-11-18/18:28                                     ; MAVEN launch (bias = 2500 V)
  t_mcp = time_double('2014-03-22/00:00:00')           ; first cross calibration measurement

; 2014-09-22/01:50                                     ; MAVEN orbit insertion
  t_sup = time_double('2014-10-14/00:00:00')           ; first suppression calibration
  t_mcp = [t_mcp, time_double('2014-10-17/02:26:41')]  ; bias adjustment (2500 -> 2600 V)
  t_mcp = [t_mcp, time_double('2014-11-12/00:00:00')]  ; bias = 2600 V (beginning of poly fit)

; 2014-11-15/00:00                                     ; beginning of science phase

; 2015-11-15/00:00                                     ; beginning of EM-1
  t_mcp = [t_mcp, time_double('2015-12-18/23:39:09')]  ; bias adjustment (2600 -> 2700 V)
  t_mcp = [t_mcp, time_double('2015-12-22/20:01:45')]  ; revert to 2600 V after HV reset
  t_mcp = [t_mcp, time_double('2015-12-30/02:28:57')]  ; back to correct bias (2700 V)
  t_sup = [t_sup, time_double('2017-04-02/00:00:00')]  ; last suppression calibration

; SWEA data dropouts resulting from PFDPU processing error
;
;  2016-01-28/03:33:52 - 2016-02-02/17:13:42
;  2016-02-26/14:03:58 - 2016-03-16/03:30:10

; 2016-10-01/00:00                                     ; beginning of EM-2
  t_mcp = [t_mcp, time_double('2016-10-25/21:52:45')]  ; bias adjustment (2700 -> 2750 V)
  t_mcp = [t_mcp, time_double('2017-08-12/07:24:27')]  ; bias adjustment (2750 -> 2800 V)

  t_mcp = [t_mcp, time_double('2018-07-28/00:00:00')]  ; last SWE-SWI cross calibration

; Gather all the configuration change times into one variable (for timebar).

  t_cfg = [t_swp, t_mtx, t_dsf, t_mcp, t_sup]

; List configuration changes

  if keyword_set(list) then begin
    print,time_string(t_swp[0]),' --> sweep tables 3 and 4 upload'
    print,time_string(t_mtx[0]),' --> stowed boom matrix upload #1 (error in MICD)'
    print,time_string(t_dsf[0]),' --> deflection scale factor update #1 (with error)'
    print,time_string(t_dsf[1]),' --> deflection scale factor update #2 (correct)'
    print,time_string(t_mtx[1]),' --> stowed boom matrix upload #2 (correct MICD)'
    print,time_string(t_swp[1]),' --> sweep tables 5 and 6 upload'
    print,time_string(t_mtx[2]),' --> boom deploy'
    print,time_string(t_mcp[1]),' --> MCP bias adjustment (2500 -> 2600 V)'
    print,time_string(t_mcp[3]),' --> MCP bias adjustment (2600 -> 2700 V)'
    print,time_string(t_mcp[4]),' --> MCP bias revert to 2600 V (unintentional)'
    print,time_string(t_mcp[5]),' --> MCP bias restore to 2700 V'
    print,time_string(t_mcp[6]),' --> MCP bias adjustment (2700 -> 2750 V)'
    print,time_string(t_mcp[7]),' --> MCP bias adjustment (2750 -> 2800 V)'
  endif

; Overplot dotted time bars on the current tplot window (assumed to exist)

  if keyword_set(timebar) then timebar, t_cfg, line=1

  return

end
