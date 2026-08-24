;+
;Routine to load in STATIC "full" data files, and fix any "broken" tplot variables. The "full" data files are then resaved in their
;originally directory.
;
;As of 2021-11-03, the following fixes are dealt with:
;
;mvn_sta_c6_att_mode: this is tplot variable constructed from two separate ones, mvn_sta_c6_att and mvn_sta_c6_mode. Currently, when
;tplot_restore is used to load in multiple tplot_save files of these joint variable types, it crashes. The fix is to create the joint variable
;using a 2D array, rather than two separate tplot variables. 
;
;'mvn_sta_temp_lpwcorr', 'tpar_w_corr', 'ana_dth_fwhm_compare', 'tperp_w_corr', 'modeatt': These variables are also joint variables, 
;but may not have the same time cadence. These variables are deleted from the temperature files and will be recreated in mvn_sta_l3_load.
;
;-
;

pro mvn_sta_l3_fix_variables

basedir = '/disks/data/maven/data/sci/sta/l3/'
dendir = basedir+'density/'
tempdir = basedir+'temperature/'


;###################
;DENSITY FILE FIXES:

;mvn_sta_c6_att_mode:

dfiletmp = 'mvn_sta_l3_den_????????_full_v??.tplot' 
files_den = file_search(dendir, dfiletmp, count=nfiles_den)  ;search recursively through year and month subfolders.

for ff = 0l, nfiles_den-1l do begin
    store_data, '*', /delete  ;clear tplot
    
    tplot_restore, filename=files_den[ff]  ;restore data
    
    tvars = tnames() ;list of names loaded
    
    ;################
    ;Store attenuator and mode as a single double line array:
    tname = 'mvn_sta_c6_att_mode'   
    get_data, 'mvn_sta_c6_mode', data=ddc6mode  ;get individual data for mode and att
    get_data, 'mvn_sta_c6_att', data=ddc6att
    store_data, tname, data={x: ddc6mode.x, y: [[ddc6mode.y], [ddc6att.y]]}  ;overwrite the trouble tplot variable
      options, tname, labels=['Mode', 'Att']
      options, tname, labflag=-1
      options, tname, colors=[0, 1]  ;note, default hard coded colors here- will fix in the l3 load routine
      ylim, tname, -1, 9
    
    ;################
    ;The variable mvn_sta_c6_o_o2_co2_density is another multi tplot variable that breaks when trying to tplot_restore multiple days.
    ;Each of the three varaibles is a separate tplot variable, so just delete the combined one here:
    store_data, 'mvn_sta_c6_o_o2_co2_density', /delete
    
    
    ;################
    ;Save the updated set of tplot variables - overwrite the original file
    tvars2 = tnames() ;updated list of names loaded
    
    tplot_save, tvars2, filename=files_den[ff]  ;resave tplot variable - save all variables, into the same directory.
    
endfor


;#######################
;TEMPERATURE FILE FIXES:

tfiletmp = 'mvn_sta_l3_temp_????????_full_v??.tplot'
files_temp = file_search(tempdir, tfiletmp, count=nfiles_temp)  ;search recursively through year and month subfolders.

badvars =  ['mvn_sta_temp_lpwcorr', 'tpar_w_corr', 'ana_dth_fwhm_compare', 'tperp_w_corr', 'modeatt']

for ff = 0l, nfiles_temp-1l do begin
  store_data, '*', /delete  ;clear tplot

  tplot_restore, filename=files_temp[ff]  ;restore data

  tvars = tnames() ;list of names loaded
   
  store_data,badvars,/delete; delete the bad variables 

  tplot_save, tvars, filename=files_temp[ff]  ;resave tplot variable - save all variables, into the same directory.
endfor


end


