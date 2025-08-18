;+
;Routine to load STATIC L3 moments into IDL tplot: density, temperature, and eventually flow and winds.
;
;KEYWORDS:
;Set /den to load STATIC densities for the five major species: H+, m/q=2 (typically He++ in the solar wind), O+, O2+, CO2+.
;Set /temp to load STATIC O2+ temperatures.
;
; - Setting no keywords will by default load all moment types.
;
;Set /append to append the output tplot variables to IDL tplot memory. This means that if the loaded tplot variables already exist,
;     they will be appended to, rather than being overwritten. By default, when this keyword is not set, any tplot variables with the same
;     names that already exist are overwritten.
;
;success: set to a named variable to return: 0: unsuccessful - no data loaded.
;                                            1: successful - data (probably) loaded.
;                                            The routine is not clever enough to provide more details - 0 means it could not find any
;                                            files to load, 1 means it found some (could be density or temperature) files and loaded them.
;
;Set /margin to extend the left hand side margin so that tplot panel titles show properly. The default settings in tplot mean that 
;these don't always fit. These are changed to tplot_options, 'xmargin', [16,8].
;
;Set /anc to load ancillary data files that include more detailed information from the density and temperature calculations. These are
;typically used for calibration and checks by the instrument team, and should not be needed for most users. It is recommended that you 
;contact the instrument team if you wish to use any parameters loaded using this keyword.
;
;Set /flag to load a second set of ancillary data files that contain additional flag information, that was used to create the final flag variable
;     mvn_sta_l3_density_quality_flag.
;
;Set coltab as a float/integer to the desired color table, so that tplot variable labels can be colored correctly. If not set, the default
;     value of 43 is used, via loadct2, 43. Note: in the latest version this keyword no longer works.
;
;Set /qualc if you are using Mike Chaffins qualcolors colortable software. This supercedes the coltab keyword. If qualc is not set, 
;     then the keyword coltab is used instead, which defaults to 43 if not set. Note: this routine used to run loadct2, if qualc was not set. This
;     no longer happens: the user must run loadct2 before running this routine, if they want to set a specific colortable. If this routine cannot find
;     an structure of array colors to use (which is obtained through either loadct2 or qualcolors), then it will use placeholder values, to avoid a crash.
;     NOTE: If you use the qualcolors software, you may get a red background when loading the data if you don't use the /qualc keyword. 
;           To fix this, run the following:
;               @'qualcolors'
;               !p.background = qualcolors.white
;               !p.color = qualcolors.black 
; 
;If you set /leavecolors, the routine will not set any colors and will ignore the coltab and qualc keywords. Use this if you do not 
;     want this routine loading a new colortable. You can fix the tplot colors outside of this routine using 
;         options, 'tplotname', colors=[1,2,3,4,5]
;
;Set filesloaded to a variable that will contain the filenames of the tplot files loaded. This output will be in string format. Files are appended in the order loaded,
;     so science, ancillary and flag filenames, if /anc and /flag are set. 
;
;
;OUTPUTS: 
;The following IDL tplot variables:
;DENSITY:
;mvn_sta_l3_density : densities in cm^-3, for H+, m/q=2 (usually He++ in the solar wind, sometimes H2+ in the ionosphere), O+, O2+, CO2+.
;
;mvn_sta_l3_density_abs_uncertainty - absolute statistical uncertainty in densities (cm^-3). Note, this is the statisical uncertainty
;                                     associated with the number of counts observed. There can be other sources of uncertainty, for example
;                                     from blockage caused by the spacecraft or gaps in STATICs field of view. These are not accounted for 
;                                     (and are difficult to do so in an automated fashion).                                   
;
;mvn_sta_l3_density_perc_uncertainty - statistical uncertainty in densities as a percentage of the total density for that species.
;
;mvn_sta_l3_density_quality_flag - quality flag assigned to each data point and ion species:
;                               0 = ok
;                               1 = use caution (recommend not using)
;                               Quality flag takes into account the statistical significance of the observed count rates, changes in
;                               attenuator states, whether STATIC is pointed optimally. 
;                               
;mvn_sta_l3_density_light_method & 
;mvn_sta_l3_density_heavy_method - methods used to determine light and heavy ion densities. 
;                                  0 = moment; 1, 2, or 3 = beam for O+, O2+, CO2+ respectively (different values used for viewing purposes).      
;    
;mvn_sta_c6_att_mode -   indicates which mode & attenuator state STATIC is in  (see STATIC readme)                                            
;                               
;mvn_sta_l3_density_mvn_pos_mso - MAVENs position in the MSO coordinate system, in units of km, generated using SPICE.
;
;mvn_sta_l3_density_mvn_sza - MAVENs solar zenith angle in the MSO coordinate system, in degrees, generated using SPICE.
;
;mvn_sta_l3_density_mvn_alt_iau - MAVENs altitude in the IAU coordinate system (ie Mars is an oblate spheroid), in units of km, generated using SPICE.
;
;
;
;TEMPERATURE:
;
;mvn_sta_l3_temperature_o2+: O2+ temperature, mostly at c6 time cadence (4s) in eV
;
;mvn_sta_l3_temperature_abs_uncertainty: absolute statistical uncertainty in temperature (eV). Note, this is the statisical uncertainty
;                                     associated with the number of counts observed. There can be other sources of uncertainty, for example
;                                     from blockage caused by the spacecraft or gaps in STATICs field of view. These are not accounted for
;                                     (and are difficult to do so in an automated fashion).;
;                      
;mvn_sta_l3_temperature_quality_flag - quality flag assigned to each data point and ion species:
;                               0 = ok
;                               1 = use caution (recommend not using)
;                               Quality flag takes into account the availability of corrections to s/c potential based on LPW data, 
;                               and the ratio of the temperature corrections to the temperature (T_AC/T_ion, see temperature paper for 
;                               definition of T_AC) 
;                               
;mvn_sta_l3_temperature_product - indicates which STATIC data product was used to calculate O2+ temperature.
;                               0 = c6 energy beamwidth (default) 
;                               1 = c8 angular beamwidth 
;                               
;mvn_sta_l3_sta_att_mode - indicates which mode & attenuator state STATIC is in  (see STATIC readme; same as mvn_sta_c6_att_mode)                 
;
;mvn_sta_l3_temperature_mvn_pos_mso - MAVEN's position in the MSO coordinate system, in units of km, generated using SPICE.
;
;mvn_sta_l3_temperature_mvn_pos_geo - MAVEN's position in the planetocentric coordinate system, in units of km, generated using SPICE.
;
;mvn_sta_l3_temperature_mvn_sza - MAVEN's solar zenith angle in the MSO coordinate system, in degrees, generated using SPICE.
;
;mvn_sta_l3_temperature_mvn_alt_iau - MAVEN's altitude in the IAU coordinate system (ie Mars is an oblate spheroid), in units of km, generated using SPICE.
;
;mvn_sta_l3_temperature_mvn_lst - MAVEN's local solar time, in hours. 
;
;
;
;BULK FLOW VELOCITY:
;TBD
;
;
;
;EXAMPLES:
;timespan, '2019-04-03', 1.  ;set timespan
;mvn_sta_l3_load  ;load all STATIC moments into tplot.
;------
;timespan,'2019-04-03',1
;mvn_sta_l3_load, /den, /margin, /qualcolors ; load density moments using Mike Chaffin's qualitative 
;                                              colorbar package & fix the xmargin of the tplot window
;                                              so that all the titles are displayed 
;
;NOTES:
;If you discover any features in the code (i.e. bugs), please contact the STATIC instrument team:
;Gwen Hanley, gwen.hanley@berkeley.edu (temperatures in particular)
;Chris Fowler, christopher.fowler@mail.wvu.edu (densities in particular)
;Jim McFadden, mcfadden@ssl.berkeley.edu (STATIC instrument PI)
;
;
;EDITS:
;2021-08-18: CMF: edited code so science files are always downloaded, and anc files are only downloaded if requested. 
;2021-10-11: KGH: edited to fix naming conventions, temperature tplot colors and updated variable descriptions
;2021-10-12: CMF + KGH disabled anc keyword as still sorting through last bugs. Will reactive when ready - hopefully a few weeks.
;2021-11:11: KGH added workaround to fix problem with anc keyword -- recreate 'problem' tplot variables at the end of this code rather than storing them in the anc files. 
;2022-06-27: CMF: added filesloaded keyword to output list of filenames loaded.
;2024-02-28: CMF: removed the default behavior to use loadct2 command. The user must run this themselves beforehand now. The keyword coltab now no longer works as a result.
;-
;


