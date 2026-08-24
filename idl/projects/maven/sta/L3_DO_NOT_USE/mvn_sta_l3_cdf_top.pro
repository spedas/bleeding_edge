;+
;Top level routine to generate MAVEN STATIC L3 CDF files.
;
;Routine receives a date as input; the corresponding L3 tplot save file is loaded into tplot, and these variables are saved into a CDF file.
;Tplot is cleared upon exit.
;
;This routine does not require SPICE.
;This routine should be quick.
;
;INPUTS:
;date: string: 'yyyy-mm-dd': the day to load.
;
;basedir: string: the base direectory in which to save the output CDF files. Subfolders will include density, temperature, and then year and month within each. Routine will
;                 bail if this is not set.
;
;KEYWORDS:
;Set /den and /temp to specify if you want to create just one or the other. If neither is set on input, both are then set by default by the code.
;
;tmpdir: set as a string, if set file output will go here (this routine will add the folder tree '/density/yr/mn/'). Used  for testing.
;
;testfileload: set as a string, full directory and filename to a STATIC L3 tplot save file, that you want to load, instead of using the
;              default timespan with date option. This should be used for testing only.
;
;OUTPUTS:
;Separate CDF files for density and temperature moments, stored in the base directories provided by basedir (subfolders for den/temp/yr/mn are added automatically).
;
;saved_filenames: set as a variable that will contain the full directory and filenames of CDF files created. Format will be strings.
;
;
;;During testing, CMF and JMT found some bugs in tplot2cdf. Jim McT added fixes but these routines are not yet (as of writing) uploaded to the SVN. Compile
;manually by hand for now, using the below:
;.r /Users/cmfowler/IDL/STATIC_routines/CDFs/Software/tplot2cdf.pro
;.r /Users/cmfowler/IDL/STATIC_routines/CDFs/Software/spd_extract_tvar_metadata.pro
;.r /Users/cmfowler/IDL/STATIC_routines/CDFs/Software/mvn_sta_l3_cdf_top.pro
;-
;

pro mvn_sta_l3_cdf_top, date, den=den, temp=temp, basedir=basedir, success=success, tmpdir=tmpdir, saved_filenames=saved_filenames, $
                          testfileload=testfileload

proname = 'mvn_sta_l3_cdf_top'
success = 0
dataversion='01'  ;#### this are hardcoded for now, and the same for Ni and Ti.

if size(date,/type) ne 7 then begin
  print, ""
  print, proname, ": date must be set as a string in format yyyy-mm-dd'"
  success=0
  return
endif

if size(den,/type) eq 0 and size(temp,/type) eq 0 then begin
  den=1
  temp=1
endif

if size(den,/type) eq 0 then den=0
if size(temp,/type) eq 0 then temp=0

;If tmpdir is specified, save file there, if not, use SSL file directory:
sl = path_sep()  ;/ vs \ for mac vs windows
if keyword_set(tmpdir) then basedir = tmpdir
if not keyword_set(basedir) then basedir = sl+'disks'+sl+'data'+sl+'maven'+sl+'data'+sl+'sci'+sl+'sta'+sl+'l3'+sl   ;'/disks/data/maven/data/sci/sta/l3/' ;we add 'density' or 'temperature' in the loops below

if size(basedir,/type) ne 7 then begin
  print, ""
  print, proname, ": basedir must be set as a string."
  success=0
  return
endif

;Reformat date for file generation later:
yr = strmid(date, 0, 4)
mn = strmid(date, 5, 2)
dd = strmid(date, 8, 2)
date2 = yr+mn+dd  ;yyyymmdd format

;##########
;Load data:
store_data, '*', /delete  ;remove all tplots first

if keyword_set(testfileload) then begin
  tf = file_search(testfileload, count=ntf)
  if ntf eq 0 then begin
    print, ""
    print, proname, ": I couldn't find the testfileload specified."
    success=0
    return
  endif
  tplot_restore, filename=testfileload
  fl2 = file_basename(testfileload) ;get just filenames
  nFL = n_elements(testfileload)
  sta_success=1
