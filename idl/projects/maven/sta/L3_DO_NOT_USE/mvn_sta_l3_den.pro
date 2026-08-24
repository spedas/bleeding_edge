;+
;STATIC processing routine to generate L3 density and flow products. 
;
;Routine uses mvn_sta_l3_mac_den_v2 -> this is mac_den, but with minor edits to work in this pipeline.
;
;
;INPUTS:
;trange: [a,b]: double UNIX times - calculate STATIC densities between these two times. Note, this routine is expecting trange to span
;               a single day only, ie midnight to mignight, to match MAVEN L0 files. If not set, full time range is used.
;qualc: Set this to use Mike Chaffins qualcolors-  this is for CMF only.
;savedir: string: full base directory in which to save the tplot save file. This routine will then add yr/mn/ sub folders if needed
;                 within savedir. Only used for testing - the routine will use the correct directory for processing by default if this is
;                 not set.
;
;vSTR = version number
;
;Set /nobkg to process even if no bkg files have been loaded (this is achived using iv_level>0 with mvn_sta_l2_load). The default in mvn_sta_mac_den_v2
;     is to abort if no bkg is found.
;
;spiceloaded: set to a string array containing the names of SPICE kernels used for this run. This array will be stored in the preliminary
;             tplot density file, under the limit structure.
;
;parent_files: set to a string array containing the names of the STATIC L2 files used for this run. This array will be stored in the
;              preliminary tplot density file, under the limit structure.
;
;NOTES TO FIX:
;How to track file version number?
;
;
;KEY OUTPUTS:
;mvn_sta_density_prelim: original stitched density (nbc and d0/d1)
;mvn_sta_density_prelim_2: stitched density, with values averaged over attenuator state changes.
;
;.r /Users/cmfowler/IDL/STATIC_routines/Processing_software/L3/mvn_sta_l3_den.pro
;-
;

pro mvn_sta_l3_den, trange=trange, qualc=qualc, success=success, savedir=savedir, vSTR=vSTR, nobkg=nobkg, spiceloaded=spiceloaded, parent_files=parent_files

proname='mvn_sta_l3_den'
if size(vSTR,/type) eq 0 then vSTR = '02'  ;*** how keep track of this?

if size(spiceloaded, /type) eq 0 then spiceloaded = ''
if size(parent_files, /type) eq 0 then parent_files = ''

syst1 = systime(/seconds)

sl = path_sep()  ;'/' or '\' (mac or windows)

;If savedir is specified, save file there, if not, use SSL file directory:
if not keyword_set(savedir) then savedir = '/disks/data/maven/data/sci/sta/l3/density/'

;SETUP COLORS: Setting /qualc uses Mike Chaffins qual colors (usually only works for CMF). Default if not is to load ct43.
;SORT COLORS HERE:
if keyword_set(qualc) then begin
    @'qualcolors'
    colorindices = create_struct('black'    ,     qualcolors.black    , $
                                 'purple'   ,     qualcolors.purple   , $
                                 'brown'    ,     qualcolors.brown    , $
                                 'magenta'  ,     qualcolors.purple   , $
                                 'blue'     ,     qualcolors.blue     , $
                                 'cyan'     ,     qualcolors.pink     , $  ;no equivalent in qualc, use pink
                                 'green'    ,     qualcolors.green    , $
                                 'yellow'   ,     qualcolors.yellow   , $
                                 'orange'   ,     qualcolors.orange   , $
                                 'red'      ,     qualcolors.red      , $
                                 'white'    ,     qualcolors.white)
   
endif else begin
    colorindices=get_colors()  ;standard ct=39
    str_element, colorindices, /add, "brown", 25  ;random guess here
    str_element, colorindices, /add, "purple", colorindices.magenta  ;copy
    str_element, colorindices, /add, "orange", 210  ;guess
endelse
    
;CHECKS:
get_data, 'mvn_lpw_swp1_IV', data=ddlpwiv  
if size(ddlpwiv, /type) eq 0 then begin
  print, proname, ": I couldn't find any LPW SWP1 data. This is necessary."
  success=0
  return
endif

get_data, 'mvn_sta_c6_E', data=ddstac6
if size(ddstac6, /type) eq 0 then begin
    print, proname, ": I couldn't find any STATIC files for this date and iv_level. Returning."
    success=0
    return
endif

;Get date requested:
dateSTR1 = strtrim(time_string(ddstac6.x[10], precision=-3),2)  ;this routine expects trange to span 24 hours at most. Use .x[10] incase a few points overlap to previous day
yrSTR = strmid(dateSTR1, 0, 4)
mnSTR = strmid(dateSTR1, 5, 2)
dySTR = strmid(dateSTR1, 8, 2)
dateSTR2 = yrSTR+mnSTR+dySTR  ;file format yyyymmdd

