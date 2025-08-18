;+ 
; MMS FPI summary crib sheet
; 
; mms_load_fpi_summary_crib.pro
; 
; Note:
;   This version is meant to work with v3.0.0 of the FPI CDFs
;   and will not work with v2.1 and below
; 
; Suggestions for this crib sheet:
;     https://github.com/spedas/bleeding_edge/issues
; 
;    
; History:
; egrimes updated 8/23/2016, forked for v3 of the FPI CDFs;
;     updated variable names for the new naming scheme
; 
; 
; egrimes updated 1/29/2016, changing to DMPA coordinates for 
;     magnetic field data, now using position from DFG files, 
;     instead of the ASCII/MEC files
; egrimes updated 12/9/2015, changed to GSM coordinates, adding 
;     support for l2pre, switched to use QL data instead of SITL
; egrimes updated 23Sep2015, to set some metadata for spectra/PADs
; egrimes updated 8Sept2015
; BGILES UPDATED 1Sept2015
; BGILES UPDATED 31AUGUST2015
; SBoaardsen added query for brst or fast
; 
; $LastChangedBy: egrimes $
; $LastChangedDate: 2023-08-14 12:51:35 -0700 (Mon, 14 Aug 2023) $
; $LastChangedRevision: 31999 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/advanced/mms_load_fpi_summary_crib.pro $
;-

start_time = systime(/seconds)

;preparations and defaults
;date = '15-10-06/00:00:00'
;date = '15-9-01/00:00:00'

; full day for FS
;date = '2015-10-16/00:00:00'
;timespan, date, 1, /day

; small interval for burst
date = '2015-10-16/13:07'
timespan, date, 15, /min

data_rates = ['brst','fast'] ;SAB
read, 'for FPI data rate input 0 for brst, 1 for fast:', irate ;SAB
;data_rate = 'brst'
data_rate = data_rates[irate] ;SAB


;probes = [1, 2, 3, 4]
probes = [1]
datatype = ['des-moms', 'dis-moms'] ; grab all data in the CDF
level = 'l2' ; FPI data
fgm_level = 'l2' ; FGM
autoscale = 1
iw=0
width = 650
height = 750

; options for send_plots_to:
;   ps: postscript files
;   png: png files
;   win: creates/opens all of the tplot windows

send_plots_to = 'win'
plot_directory = ''

postscript = send_plots_to eq 'ps' ? 1 : 0

tplot_options,'xmargin',[15,15]              ; Set left/right margins to 10 characters
;tplot_options,'ymargin',[4,2]                ; Set top/bottom margins to 4/2 lines

; handle any errors that occur in this script gracefully
catch, errstats
if errstats ne 0 then begin
    error = 1
    dprint, dlevel=1, 'Error: ', !ERROR_STATE.MSG
    catch, /cancel
endif

;load data for all 4 probes
mms_load_fpi, trange = trange, probes = probes, datatype = datatype, $
    level = level, data_rate = data_rate, $
    local_data_dir = local_data_dir, source = source, $
    get_support_data = get_support_data, $
    tplotnames = tplotnames, no_color_setup = no_color_setup, $
    autoscale = autoscale, min_version='2.2.0'

; load ephemeris data for all 4 probes
; as of 3/14/16, we no longer use the S/C position data loaded from the FGM files
mms_load_mec, trange = trange, probes = probes

; load FGM data for all 4 probes
mms_load_fgm, trange = trange, probes = probes, level = fgm_level