endif else begin
  timespan, date, 1.
  mvn_sta_l3_load, den=den, temp=temp, qualc=qualc, filesloaded=fl, success=sta_success
  fl2 = file_basename(fl) ;get just filenames
  nFL = n_elements(fl2)
endelse

;Bail if no L3 tplot files were loaded:
if sta_success eq 0 then begin
  print, ""
  print, proname, ": I couldn't find any L3 tplot files load for this date, ", date
  success=0
  return
endif

;########
;Density:
if den eq 1 then begin
;#######################
;Setup global attributes: requires a L3 file for spiceloaded and parent_files:
get_data, 'mvn_sta_l3_density', limit=ll1
spice_loaded = ll1.spiceloaded
parent_files = ll1.parent_files

global_att_den = {project:'MAVEN', $
              descriptor:'STATIC>Supra-Thermal And Thermal Ion Composition Particle Distribution Moments', $
              source_name:'MAVEN>Mars Atmosphere and Volatile Evolution Mission', $
              discipline:'Planetary Physics>Ionospheric Studies', $
              data_type:'Time series plasma observations', $
              data_version:dataversion, $
              spice_loaded: spice_loaded, $
              parent_files: parent_files, $
              pi_name:'J. McFadden' , $
              pi_affiliation:'Space Sciences Laboratory, UC Berkeley' , $
              text:'For more information see: '+$
                   'McFadden+ (2015), MAVEN suprathermal and thermal ion composition (STATIC) instrument, Space Science Reviews; ' +$
                   'Hanley+ (2021), In situ measurements of thermal ion temperature in the Martian ionosphere, Journal of Geophysical Research: Space Physics; ' + $
                   'Fowler+ (2022), In-situ measurements of ion density in the Martian ionosphere: underlying structure and variability observed by the MAVEN-STATIC instrument, Journal of Geophysical Research: Space Physics.', $       
              instrument_type:'Particles (space)' , $
              mission_group:'MAVEN' , $
              logical_file_id:'MAVEN>Mars Atmosphere and Volatile Evolution Mission/Time series plasma observations/STATIC>Supra-Thermal And Thermal Ion Composition Particle Distribution Moments/'+date+'/'+dataversion,$  ;this format is used by PDS
              logical_source:'na' , $
              logical_source_description:'na' }


  ;Create filename:
  iden = where(strmatch(fl2, 'mvn_sta_l3_den_'+date2+'_v??.tplot') eq 1, niden)  
  if niden gt 1 then stop  ;this should never happen - we only load one day, and only request the science data files. Note - if we include anc and flag files here,
                           ;we will have to edit this catch.
  den_filename = strmid(fl2[iden[0]], 0, 27) + '.cdf'  ;#### format hardcoded here. 
    
  ;Create yr/mn subfolders if needed:
  ;Set up year-month folder directory if not present:
  basedir2a = basedir+'density'+sl
  basedir2b = basedir+'density'+sl+yr+sl+mn+sl ;this is the full save directory
  mvn_sta_makedir, basedir2a, yr, mn, success=success_dir, /group  ;create the yr-mn subfolders if needed
  if success_dir eq 0 then begin
    print, ""
    print, proname, ": I couldn't create the requested folder to store the density CDF file."
    success=0
    return
  endif
  
  full_den_filename = basedir2b+den_filename  ;full cdf file name for density
    ;;;; create a dummy filename to hide from the automated software that copies files to PDS
  den_dummyname = basedir2b+'dummy.cdf'
  
  mvn_sta_l3_cdf_density_v2, den_dummyname, global_att_den, qualc=qualc, success=den_success
  
  ;;; copy the dummy file into the correct filename at the end
  cmd = 'mv ' + den_dummyname + ' ' + full_den_filename
  spawn, cmd, result, err
  if (err ne '') then begin
    print, "Error renaming file: "
    print, "  ", cmd
    print, "  ", err
    return
  endif
  
  success+=den_success
  
  if size(saved_filenames, /type) eq 0 then saved_filenames=full_den_filename else saved_filenames = [saved_filenames, full_den_filename]