pro mvn_sta_l3_load, den=den, temp=temp, success=success, append=append, margin=margin, anc=anc, flag=flag, coltab=coltab, qualc=qualc, $
                        leavecolors=leavecolors, filesloaded=filesloaded

proname = 'mvn_sta_l3_load'
sl = path_sep()
success = 0  ;default if routine bails

;2021-10-12: CMF and KGH: anc keyword needs a bit of debugging when loading multiple files using tplot-restore append function.
;Disable for now, and reactive when fixed
;2022-06-27 - this bug has been fixed (?) so reactivate anc keyword..?
;if keyword_set(anc) then begin
;  print, ""
;  print, proname, ": the anc keyword is currently disabled as we're sorting out final bugs."
;  print, "This should become active in a few weeks."
;  print, ""
;  anc=1
;endif

if keyword_set(den) then den=1 else den=0
if keyword_set(temp) then temp=1 else temp=0
if den+temp eq 0 then begin
    den=1
    temp=1  ;default
endif

;May need password: (taken from mvn_lpw_cdf_read.pro)
if getenv('MAVENPFP_USER_PASS') eq '' then begin
  ;see mvn_file_source, 2015-04-17, jmm
  if getenv('USER') ne '' then passwd = getenv('USER')+':'+getenv('USER')+'_pfp' $
  else if getenv('USERNAME') ne '' then passwd = getenv('USERNAME')+':'+getenv('USERNAME')+'_pfp' $
  else if getenv('LOGNAME') ne '' then passwd = getenv('LOGNAME')+':'+getenv('LOGNAME')+'_pfp' $
  else passwd = ''