FOR i=0,n_elements(probes)-1 DO BEGIN    ;step through the observatories
    obsstr='mms'+STRING(probes[i],FORMAT='(I1)')+'_'
    
    ;SET UP TPLOT VARIABLES
         
    ; convert the position data into Re
   ; eph_variable = 'mms'+strcompress(string(probes[i]), /rem)+'_defeph_pos'
    if fgm_level eq 'l2' then begin
        eph_variable = obsstr+'mec_r_gsm'
        b_variable = '_fgm_b_dmpa_srvy_l2'
    endif else begin
        eph_variable = obsstr+'mec_r_gsm'
      ;  eph_variable = 'mms'+strcompress(string(probes[i]), /rem)+'_ql_pos_gsm'
        b_variable = '_dfg_srvy_dmpa'
    endelse

    suffix_kludge = ['x', 'y', 'z']
    calc,'"'+eph_variable+'_re" = "'+eph_variable+'"/6371.2'
    
    ; split the position into its components
    split_vec, eph_variable+'_re'
    calc, '"'+eph_variable+'_r_gsm" = sqrt("'+eph_variable+'_re_'+suffix_kludge[0]+'"^2+"'+eph_variable+'_re_'+suffix_kludge[1]+'"^2+"'+eph_variable+'_re_'+suffix_kludge[2]+'"^2)'

    ; set the label to show along the bottom of the tplot
    options, eph_variable+'_r_gsm', ytitle='R (Re)'
    options, eph_variable+'_re_'+suffix_kludge[0],ytitle='X-GSM (Re)'
    options, eph_variable+'_re_'+suffix_kludge[1],ytitle='Y-GSM (Re)'
    options, eph_variable+'_re_'+suffix_kludge[2],ytitle='Z-GSM (Re)'
    position_vars = [eph_variable+'_re_'+suffix_kludge[2], eph_variable+'_re_'+suffix_kludge[1], eph_variable+'_re_'+suffix_kludge[0], eph_variable+'numberdensity']

    ; Data quality bar
    quality_bar = obsstr+'dis_errorflags_'+data_rate+'_moms_flagbars_mini'
    
    ; combine B into a single tplot variable
    prefix = 'mms'+strcompress(string(probes[i]), /rem)
    split_vec, prefix+b_variable
    
    ; time clip the data to -150nT to 150nT
    tclip, prefix+b_variable+'_bvec_?', -150, 150, /overwrite
    tclip, prefix+b_variable+'_btot', -150, 150, /overwrite
    
    store_data, prefix+'_fgm_dmpa_srvy_clipped', data=prefix+[b_variable+'_'+['0', '1', '2'], b_variable+'_btot']
    options, prefix+'_fgm_dmpa_srvy_clipped', labflag=-1
    options, prefix+'_fgm_dmpa_srvy_clipped', labels=['Bx DMPA', 'By DMPA', 'Bz DMPA', 'Bmag']
    options, prefix+'_fgm_dmpa_srvy_clipped', colors=[2, 4, 6, 0]
    options, prefix+'_fgm_dmpa_srvy_clipped', ytitle=prefix+'!CFGM'


    options, obsstr+'des_numberdensity'+data_rate, 'labels', 'Ne, electrons'
    options, obsstr+'dis_numberdensity'+data_rate, 'labels', 'Ni, ions'
    options, obsstr+'des_numberdensity'+data_rate, 'colors', 2
    options, obsstr+'dis_numberdensity'+data_rate, 'colors', 4

    ; combine the densities into one tplot variable
    store_data, obsstr+'numberdensity', data=[obsstr+'des_numberdensity', obsstr+'dis_numberdensity']+data_rate
    
    options, obsstr+'numberdensity', 'labflag', -1
    options, obsstr+'numberdensity', 'colors', [2, 4]
    options, obsstr+'numberdensity', ytitle='MMS'+STRING(probes[i],FORMAT='(I1)')+'!CFPI density'
    
    ; combine the bulk electron velocities into one tplot variable
   ; get_data, obsstr+'des_bulkx'+'_dbcs_'+data_rate, xtimes, bulkx
   ; get_data, obsstr+'des_bulky'+'_dbcs_'+data_rate, xtimes, bulky
   ; get_data, obsstr+'des_bulkz'+'_dbcs_'+data_rate, xtimes, bulkz
   ; e_bulk_mag=SQRT(bulkx^2+bulky^2+bulkz^2)
   ; store_data, obsstr+'ebulkv_mag'+'_dbcs_'+data_rate, data = {x:xtimes, y:e_bulk_mag}
   ; join_vec, [obsstr+'des_bulkx', obsstr+'des_bulky', obsstr+'des_bulkz', obsstr+'ebulkv_mag']+'_dbcs_'+data_rate, obsstr+'ebulkv_dbcs'


    options, obsstr+'des_bulkv_gse_'+data_rate, 'labels', ['Vx', 'Vy', 'Vz']
    options, obsstr+'des_bulkv_gse_'+data_rate, 'labflag', -1
    options, obsstr+'des_bulkv_gse_'+data_rate, 'colors', [2, 4, 6]
    options, obsstr+'des_bulkv_gse_'+data_rate, 'ytitle', 'MMS'+STRING(probes[i],FORMAT='(I1)')+'!CeBulkV!CGSE'
    options, obsstr+'des_bulkv_gse_'+data_rate, 'ysubtitle', '[km/s]'
    
    ; combine the bulk ion velocity into a single tplot variable
  ;  get_data, obsstr+'dis_bulkx'+'_dbcs_'+data_rate, xtimes, bulkx
  ;  get_data, obsstr+'dis_bulky'+'_dbcs_'+data_rate, xtimes, bulky
  ;  get_data, obsstr+'dis_bulkz'+'_dbcs_'+data_rate, xtimes, bulkz
  ;  i_bulk_mag=SQRT(bulkx^2+bulky^2+bulkz^2)
  ;  store_data, obsstr+'ibulkv_mag'+'_dbcs_'+data_rate, data = {x:xtimes, y:i_bulk_mag}
   ; join_vec, [obsstr+'dis_bulkX', obsstr+'dis_bulkY', obsstr+'dis_bulkZ', obsstr+'ibulkv_mag'], obsstr+'ibulkv_dbcs'
  ;  join_vec, [obsstr+'dis_bulkx', obsstr+'dis_bulky', obsstr+'dis_bulkz', obsstr+'ibulkv_mag']+'_dbcs_'+data_rate, obsstr+'ibulkv_dbcs'

    options, obsstr+'dis_bulkv_gse_'+data_rate, 'labels', ['Vx', 'Vy', 'Vz']
    options, obsstr+'dis_bulkv_gse_'+data_rate, 'labflag', -1
    options, obsstr+'dis_bulkv_gse_'+data_rate, 'colors', [2, 4, 6]
    options, obsstr+'dis_bulkv_gse_'+data_rate, 'ytitle', 'MMS'+STRING(probes[i],FORMAT='(I1)')+'!CiBulkV!CGSE'
    options, obsstr+'dis_bulkv_gse_'+data_rate, 'ysubtitle', '[km/s]'
    
    ; combine the parallel and perpendicular temperatures into a single tplot variable
    store_data, obsstr+'temp', data=[obsstr+'des_temppara_', obsstr+'des_tempperp_', obsstr+'dis_temppara_', obsstr+'dis_tempperp_']+data_rate
    options, obsstr+'temp', 'labels', ['eTpara', 'eTperp', 'iTpara', 'iTperp']
    options, obsstr+'temp', 'labflag', -1
    options, obsstr+'temp', 'colors', [2, 4, 6, 8]
    options, obsstr+'temp', 'ytitle', 'MMS'+STRING(probes[i],FORMAT='(I1)')+'!CTemp'

    ; use bss routine to create tplot variables for fast, burst bars
    trange = timerange(trange)
    spd_mms_load_bss, datatype=['fast', 'burst'], /include_labels
        
    ;-----------PLOT ELECTRON ENERGY SPECTRA DETAILS -- ONE SPACECRAFT --------------------
    ;PLOT: electron energy spectra for each observatory
    electron_espec = [obsstr+'des_energySpectr_pX', obsstr+'des_energySpectr_mX',$
                      obsstr+'des_energySpectr_pY', obsstr+'des_energySpectr_mY',$
                      obsstr+'des_energySpectr_pZ', obsstr+'des_energySpectr_mZ']+'_'+data_rate
    electron_espec = strlowcase(electron_espec)
    electron_espec_omni = [obsstr+'des_energyspectr_omni']+'_'+data_rate
    electron_espec_omni = strlowcase(electron_espec_omni)
    ; replace gaps with NaNs so tplot doesn't interpolate on the X axis
    tdegap, electron_espec, /overwrite
    tdegap, electron_espec_omni, /overwrite
    panels=['mms_bss_burst', 'mms_bss_fast', obsstr+'des_errorflags_'+data_rate+'_moms_flagbars', $
            prefix+'_fgm_dmpa_srvy_clipped', electron_espec, electron_espec_omni]
    window_caption="MMS FPI Electron energy spectra:  Counts, summed over DSC velocity-dirs +/- X, Y, & Z"
    if ~postscript then window, iw, xsize=width, ysize=height
    ;tplot_options,'title', window_caption
    tplot, panels, window=iw, var_label=position_vars, title=window_caption
   ; xyouts, .01, .98, window_caption, /normal, charsize=1.15
    
    if postscript then tprint, plot_directory + obsstr+"electron_eSpec"
    iw=iw+1
   
    ;-----------ION ENERGY SPECTRA DETAILS -- ONE SPACECRAFT--------------------
    ion_espec =     [obsstr+'dis_energySpectr_pX', obsstr+'dis_energySpectr_mX', $
                     obsstr+'dis_energySpectr_pY', obsstr+'dis_energySpectr_mY', $
                     obsstr+'dis_energySpectr_pZ', obsstr+'dis_energySpectr_mZ']+'_'+data_rate
    ion_espec = strlowcase(ion_espec)                 
    ion_espec_omni = [obsstr+'dis_energyspectr_omni']+'_'+data_rate
    ion_espec_omni = strlowcase(ion_espec_omni)
    
    ; replace gaps with NaNs so tplot doesn't interpolate on the X axis
    tdegap, ion_espec, /overwrite
    tdegap, ion_espec_omni, /overwrite
    
    panels=['mms_bss_burst', 'mms_bss_fast', obsstr+'dis_errorflags_'+data_rate+'_moms_flagbars', $
             prefix+'_fgm_dmpa_srvy_clipped',ion_espec, ion_espec_omni]
    window_caption="MMS FPI Ion energy spectra:  Counts, summed over DSC velocity-dirs +/- X, Y, & Z"
    if ~postscript then window, iw, xsize=width, ysize=height