;Check if d1 data are loaded, if not use d0:
get_data, 'mvn_sta_d0_E', data=ddd0
get_data, 'mvn_sta_d1_E', data=ddd1
if size(ddd0,/type) eq 8 then yesd0 = 1 else yesd0 = 0
if size(ddd1,/type) eq 8 then yesd1 = 1 else yesd1 = 0

;Calculate density:
mvn_sta_l3_mac_den_v2, yesd0, yesd1, skip_get_4dt=skip_get_4dt, energy=energy, trange=trange, success=success1, colorindices=colorindices, nobkg=nobkg

if success1 eq 1 then begin
    ;Stitch together nbc and 4d, calculate uncertainty, and produce flags:
        
    ;Calculate % of eflux in top 3 bins, and energy of peak eflux from c6: CMF 2026-05: this now used c6 energy bins:
    mvn_sta_cac6_energy_peak, trange=trange, species='O', /angularwidth, tnameadd='_all'  ;ca has no mass, so applies for all species
    mvn_sta_cac6_energy_peak, trange=trange, species='O', /energywidth, tnameadd='_Op'  ;this code moved out to get_static_density_for_timerange
    mvn_sta_cac6_energy_peak, trange=trange, species='O2', /energywidth, tnameadd='_O2p'
    mvn_sta_cac6_energy_peak, trange=trange, species='CO2', /energywidth, tnameadd='_CO2p'  

    ;Get sc pot:
    mvn_sta_tplot_scpot, sta_apid='c6', /staticonly, trange=trange  ;this uses STATIC common blocks, which have been updated using mvn_scpot above
    
    ;SW region:
    mvn_sta_mom_swregion, sta_apid='c6', trange=trange
 
    ;Get flags, stitch:
    mvn_sta_l3_den_stitch, spicekernels=spicekernels, trange=trange, colorindices=colorindices
           
    ;Calculate uncertainties. Here, I used min_cnts=0l, so that dn_4d() and Gwens routine will produce a value. We can then flag
    ;when (data-bkg) < min_cnts later on, in the flagging routine.
    mvn_sta_l3_den_uncertainty, trange=trange, min_cnts=0l, colorindices=colorindices, print=1

    ;Calculate MSO position, IAU altitude and SZA:
    get_data, 'mvn_sta_density_prelim_2', data=ddtmp
    mvn_sta_anc_ephemeris, ddtmp.x, /mvn_alt, /mvn_pos, /mvn_sza
    
    ;Tidy up method variables:
    get_data, 'mvn_sta_den_method', data=ddh1, dlimit=dlh1, limit=llh1
    tname = 'mvn_sta_l3_density_heavy_method'
    str_element, dlh1, 'Notes', '0=moment, >0=beam'
    store_data, tname, data=ddh1, dlimit=dlh1, limit=llh1
      options, tname, ytitle='O+, O2+, CO2+!Cdensity method'

    get_data, 'mvn_sta_light_den_method', data=ddh1, dlimit=dlh1, limit=llh1
    tname = 'mvn_sta_l3_density_light_method'
    str_element, dlh1, 'Notes', 'Moment: 0=c6, 1=d0, 2=d1'
    store_data, tname, data=ddh1, dlimit=dlh1, limit=llh1
      options, tname, ytitle='H+, He++ (m/q=2)!Cdensity method'
    
    ;Add spiceloaded and parent_files to mvn_sta_density_prelim_2: (goes to limits structure)
    options, 'mvn_sta_density_prelim_2', 'spiceloaded', spiceloaded
    options, 'mvn_sta_density_prelim_2', 'parent_files', parent_files
    
    ;Make the colors for variables the same as those for density, so that they match:
    get_data, 'mvn_sta_density_prelim_2', limit=lltmp
    options, 'mvn_sta_ca_anode_cnts', colors=lltmp.colors[0:1] ;two elements only
    options, 'mvn_sta_ca_anode_perc', colors=lltmp.colors[0:1] ;two elements only
    
    tsave1 = ['mvn_sta_o+_c6_density2', 'mvn_sta_o2+_c6_density2', 'mvn_sta_c6_den_co2', $  ;nbc densities
              'mvn_sta_c6_den_p', 'mvn_sta_c6_den_a', 'mvn_sta_d0_den_p', 'mvn_sta_d1_den_p', 'mvn_sta_d0_den_a', 'mvn_sta_d1_den_a', $  ;n_4d densities for H+ and He++
              'mvn_sta_o+_d0_density_n_4d', 'mvn_sta_o+_d1_density_n_4d', 'mvn_sta_o2+_d0_density_n_4d', $  ;d0 and d1 densities for heavies
              'mvn_sta_o2+_d1_density_n_4d', 'mvn_sta_co2+_d0_density_n_4d', 'mvn_sta_co2+_d1_density_n_4d', $  ;d0 and d1 densities for heavies
              'mvn_sta_c6_cb_scpot', 'mvn_sta_c6_att', 'mvn_sta_c6_mode', $             
              'mvn_sta_ca_panode_index_all', 'mvn_sta_ca_anode_cnts_all', 'mvn_sta_ca_anode_perc_all', $ ;parameters 
              'mvn_sta_c6_E', 'mvn_sta_c6_M_twt', 'mvn_sta_ca_A', $  ;E+M spectra  
              'mvn_sta_c6_peak_counts_Op', 'mvn_sta_c6_peak_counts_O2p', 'mvn_sta_c6_peak_counts_CO2p', $
              'mvn_sta_c6_peak_counts_perc_Op', 'mvn_sta_c6_peak_counts_perc_O2p', 'mvn_sta_c6_peak_counts_perc_CO2p', $
              'mvn_sta_c6_peak_counts_energy_Op', 'mvn_sta_c6_peak_counts_energy_O2p', 'mvn_sta_c6_peak_counts_energy_CO2p', $              
              'mvn_sta_den_uncert', 'mvn_sta_den_uncert_perc', $  ;uncertainties
              'mvn_sta_h+_c6_all_cnts', 'mvn_sta_h+_c6_all_bkg', 'mvn_sta_he++_c6_all_cnts', 'mvn_sta_he++_c6_all_bkg', $  ;cnts and bkg using n_4d, all energies
              'mvn_sta_o+_c6_all_cnts', 'mvn_sta_o2+_c6_all_cnts', 'mvn_sta_o+_c6_all_bkg', 'mvn_sta_o2+_c6_all_bkg', $  ;cnts and bkg using n_4d, all energies, heavies
              'mvn_sta_o+_c6_cnts', 'mvn_sta_o+_c6_bkg', 'mvn_sta_o+_c6_nbc_den_qf', 'mvn_sta_ramdir_angle', $  ;cnts and bkg at E<11eV (nbc) (no '_all' in name)
              'mvn_sta_o2+_c6_cnts', 'mvn_sta_o2+_c6_bkg', 'mvn_sta_o2+_c6_nbc_den_qf', 'mvn_sta_co2+_c6_cnts', 'mvn_sta_co2+_c6_bkg', $  ;cnts and bkg at E<11eV (nbc)
              'mvn_sta_o+_c6_density_all', 'mvn_sta_o2+_c6_density_all', $  ;these are O+ and O2+ using n_4d, full energy range ('all')
              'mvn_sta_anc_mvn_pos_mso', 'mvn_sta_anc_mvn_sza', 'mvn_sta_anc_mvn_alt_iau', 'mvn_sta_sw_region', $  ;ephemeris
              'mvn_sta_anc_mars_ls', 'mvn_sta_anc_mvn_longlat_iau', $  ;ephemeris
              'mvn_att_bar', 'mvn_sta_apid_method', 'mvn_sta_d0d1pair'] ;other
    
    ;SAVE TPLOT: store as whole day file here.    
    ;Set up year-month folder directory if not present:
    savedir2 = savedir+yrSTR+sl+mnSTR+sl ;this is the save directory
    mvn_sta_makedir, savedir, yrSTR, mnSTR, success=success_dir, /group
    
    ;Double check save directory exists:
    if success_dir eq 0 then begin
        print, proname, ": I couldn't create the requested save directory.
        success=0
        return
    endif 
    
    ;SAVE:
    tsave2=[tsave1, 'mvn_sta_density_prelim_2', 'mvn_sta_l3_density_light_method', 'mvn_sta_l3_density_heavy_method']
    fn1='mvn_sta_l3_den_'+dateSTR2+'_full_v'+vSTR
    tplot_save, tsave2, filename=savedir2+fn1
    mvn_sta_checkfilesave, savedir2+fn1+'.tplot'


endif else begin
    print, proname, ": mvn_sta_l3_mac_den_v2 wasn't successful."
    success=0
    return
endelse


success=1  

syst2 = systime(/seconds)

print, ""
print, proname, ": total run time to load L2 data and calculate densities:"
print, (syst2-syst1)/60., " minutes."

end