endif else passwd = getenv('MAVENPFP_USER_PASS')

;/disks/data/maven/data/sci/sta/l3/  density  temperature

;The default for this routine is to use get_colors(); if this doesn't work, use this backup array of color indices:
colsbestguess = create_struct('black'      ,     0   , $  
                              'magenta'    ,     20  , $
                              'blue'       ,     50  , $
                              'red'        ,     250 , $
                              'green'      ,     170)

;Get timerange from timespan:
get_timespan, tr
if size(tr,/type) eq 0 then begin
    print, ""
    print, proname, ": set timerange using timespan, 'yyyy-mm-dd', ndays"
    return
endif

;Find whole number of days to load:
ndays = ceil((tr[1]-tr[0])/86400d) 
date0 = time_string(tr[0], precision=-3)  ;first date, yyyy-mm-dd format
time0 = time_double(date0)  ;first date in UNIX seconds

;Loop through each day, and load into tplot:
for tt = 0l, ndays-1l do begin  
    dateTMP0 = time_string(time0 + (86400d*tt), precision=-3)  ;current date, yyyy-mm-dd format
    yr = strmid(dateTMP0, 0, 4)
    mm = strmid(dateTMP0, 5, 2)
    dd = strmid(dateTMP0, 8, 2)
    
    dateTMP1 = yr+mm+dd  ;yyyymmdd format
        
    ;Density:
    if den eq 1 then begin
        ;SCIENCE FILES: always get by default
        fname1 = 'maven'+sl+'data'+sl+'sci'+sl+'sta'+sl+'l3'+sl+'density'+sl+yr+sl+mm+sl+'mvn_sta_l3_den_'+dateTMP1+'_v??.tplot'  ;science file
        If(sl ne '/') Then fname1 = strjoin(strsplit(fname1, sl, /extract), '/') ;fix to PC issue, jmm, 17-apr-2015
        fname2 = mvn_pfp_file_retrieve(fname1, user_pass = passwd, /valid_only)  ;jmm, 2015-02-05 to use mvn_pfp_file_retrieve, don't include the root_data_dir
              
        if fname2[0] ne '' then begin        
            ;Find most recent version number: EDIT 2021-12-02: CMF: this is done in mvn_pfp_file_retrieve, so mvn_sta_l3_latest_file is not needed.
            ;fname3 = mvn_sta_l3_latest_file(fname2, /den, success=success1)
            fname3 = fname2
            if size(filesloaded,/type) eq 0 then filesloaded = fname3 else filesloaded = [filesloaded, fname3] ;save files loaded.
            
            ;Load into tplot.
            if keyword_set(append) and tt eq 0 then tplot_restore, filename=fname3[0], /append
            if not keyword_set(append) and tt eq 0 then tplot_restore, filename=fname3[0]
            if tt ge 1 then tplot_restore, filename=fname3[0], /append  ;append all subsequent days                                         
        endif
        
        ;ANC FILES, if requested:        
        if keyword_set(anc) then begin
            fname1a = 'maven'+sl+'data'+sl+'sci'+sl+'sta'+sl+'l3'+sl+'density'+sl+yr+sl+mm+sl+'mvn_sta_l3_den_'+dateTMP1+'_full_v??.tplot'  ;full file
            If(sl ne '/') Then fname1a = strjoin(strsplit(fname1a, sl, /extract), '/')
            fname2a = mvn_pfp_file_retrieve(fname1a, user_pass = passwd, /valid_only)
            
            if fname2a[0] ne '' then begin
                ;Find most recent version number:
                ;fname3a = mvn_sta_l3_latest_file(fname2a, /den, success=success1)
                fname3a = fname2a
                if size(filesloaded,/type) eq 0 then filesloaded = fname3a else filesloaded = [filesloaded, fname3a] ;save files loaded.
                
                ;Load into tplot.
                if keyword_set(append) and tt eq 0 then tplot_restore, filename=fname3a[0], /append
                if not keyword_set(append) and tt eq 0 then tplot_restore, filename=fname3a[0]
                if tt ge 1 then tplot_restore, filename=fname3a[0], /append  ;append all subsequent days          
            endif
         endif  ;anc files
         
         ;FLAG files if requested:
         if keyword_set(flag) then begin
            fname1a = 'maven'+sl+'data'+sl+'sci'+sl+'sta'+sl+'l3'+sl+'density'+sl+yr+sl+mm+sl+'mvn_sta_l3_den_'+dateTMP1+'_flags_v??.tplot'
            If(sl ne '/') Then fname1a = strjoin(strsplit(fname1a, sl, /extract), '/')
            fname2a = mvn_pfp_file_retrieve(fname1a, user_pass = passwd, /valid_only)
            
            if fname2a[0] ne '' then begin
                ;Find most recent version number:
                ;fname3a = mvn_sta_l3_latest_file(fname2a, /den, success=success1)
                fname3a = fname2a
                if size(filesloaded,/type) eq 0 then filesloaded = fname3a else filesloaded = [filesloaded, fname3a] ;save files loaded.
  
                ;Load into tplot.
                if keyword_set(append) and tt eq 0 then tplot_restore, filename=fname3a[0], /append
                if not keyword_set(append) and tt eq 0 then tplot_restore, filename=fname3a[0]
                if tt ge 1 then tplot_restore, filename=fname3a[0], /append  ;append all subsequent days
            endif
         endif
        
    
    endif
        
    ;Temperature:
    if temp eq 1 then begin
        ;SCIENCE FILES:
        fname1 = 'maven'+sl+'data'+sl+'sci'+sl+'sta'+sl+'l3'+sl+'temperature'+sl+yr+sl+mm+sl+'mvn_sta_l3_temp_'+dateTMP1+'_v??.tplot'
        If(sl ne '/') Then fname1 = strjoin(strsplit(fname1, sl, /extract), '/') ;fix to PC issue, jmm, 17-apr-2015
        fname2 = mvn_pfp_file_retrieve(fname1, user_pass = passwd, /valid_only)  ;jmm, 2015-02-05 to use mvn_pfp_file_retrieve, don't include the root_data_dir
        
        if fname2[0] ne '' then begin
            ;Find most recent version number:
            ;fname3 = mvn_sta_l3_latest_file(fname2, /temp, success=success2)
            fname3 = fname2
            if size(filesloaded,/type) eq 0 then filesloaded = fname3 else filesloaded = [filesloaded, fname3] ;save files loaded.
            
            ;Load into tplot.
            if keyword_set(append) and tt eq 0 then tplot_restore, filename=fname3[0], /append
            if not keyword_set(append) and tt eq 0 then tplot_restore, filename=fname3[0]
            if tt ge 1 then tplot_restore, filename=fname3[0], /append  ;append all subsequent days
        endif
        
        ;ANC FILES, if requested:
        if keyword_set(anc) then begin
            fname1a = 'maven'+sl+'data'+sl+'sci'+sl+'sta'+sl+'l3'+sl+'temperature'+sl+yr+sl+mm+sl+'mvn_sta_l3_temp_'+dateTMP1+'_full_v??.tplot'
            If(sl ne '/') Then fname1a = strjoin(strsplit(fname1a, sl, /extract), '/')
            fname2a = mvn_pfp_file_retrieve(fname1a, user_pass = passwd, /valid_only)
  
            if fname2a[0] ne '' then begin
                ;Find most recent version number:
                ;fname3a = mvn_sta_l3_latest_file(fname2a, /temp, success=success2)
                fname3a = fname2a
                if size(filesloaded,/type) eq 0 then filesloaded = fname3a else filesloaded = [filesloaded, fname3a] ;save files loaded.
                
                ;Load into tplot.
                if keyword_set(append) and tt eq 0 then tplot_restore, filename=fname3a[0], /append
                if not keyword_set(append) and tt eq 0 then tplot_restore, filename=fname3a[0]
                if tt ge 1 then tplot_restore, filename=fname3a[0], /append  ;append all subsequent days
            endif
          
        endif  ;anc
        
    endif