;    tplot_options,'title', window_caption
    tplot, panels, window=iw, var_label=position_vars, title=window_caption
   ; xyouts, .05, .98, window_caption, /normal, charsize=1.15
    if postscript then tprint, plot_directory + obsstr+"ion_eSpec"
    iw=iw+1
      
                 
    ;-----------ONE SPACECRAFT ePAD DETAILS PLOT--------------------
    e_pad = [obsstr+'des_pitchAngDist_lowEn', obsstr+'des_pitchAngDist_midEn', $
              obsstr+'des_pitchAngDist_highEn' ]+'_'+data_rate
    e_pad = strlowcase(e_pad)

    e_pad_allE = [obsstr+'des_pitchangdist_sum', obsstr+'des_pitchangdist_avg']
    
    ; replace gaps with NaNs so tplot doesn't interpolate on the X axis
    tdegap, e_pad, /overwrite
    tdegap, e_pad_allE, /overwrite
    
    panels=['mms_bss_burst', 'mms_bss_fast', obsstr+'des_errorflags_'+data_rate+'_moms_flagbars', $
             prefix+'_fgm_dmpa_srvy_clipped',e_pad, e_pad_allE]
    window_caption="MMS FPI Electron PAD"
    if ~postscript then window, iw, xsize=width, ysize=height
    ;tplot_options,'title', window_caption
    tplot, panels, window=iw, var_label=position_vars, title=window_caption
  ;  xyouts, .3, .98, window_caption, /normal, charsize=1.15
    if postscript then tprint, plot_directory + obsstr+"ePAD"
    iw=iw+1 
       
    ;-----------ONE SPACECRAFT FPI SUMMARY PLOT--------------------
   ; fpi_moments = [prefix+'_fgm_dmpa_srvy_clipped', [obsstr+'des_numberdensity', obsstr+'dis_numberdensity'], obsstr+'ebulkv_dbcs',  $
   ;                obsstr+'ibulkv_dbcs', obsstr+'temp']
   ; fpi_espects = [obsstr+'dis_EnergySpectr_omni_avg', obsstr+'des_EnergySpectr_omni_avg']
    fpi_moments = [prefix+'_fgm_dmpa_srvy_clipped', $
                   obsstr+'des_errorflags_'+data_rate+'_moms_flagbars_mini', $
                   obsstr+'des_numberdensity_'+data_rate, $
                   obsstr+'dis_errorflags_'+data_rate+'_moms_flagbars_mini', $
                   obsstr+'dis_numberdensity_'+data_rate, $
                   obsstr+'des_bulkv_gse_'+data_rate,  $
                   obsstr+'dis_bulkv_gse_'+data_rate, obsstr+'temp']
                   
    fpi_espects = [obsstr+'dis_energyspectr_omni', obsstr+'des_energyspectr_omni']+'_'+data_rate
    panels=['mms_bss_burst', 'mms_bss_fast', $
            fpi_moments, obsstr+'des_pitchangdist_avg', fpi_espects]                  

    window_caption="MMS FPI Observatory Summary:"+"MMS"+STRING(probes[i],FORMAT='(I1)')
    if ~postscript then window, iw, xsize=width, ysize=height
    ;tplot_options,'title', window_caption
    tplot, panels, window=iw, var_label=position_vars, title=window_caption
  ;  xyouts, .3, .98, window_caption, /normal, charsize=1.15
    if postscript then tprint, plot_directory + obsstr+"Observatory Summary"
    iw=iw+1
    if send_plots_to eq 'png' then begin
        thm_gen_multipngplot, obsstr, date, directory = plot_directory, /mkdir
    endif