endif


;############
;Temperature:
if temp eq 1 then begin
  
;#######################
;Setup global attributes: requires a L3 file for spiceloaded and parent_files:
get_data, 'mvn_sta_l3_temperature_o2+', limit=ll1
spice_loaded = ll1.spiceloaded
parent_files = ll1.parent_files

global_att_temp = {project:'MAVEN', $
  descriptor:'STATIC>Supra-Thermal And Thermal Ion Composition Particle Distribution Moments', $
  source_name:'MAVEN>Mars Atmosphere and Volatile Evolution Mission', $
  discipline:'Planetary Physics>Ionospheric Studies', $
  data_type:'Time series plasma observations', $
  data_version:dataversion, $
  spice_loaded: spice_loaded, $
  parent_files: parent_files, $
  pi_name:'J. McFadden' , $
  pi_affiliation:'Space Sciences Laboratory, UC Berkeley' , $
  text:'For more information see: '+$
  'McFadden+ (2015), MAVEN suprathermal and thermal ion composition (STATIC) instrument, Space Science Reviews; ' +$
'Hanley+ (2021), In situ measurements of thermal ion temperature in the Martian ionosphere, Journal of Geophysical Research: Space Physics; ' + $
'Fowler+ (2022), In-situ measurements of ion density in the Martian ionosphere: underlying structure and variability observed by the MAVEN-STATIC instrument, Journal of Geophysical Research: Space Physics.', $
  instrument_type:'Particles (space)' , $
  mission_group:'MAVEN' , $
  logical_file_id:'MAVEN>Mars Atmosphere and Volatile Evolution Mission/Time series plasma observations/STATIC>Supra-Thermal And Thermal Ion Composition Particle Distribution Moments/'+date+'/'+dataversion,$  ;this format is used by PDS
  logical_source:'na' , $
  logical_source_description:'na' }


  ;Create filename:
  itemp = where(strmatch(fl2, 'mvn_sta_l3_temp_'+date2+'_v??.tplot') eq 1, nitemp)
  if nitemp gt 1 then stop  ;this should never happen - we only load one day, and only request the science data files. Note - if we include anc and flag files here,
  ;we will have to edit this catch.
  temp_filename = strmid(fl2[itemp[0]], 0, 28) + '.cdf'  ;#### format hardcoded here.
  
  ;Create yr/mn subfolders if needed:
  ;Set up year-month folder directory if not present:
  basedir3a = basedir+'temperature'+sl
  basedir3b = basedir+'temperature'+sl+yr+sl+mn+sl ;this is the full save directory
  mvn_sta_makedir, basedir3a, yr, mn, success=success_dir, /group  ;create the yr-mn subfolders if needed
  if success_dir eq 0 then begin
    print, ""
    print, proname, ": I couldn't create the requested folder to store the temperature CDF file."
    success=0
    return
  endif
  
  full_temp_filename = basedir3b+temp_filename  ;full cdf file name for temp
  ;;;; create a dummy filename to hide from the automated software that copies files to PDS
  temp_dummyname = basedir3b+'dummy.cdf'
  
  mvn_sta_l3_cdf_temperature_v2, temp_dummyname, global_att_temp, success=temp_success 
  
  ;;; copy the dummy file into the correct filename at the end
  cmd = 'mv ' + temp_dummyname + ' ' + full_temp_filename
  spawn, cmd, result, err
  if (err ne '') then begin
    print, "Error renaming file: "
    print, "  ", cmd
    print, "  ", err
    return
  endif
  
  success+=temp_success
  
  if size(saved_filenames, /type) eq 0 then saved_filenames=full_temp_filename else saved_filenames = [saved_filenames, full_temp_filename]
endif


;Notes:
;Density file save seems to work on CMF machine. 
;
;Next steps:
;Test density file creation at SSL.
;Create temp creation software (Gwen).
;
;Do we want to include anc and flag files? Discuss with Gwen. Shouldn't be too difficult, but lots of metadata for anc in particular.



end