endfor  ;tt


if keyword_set(margin) then tplot_options, 'xmargin', [16,8]

;Fix colors for density here:
if not keyword_set(leavecolors) then begin  ;only fix colors if requested
    ;Setup color table if needed:
    if keyword_set(qualc) then begin
        @'qualcolors'
        cols = qualcolors  ;copy colortable variable
        cols5 = [cols.black, cols.purple, cols.blue, cols.red, cols.green] ;5 colors for density
        cols3 = [cols.blue, cols.red, cols.green]  ;heavy ion method
    endif else begin
        ;Not qualcolors:
        if keyword_set(coltab) then ct = coltab else ct = 43 ;default if coltab not set
        ;loadct2, ct  ;as of 2024-02-28, CMF disabled this - users must set it themselves.
        cols = get_colors()  ;get list of table colors   
        if size(cols,/type) ne 8 then cols=colsbestguess
        cols5 = [cols.black, cols.magenta, cols.blue, cols.red, cols.green]   ;note, 43 doesn't have purple - use magenta instead. 
        cols3 = [cols.blue, cols.red, cols.green]
    endelse
        
    if keyword_set(den) then begin
        dvars = ['mvn_sta_l3_density', 'mvn_sta_l3_density_abs_uncertainty', 'mvn_sta_l3_density_perc_uncertainty', $
                    'mvn_sta_l3_density_quality_flag']
        ndv = n_elements(dvars)       
        for dv = 0l, ndv-1l do options, dvars, colors=cols5  ;change colors
        options, 'mvn_sta_l3_density_heavy_method', colors=cols3
        
        ;Fix attenuator + state mode colors:
        options, 'mvn_sta_c6_att_mode', colors=[cols.black, cols.red]
    endif  ;den
    
    if keyword_set(temp) then begin
      options,'mvn_sta_l3_sta_att_mode',colors=[cols.black,cols.red]  
    endif
    
