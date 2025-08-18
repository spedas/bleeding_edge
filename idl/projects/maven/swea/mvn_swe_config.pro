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
;    MOI         2014-09-22/02:24  -
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
;                                   |-> Extended Mission 4 (PDS R21 - R32)
;    Ext Ops 5   2022-10-01/00:00  -
;                                   |-> Extended Mission 5 (PDS R33 - R44)
;    Ext Ops 6   2025-10-01/00:00  -
;                                   |-> Extended Mission 6 (PDS R45 - R56)
;    Ext Ops 7   2028-10-01/00:00  -
;                                   |-> Extended Mission 7 (PDS R57 - R68)
;    Ext Ops 8   2031-10-01/00:00  -
;    -----------------------------------------------------------------------
;
;USAGE:
;  mvn_swe_config
;
;INPUTS:
;
;KEYWORDS:
;
;    LIST:          List configuration changes.  Set this keyword to one of
;                   the following to list changes of a particular type:
;
;                     'swp' : sweep table
;                     'mtx' : MAG-to-SWE rotation matrix
;                     'dsf' : deflection scale factors
;                     'mcp' : MCP bias voltage (or SWE-SWI cross calibration)
;                     'sup' : electron suppression
;
;                   Otherwise, all changes are listed.
;
;    TIMEBAR:       Returns a structure with three tags:
;
;                     time : array of times for configuration changes
;                     text : brief descriptions of configuration changes
;                     type : types of configuration changes (see above)
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2025-05-23 15:45:39 -0700 (Fri, 23 May 2025) $
; $LastChangedRevision: 33326 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_config.pro $
;
;CREATED BY:    David L. Mitchell  03-29-13
;FILE: mvn_swe_config.pro
;-
pro mvn_swe_config, list=list, timebar=tbar

  @mvn_swe_com

; ----- LAUNCH: 2013-11-18/18:28  (MCP bias = 2500 V) -----

; ----- CRUISE -----

; Sweep table update.  Replace tables 1 and 2 with tables 3 and 4, respectively.
; Tables 3 and 4 are used for all cruise data from March 19 to the MOI moratorium.
; See mvn_swe_sweep for definitions of all sweep tables.

; ----- CRUISE DATA BEGIN: 2014-03-19 -----

  t_swp = time_double('2014-03-19/14:00:00')
  m_swp = 'sweep tables 3 and 4 upload'

  t_mcp = time_double('2014-03-22/00:00:00')
  m_mcp = 'MCP bias = 2500 V ; first SWE-SWI cross calibration'

; Stowed MAG1-to-SWE rotation matrix.  SWEA was launched with a MAG1-to-SWEA rotation
; matrix for a deployed boom.  This matrix is used by FSW to create optimal cuts 
; through the 3D distributions to create PADs.  This update loads the rotation matrix
; for a stowed boom (135-deg rotation about the spacecraft Y axis).
;
; Because of an undetected error in the MICD, this matrix and the previous one are 
; incorrect by a 90-degree rotation in SWEA azimuth.

  t_mtx = time_double('2014-04-02/14:26:02')
  m_mtx = 'stowed boom matrix upload #1 (error in MICD)'

