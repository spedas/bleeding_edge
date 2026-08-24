;+
;Edited version of mvn_sta_l3_top, originally for use with the radial IMF project. Use mvn_sta_l2_load_no_bkg4.pro to save common block 
;save files of the full STATIC data, without bkg4 subtracted. This routine will then load in these save files, instead of using mvn_sta_l2_load,
;and calculate the densities. The save file version numbers will have 'nobkg4' added to them.
;
;The common block save files must have the name format "CommonBlockFiles_no_bkg4_2021-08-11_ca.sav"; you give this routine the save directory,
;and it will search for common block save files with the input date.
;
;
;Top level routine for STATIC L3 data product processing. This routine will load in STATIC iv3 data for a specified date,
;and produce the team tplot files for density and temperature (and hopefully bulk velocity).
;
;INPUTS:
;
;date: string: 'yyyy-mm-dd'; the date to be processed. 
;
;Specify which L3 data product is to be created:
; /den = density
; /temp = temperature
; /vbulk = bulk  velocity (tbw)
; 
;Setting these keywords will tell the routine which apids to load. Apids need only be loaded once, before each L3 product is 
;calculated.
;
;KEYWORDS:
;trange: double array [a,b]: start and stop times over which to calculate L3 products. Default if not set is the entire day. This may not
;        work currently - check it's been included!
;
;iv_level: string: '0', '1', '2', etc - the level of background processing in STATIC L0 files. Default if not set is currently '3'.
;
;tmpdir: string: temp directory in which to save the output tplot files. Used for testing. The default if not set are the L3 folders:
;                '/disks/data/maven/data/sci/sta/l3/'. Subfolders for year/month are created automatically by mvn_sta_makedir.pro.
;
;Set /indspice to load SPICE for this particular date. Do not set when running as part of a loop, where you can run SPICE once at the very
;   start over the full date range, rather than doing it on each individual date.
;
;Set /skipload to skip loading L2 data. Used for testing only.
;
;version: string: two element number for version number, eg version='01', '02', etc. Default of '01' is used if not set.
;
;ADDED:
;cbdir: string: directory to the common blocl directory where nobkg4 files are loaded from.
;
;.r /Users/cmfowler/IDL/STATIC_routines/Processing_software/L3/mvn_sta_l3_top_nobkg4.pro
;-
;

pro mvn_sta_l3_top_nobkg4, date, trange=trange, den=den, temp=temp, vbulk=vbulk, iv_level=iv_level, success=success, tmpdir=tmpdir, indspice=indspice, $
                    skipload=skipload, version=version, cbdir=cbdir

proname = 'mvn_sta_l3_top_nobkg4'

if size(version,/type) eq 0 then version='01nobkg4'  ;default version number
vSTR = version

if size(date,/type) ne 7 then begin
    print, proname, ": Date must be set as a string, 'yyyy-mm-dd'."
    success=0
    return
endif

if not keyword_set(iv_level) then iv_level='4'

;If tmpdir is specified, save file there, if not, use SSL file directory:
if not keyword_set(tmpdir) then basedir = '/disks/data/maven/data/sci/sta/l3/' else basedir=tmpdir 


;Load STATIC data: first determine which apids are required:
if keyword_set(den) then dflag=1 else dflag=0
if keyword_set(temp) then tflag=2 else tflag=0
if keyword_set(vbulk) then vflag=4 else vflag=0

ftot = dflag+tflag+vflag
;Possible combinations of ftot are: d (1), t (2), v (4), d+t (3), d+v (5), t+v (6), d+t+v (7)
case ftot of
    1 : sta_apids = ['c6', 'c0', 'c8', 'ca', 'd8', 'd9', 'da', 'db', 'd0', 'd1']  ;d
    2 : sta_apids = ['c6', 'c0', 'c8', 'ca', 'd8', 'd9', 'da', 'db', 'd0', 'd1', 'd6', '2a']  ;t
    3 : sta_apids = ['c6', 'c0', 'c8', 'ca', 'd8', 'd9', 'da', 'db', 'd0', 'd1', 'd6', '2a']  ;d+t
    4 : sta_apids = ['']  ;v
    5 : sta_apids = ['']  ;d+v
    6 : sta_apids = ['']  ;t+v
    7 : sta_apids = ['']  ;d+t+v
    else : begin
              success=0
              return
           end