endif  ;leavecolors


;;; added by KGH 11/9/21
;; now recreate the array-of-strings tplot variables
if keyword_set(anc) and keyword_set(temp) then begin
  
  ;; load the colors if they weren't loaded already
  if keyword_set(leave_colors) then begin
    if keyword_set(qualcolors) then begin
      @'qualcolors'
      cols = qualcolors  ;copy colortable variable
      str_element, cols, 'cyan', cols.pink, /add ; this is terrible but I needed a field called cyan -- I can't add a new qualcolor, so I'll just make it pink. 
      endif else begin
       ;Not qualcolors:
        if keyword_set(coltab) then ct = coltab else ct = 43 ;default if coltab not set
        ;loadct2, ct  ;CMF disabled on 2024-02-28
        cols = get_colors() 
        if size(cols,/type) ne 8 then cols=colsbestguess
        str_element, cols, 'orange', 200, /add ; best guess       
      endelse     
  endif else begin
    if keyword_set(qualcolors) then str_element, cols, 'cyan', cols.pink, /add else str_element, cols, 'orange', 200, /add
  endelse
  badvars =  ['mvn_sta_temp_lpwcorr', 'tpar_w_corr', 'ana_dth_fwhm_compare', 'tperp_w_corr', 'modeatt']

  store_data,'mvn_sta_temp_lpwcorr', data=['mvn_sta_c6_o2+_tparu','mvn_sta_c6_o2+_temp_nolpw']
  ylim,'mvn_sta_temp_lpwcorr',0.01,10,1
  options,'mvn_sta_temp_lpwcorr',colors=[cols.black,cols.cyan]

  store_data, 'tpar_w_corr', data=['mvn_sta_c6_o2+_tparu', $
    'mvn_sta_c6_o2+_temp', 'mvn_sta_c6_o2+_temp_ac' ]
  options, 'tpar_w_corr', 'colors', [cols.blue, cols.cyan, cols.orange]
  options, 'tpar_w_corr', 'labels', ['Uncorrected', $
    'Corrected', 'Analyzer']
  options, 'tpar_w_corr', 'labflag', -1
  ylim, 'tpar_w_corr', 0.001, 10, 1

  store_data,'ana_dth_fwhm_compare',data=['ana_dth_fwhm','ana_dth_fwhm_corr']
  ylim,'ana_dth_fwhm_compare',1.,7.,1

  store_data, 'tperp_w_corr', data=['mvn_sta_c8_tperpu', $
    'mvn_sta_c8_temp', 'mvn_sta_c8_o2+_temp_ac' ]
  options, 'tperp_w_corr', 'colors', [cols.blue, cols.cyan, cols.orange]
  options, 'tperp_w_corr', 'labels', ['Uncorrected', $
    'Corrected', 'Analyzer']
  options, 'tperp_w_corr', 'labflag', -1
  ylim, 'tperp_w_corr', 0.001, 10, 1

  store_data, 'modeatt', data=['mvn_sta_c6_mode', 'mvn_sta_c6_att']
  options,'modeatt','colors',[cols.black,cols.red]
endif ;anc & temp

success=1 

;Print blurb at end with links to STATIC papers for caveats etc:
print, ""
print, "****************************************"
print, "A note from the MAVEN-STATIC instrument team: thanks for using the L3 data!"
print, "Please see the following publications for more information about how the L3"
print, "products are created, and descriptions of the most common caveats to be aware of:"
print, ""
print, "Hanley+ (2021), In situ measurements of thermal ion temperature in the Martian ionosphere."
print, "Journal of Geophysical Research: Space Physics."
print, ""
print, "Fowler+ (2022), In‐situ measurements of ion density in the Martian ionosphere: Underlying"
print, "structure and variability observed by the MAVEN‐STATIC instrument."
print, "Journal of Geophysical Research: Space Physics"
print, ""
print, "McFadden+ (2015), MAVEN suprathermal and thermal ion composition (STATIC) instrument."
print, "Space Science Reviews."
print, "****************************************"
print, ""

end