ENDFOR


;-----------FOUR SPACECRAFT SUMMARY PLOT--------------------
panels=['mms_bss_burst', 'mms_bss_fast', quality_bar]
FOR i=1,4 DO BEGIN
   obsstr = 'mms'+STRING(i,FORMAT='(I1)')
   panels=[panels,obsstr+'_fgm_dmpa_srvy_clipped',obsstr+'_des_energyspectr_omni_'+data_rate,obsstr+'_dis_energyspectr_omni_'+data_rate] 
ENDFOR
window_caption="MMS FPI Observatory Summary: MMS1, MMS2, MMS3, MMS4"
if ~postscript then window, iw, xsize=width, ysize=height
;tplot_options,'title', window_caption
tplot, panels, window=iw, var_label='mms'+strcompress(string(probes[0]), /rem)+'_defeph_pos', title=window_caption
;xyouts, .25, .98, window_caption, /normal, charsize=1.15
if postscript then tprint, plot_directory + "MMS-all FPI Observatory Summary"

; make the PNGs
if send_plots_to eq 'png' then begin
    thm_gen_multipngplot, 'mms_fpi_all', date, directory = plot_directory, /mkdir
endif
print, 'FPI summary script took: ' + string(systime(/sec)-start_time) + ' seconds to run'

stop

END