endcase

if sta_apids[0] eq '' then begin
    print, proname, ": I wasn't sure which STATIC apids to load. Please set dflag, tflag and vflag as needed."
    success=0
    return
endif

timespan, date, 1.
if keyword_set(indspice) then kk=mvn_spice_kernels(/load)  

if not keyword_set(skipload) then begin
  ;This is the original load code:
  ;mvn_sta_l2_load, sta_apid=sta_apids, iv_level=iv_level
  ;mvn_sta_l2_tplot, /test,/all,/replace
  
  ;Instead, load common block files:
  files = file_search(cbdir+'CommonBlockFiles_no_bkg4_'+date+'_??.sav', count=nfiles)
  if nfiles ne 9 then begin
    print, ""
    print, proname, ": I need 9 common block files and I found ", nfiles, " for this date."
    print, "Make sure these files exist and cbdir is set correctly."
    return
  endif
  
  print, ""
  print, proname, ": Restoring common block files..."
  for ff = 0l, nfiles-1l do restore, filename=files[ff]
  
  common mvn_c0,mvn_c0_ind,mvn_c0_dat
  common mvn_c6,mvn_c6_ind,mvn_c6_dat
  common mvn_c8,mvn_c8_ind,mvn_c8_dat
  common mvn_ca,mvn_ca_ind,mvn_ca_dat
  common mvn_d0,mvn_d0_ind,mvn_d0_dat
  common mvn_d1,mvn_d1_ind,mvn_d1_dat
  common mvn_d9,mvn_d9_ind,mvn_d9_dat
  common mvn_d8,mvn_d8_ind,mvn_d8_dat
  common mvn_db,mvn_db_ind,mvn_db_dat
  
  mvn_sta_l2_tplot
  mvn_lpw_l0_tplot_restore
  mac_lpw_load_pot_c6 ;correctons to sc pot due to LPW sweeps
endif

;;;; added by kgh
common mvn_sta_kk3_anode, kk3_anode
kk3_anode=1
;;;; 

;mvn_scpot  ;add all scpot values to STATIC structre.  -> ***** how to deal with new SWEA sweeps with no low energy?

;;;; added by kgh
mvn_sta_tplot_scpot 
maven_orbit_tplot, /loadonly  ;this is required by mvn_sta_l3_ramdir
mvn_sta_l3_ramdir
mvn_attitude_bar  ;use to determine sc pointing at periapsis
;;;;


;Derive L3 products:
if keyword_set(den) then begin
    if not keyword_set(tmpdir) then savedir1 = basedir+'density/' else savedir1 = basedir  ;add on /density/ for default use
    mvn_sta_l3_den, trange=trange, qualc=qualc, success=density_success, savedir=savedir1, vSTR=vSTR
endif


if keyword_set(temp) then begin
    if not keyword_set(tmpdir) then savedir2 = basedir+'temperature/' else savedir2 = basedir  ;add on /temperature/ for default use
    mvn_sta_l3_temp, trange=trange, success=temperature_success, savedir=savedir2; vSTR=vSTR ?
endif


if keyword_set(vbulk) then begin  
    ;This code tbw - a top level wrapper is needed to wrapp all of the below up. 
    ;Calculate flow vectors for the 5 primary ion species as well:
    ;mvn_sta_flow, trange=trange, spicekernels=spicekernels, /kms, success=success_flow, sta_apid='d1', /sc_vel, species='H'
    ;mvn_sta_flow, trange=trange, spicekernels=spicekernels, /kms, success=success_flow, sta_apid='d1', /sc_vel, species='He'
    ;mvn_sta_flow, trange=trange, spicekernels=spicekernels, /kms, success=success_flow, sta_apid='d1', /sc_vel, species='O'
    ;mvn_sta_flow, trange=trange, spicekernels=spicekernels, /kms, success=success_flow, sta_apid='d1', /sc_vel, species='O2+'
    ;mvn_sta_flow, trange=trange, spicekernels=spicekernels, /kms, success=success_flow, sta_apid='d1', /sc_vel, species='CO2+'

  
  
endif

mvn_lpw_anc_clear_spice_kernels  ;clear SPICE at the end 

success=1  ;do we want more detailed flags for each L3 requested - eg success for den, temp and vbulk?

end