; Deflection scale factor update.  This introduced an error (DSF's too small), but 
; at least deflection bins 0 and 1 were set to zero.

  t_dsf = time_double('2014-04-23/17:21:30')
  m_dsf = 'deflection scale factor update #1 (with error)'

; Deflection scale factor update.  This corrected the mistake from the previous
; update.  Now DSF's are 0, 0, 1, 1, 1, 1 -- as desired.

  t_dsf = [t_dsf, time_double('2014-04-30/18:06:21')]
  m_dsf = [m_dsf, 'deflection scale factor update #2 (correct)']

; Stowed MAG1-to-SWE rotation matrix update.  This compensates for error in the MICD.
; The error was confirmed by examining photos of the instrument before encapsulation.
; From this time until the MOI moratorium, the MAG1-to-SWE rotation matrix is correct.

  t_mtx = [t_mtx, time_double('2014-06-30/17:09:19')]
  m_mtx = [m_mtx, 'stowed boom matrix upload #2 (correct MICD)']

; ----- CRUISE DATA END: 2014-07-16 -----

; ----- MOI MORATORIUM -----

; ----- MARS ORBIT INSERTION: 2014-09-22/02:24 (end of burn) -----

; EEPROM load executed on 2014-09-22.  For SWEA this included:
;   - sweep tables 5 and 6 (used for all data from transition onward)
;   - deployed boom rotation matrix (with correct MICD)
;   - science deflection scale factors: cos(swe_el) = [0.63, 0.86, 0.99, 0.98, 0.85, 0.60]

  t_swp = [t_swp, time_double('2014-09-22')]
  m_swp = [m_swp, 'sweep tables 5 and 6 upload']

; First SWEA turn-on in orbit
;   - Power on:         2014-10-06/22:58:28
;   - MCP ramp begins:  2014-10-06/23:13:22
;   - MCP ramp ends:    2014-10-07/00:00:30 (2500 V)
;   - Sweep enabled:    2014-10-07/00:10:26 (first science data, center time)

  t_dsf = [t_dsf, time_double('2014-10-06/22:58:28')]
  m_dsf = [m_dsf, 'deflection scale factor update #3 (cosine elevation)']

; SWEA Boom Deploy
;   Boom separation nut pyro was fired at 2014-10-10/15:08:14.684
;     - Spacecraft begins counter rotation to conserve angular momentum (theta = 73.56 deg)
;   SWEA data show evidence for boom motion within a few seconds
;   Boom fully deployed by about 2014-10-10/15:09:30
;     - Spacecraft counter rotation stops at 2014-10-10/15:10:00 (theta = 82.64 deg)

  t_mtx = [t_mtx, time_double('2014-10-10/15:08:40')]
  m_mtx = [m_mtx, 'boom deploy (with new MAG-to-SWE matrix)']

  t_sup = time_double('2014-10-14/00:00:00')
  m_sup = 'first suppression calibration'

  t_mcp = [t_mcp, time_double('2014-10-17/02:26:41')]
  m_mcp = [m_mcp, 'MCP bias adjustment (2500 -> 2600 V)']

; Comet Siding Spring encounter with Mars: 2014-10-19
;  - ESA HV off (hunker down): 2014-10-19/16:41:36
;  - ESA HV on               : 2014-10-19/22:04:00
;  - SWEA science data resume: 2014-10-19/23:01:40

  t_mcp = [t_mcp, time_double('2014-11-12/00:00:00')]
  m_mcp = [m_mcp, 'MCP bias = 2600 V (beginning of poly fit)']

; ----- SCIENCE PHASE BEGINS (2014-11-15) -----

; 2014-11-15/00:00                                     ; beginning of Primary Mission

  t_mcp = [t_mcp, time_double('2015-12-18/23:39:09')]
  m_mcp = [m_mcp, 'MCP bias adjustment (2600 -> 2700 V)']

  t_mcp = [t_mcp, time_double('2015-12-22/20:01:45')]
  m_mcp = [m_mcp, 'MCP bias reverts to 2600 V after HV reset']

  t_mcp = [t_mcp, time_double('2015-12-30/02:28:57')]
  m_mcp = [m_mcp, 'MCP bias back to correct value (2700 V)']

; 2015-11-15/00:00                                     ; beginning of EM-1

; SWEA data dropouts resulting from PFDPU processing error
;
;  2016-01-28/03:33:52 - 2016-02-02/17:13:42           ; first occurrence
;  2016-02-26/14:03:58 - 2016-03-16/03:30:10           ; 1-bit patch applied on data restart
;  2018-09-23/22:10:06 - 2018-10-05/19:10:37           ; following EEPROM load missing patch
                                                       ; (patch reapplied on data restart)

; 2016-10-01/00:00                                     ; beginning of EM-2

  t_mcp = [t_mcp, time_double('2016-10-25/21:52:45')]
  m_mcp = [m_mcp, 'MCP bias adjustment (2700 -> 2750 V)']

  t_sup = [t_sup, time_double('2017-04-02/00:00:00')]
  m_sup = [m_sup, 'last suppression calibration']

  t_mcp = [t_mcp, time_double('2017-08-12/07:24:27')]
  m_mcp = [m_mcp, 'MCP bias adjustment (2750 -> 2800 V)']

; EEPROM load on 2018-08-28 (apo 7621)

  t_swp = [t_swp, time_double('2018-08-28/14:02:38')]
  m_swp = [m_swp, 'sweep table 8 upload (32-Hz,  50 eV)']

; 2018-10-01/00:00                                     ; beginning of EM-3

  t_swp = [t_swp, time_double('2018-11-09/17:57:56')]
  m_swp = [m_swp, 'sweep table 7 upload (32-Hz, 200 eV)']

  t_mcp = [t_mcp, time_double('2018-11-13/11:18:13')]
  m_mcp = [m_mcp, 'MCP bias adjustment (2800 -> 2875 V)']

; 2019-10-01/00:00                                     ; beginning of EM-4

  t_swp = [t_swp, time_double('2022-04-22/00:00:00')]
  m_swp = [m_swp, 'sweep table 9 upload (32-Hz, 125 eV)']

; 2022-10-01/00:00                                     ; beginning of EM-5

  t_mcp = [t_mcp, time_double('2023-09-21/18:50:41')]
  m_mcp = [m_mcp, 'MCP bias adjustment (2875 -> 2925 V)']

  t_mcp = [t_mcp, time_double('2025-01-20/00:00:00')]
  m_mcp = [m_mcp, 'last SWE-SWI cross calibration']

; 2025-10-01/00:00                                     ; beginning of EM-6

; Gather configuration changes into one variable.

  t_cfg = [t_swp, t_mtx, t_dsf, t_mcp, t_sup]
  m_cfg = [m_swp, m_mtx, m_dsf, m_mcp, m_sup]
  type = [replicate('swp',n_elements(t_swp)) , $
          replicate('mtx',n_elements(t_mtx)) , $
          replicate('dsf',n_elements(t_dsf)) , $
          replicate('mcp',n_elements(t_mcp)) , $
          replicate('sup',n_elements(t_sup))    ]

  i = sort(t_cfg)
  n = n_elements(i)
  tbar = replicate({time: 0D, text: '', type: ''}, n)
  tbar.time = t_cfg[i]
  tbar.text = m_cfg[i]
  tbar.type = type[i]

; List configuration changes

  if keyword_set(list) then begin
    i = indgen(n)
    if (size(list,/type) eq 7) then begin
      list = strlowcase(list[0])
      i = where(tbar.type eq list, n)
      if (n eq 0) then begin
        print,'  unrecognized configuration type: ',list
        print,'  valid types: swp, mtx, dsf, mcp, sup'
      endif
    endif
    for j=0,(n-1) do print, time_string(tbar[i[j]].time),' --> ',tbar[i[j]].text
  endif

  return

end
