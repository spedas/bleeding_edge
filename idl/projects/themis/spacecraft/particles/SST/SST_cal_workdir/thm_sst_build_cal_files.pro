;+
;NAME:
; thm_sst_build_cal_files
;PURPOSE:
;
;  Automated routine to ease the creation of text-based cal-files
;
;$LastChangedBy: pcruce $
;$LastChangedDate: 2013-03-11 16:02:06 -0700 (Mon, 11 Mar 2013) $
;$LastChangedRevision: 11768 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/SST/SST_cal_workdir/thm_sst_build_cal_files.pro $
;-


;just encapsulates repeated code used to print the calibration files
;assumes dates in monotonic ordering
pro thm_sst_build_cal_files_helper,filename,comment,en_low,en_high,deadtime,gf_nominal,gf_dates,gf_corrections,$
                                   dl_dates,dl_corrections,attenuator,efficiencies
                                   
  compile_opt idl2,hidden

  i=0
  j=0
  openw,lun,filename,/get_lun
  printf,lun,comment
  ;loop over calibration coefficients.  Since not all coefs may occur at the same times, we have this some confusing double index loop condition
  repeat begin
   
    string_suffix=  strjoin(strtrim(en_low,2),' ')+' '+$
                    strjoin(strtrim(en_high,2),' ')+' '+$
                    strtrim(deadtime,2)+' '+$
                    strtrim(gf_nominal,2)+' '+$
                    strjoin(strtrim(gf_corrections[*,i],2),' ')+ ' ' + $
                    strjoin(strtrim(dl_corrections[*,j],2),' ')+' '+$
                    strtrim(attenuator,2)+' '+$
                    strjoin(strtrim(efficiencies,2),' ')
   
    if i ge n_elements(gf_dates)-1 then begin
      s=dl_dates[j]+' '+string_suffix
      printf,lun,s
      j++
    endif else if j ge n_elements(dl_dates)-1 then begin
      s=gf_dates[i]+' '+ string_suffix
      printf,lun,s
      i++
    endif else if time_double(gf_dates[i]) lt time_double(dl_dates[j])then begin
      s=gf_dates[i]+' '+ string_suffix
      printf,lun,s
      i++
    endif else if time_double(gf_dates[i]) gt time_double(dl_dates[j]) then begin
      s=dl_dates[j]+' '+string_suffx
      printf,lun,s
      j++
    endif else begin
    
      s=gf_dates[i]+' '+ string_suffix
      printf,lun,s
      i++
      j++
    endelse
    
  endrep until (i ge n_elements(gf_dates)-1 && j ge n_elements(dl_dates)-1)

  close,lun
  free_lun,lun


end

pro thm_sst_build_cal_files

  cal_file_root = '~/IDLWorkspace/themis/spacecraft/particles/SST/SST_cal_workdir/cal_files/'
  probes=['a','b','c','d','e']
  
  ;based on geometry only
  gf_nominal = 0.1
  ;dead time correction not yet completed
  deadtime = 0.0
  ;notional attentuator factor.  Attenuator factors TBD empirically(comparing delta flux from an attenuator close/open)
  attenuator_correction = 1/64.
  
  ;geant4 modeled energy boundaries
  ;deadlayers TBD empirically (looking at changing performance across time & after bias voltage steps)
  ;numbers are not strictly ascending because some of the boundaries are for SST coincidence channels.(FT,OT,FTO,FO)
  ion_open_en_low=[25,36,46,59,75,115,168,243,346,492,812,1453,6315,6485,6485,6485]  
  ion_open_en_high=[37,48,65,77,116,175,245,348,494,813,1455,6500,6485,6485,6485,6485]
  
  electron_foil_en_low=[26,36,46,58,73,113,165,241,345,495,600,600,335,481,640,710]
  electron_foil_en_high=[36,46,58,73,113,165,242,345,495,600,600,600,481,642,799,1409]
  
  ;geant modeled efficiencies.  
  ;These are applied only as a scalar divisor to each channel.
  ;Doesn't do any matrix-style decontamination/crosstalk removal
  ;However, future versions intend to use an efficiency decontamination matrix
  electron_foil_mono_channel_efficiencies=[0.35,0.49,0.52,0.59,0.73,0.77,0.77,0.75,0.43,0.16,0.05,0.05,0.34,0.60,0.60,0.25]
  ion_open_mono_channel_efficiencies=[1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0]
   
  ;calibration factors from drew turner(dturner@igpp.ucla.edu, 2013-03-07)   
  tha_ion_dead_layer_dates = ['1970-01-01/00:00:00', $ ;sentinel(slightly abusing the term)
                              '2008-06-25/00:00:00', $
                              '2008-12-24/00:00:00', $
                              '2009-07-02/00:00:00', $
                              '2009-12-24/00:00:00', $
                              '2010-06-10/00:00:00', $
                              '2010-12-06/00:00:00', $
                              '2011-06-06/00:00:00', $
                              '2011-12-07/00:00:00', $
                              '2012-05-30/00:00:00']
                              
  ;angle columns as listed in array below are theta look directions -52,-25,25,52
  ;non-monotone angle order matches the order that the data are stored in the SST data structures
  ;offsets are in keV                               
  tha_ion_dead_layer_offsets = [[6e,1,8,7],$
                                [7,4,8,7],$
                                [9,7,14,9],$
                                [12,13,14,12],$
                                [12,13,17,12],$
                                [21,17,23,21],$
                                [27,28,31,23],$
                                [32,37,38,36],$
                                [32,39,40,38],$
                                [32,39,40,38]]      
 
  tha_electron_dead_layer_dates = ['1970-01-01/00:00:00']
  tha_electron_dead_layer_offsets = [[0,0,0,0]] ;not actually assuming no dead layer.  Just no increase over the modeled channel.
 
 
  ;calibration factors from drew turner(dturner@igpp.ucla.edu, 2013-03-07)   
  thb_ion_dead_layer_dates = ['1970-01-01/00:00:00', $ ;sentinel(slightly abusing the term)
                          '2008-06-13/00:00:00', $ 
                          '2008-12-01/00:00:00', $
                          '2009-07-03/00:00:00', $
                          '2010-03-29/00:00:00', $
                          '2010-10-22/00:00:00', $
                          '2011-02-03/00:00:00', $
                          '2011-06-15/00:00:00', $
                          '2011-11-24/00:00:00', $
                          '2012-06-03/00:00:00']
                          
   
  ;angle columns as listed in array below are theta look directions -52,-25,25,52
  ;offsets are in keV                                                
  thb_ion_dead_layer_offsets = [[1e,2,4,2],$
                               [1,2,4,2],$
                               [1,2,4,2],$
                               [3,6,7,4],$
                               [4,8,9,6],$
                               [4,8,11,6],$
                               [5,8,11,6],$
                               [5,8,11,6],$
                               [5,8,11,6],$
                               [5,8,11,6],$
                               [5,20,15,7]]
                         
  thb_electron_dead_layer_dates = ['1970-01-01/00:00:00']
  thb_electron_dead_layer_offsets = [[0,0,0,0]]  ;not actually assuming no dead layer.  Just no increase over the modeled channel.
  
 ;calibration factors from drew turner(dturner@igpp.ucla.edu, 2013-03-07)   
  thc_ion_dead_layer_dates = ['1970-01-01/00:00:00', $ ;sentinel(slightly abusing the term)
                              '2008-07-01/00:00:00', $
                              '2008-12-20/00:00:00', $
                              '2009-06-26/00:00:00', $
                              '2009-12-30/00:00:00', $
                              '2010-07-17/00:00:00', $
                              '2011-02-01/00:00:00', $
                              '2011-08-14/00:00:00', $
                              '2012-03-08/00:00:00', $
                              '2012-08-15/00:00:00']
  
  ;angle columns as listed in array below are theta look directions -52,-25,25,52
  ;offsets are in keV                                    
  thc_ion_dead_layer_offsets = [[7e,7,4,1],$
                                [7,10,4,1],$
                                [7,12,5,3],$
                                [7,18,10,7],$
                                [7,22,12,7],$
                                [12,22,15,9],$
                                [12,22,15,9],$
                                [12,32,18,10],$
                                [12,34,19,10],$
                                [12,40,20,11]]
                                
                                
  thc_electron_dead_layer_dates = ['1970-01-01/00:00:00']
  thc_electron_dead_layer_offsets = [[0,0,0,0]] ;not actually assuming no dead layer.  Just no increase over the modeled channel.
  
  ;calibration factors from drew turner(dturner@igpp.ucla.edu, 2013-03-07)   
  thd_ion_dead_layer_dates = ['1970-01-01/00:00:00', $ ;sentinel(slightly abusing the term)
                              '2008-06-09/00:00:00', $
                              '2008-12-06/00:00:00', $
                              '2009-06-12/00:00:00', $
                              '2009-12-11/00:00:00', $
                              '2010-07-28/00:00:00', $
                              '2011-02-01/00:00:00', $
                              '2011-06-17/00:00:00', $
                              '2011-12-13/00:00:00', $
                              '2012-06-11/00:00:00']
   ;angle columns as listed in array below are theta look directions -52,-25,25,52
   ;offsets are in keV                               
   thd_ion_dead_layer_offsets = [[5e,6,10,4],$
                                 [5,6,10,4],$
                                 [6,8,12,4],$
                                 [6,11,12,5],$
                                 [6,11,14,5],$
                                 [6,11,14,5],$
                                 [15,25,27,11],$
                                 [19,25,27,15],$
                                 [20,25,29,16],$
                                 [23,28,31,16]]                         
  
  thd_electron_dead_layer_dates = ['1970-01-01/00:00:00']
  thd_electron_dead_layer_offsets = [[0,0,0,0]] ;not actually assuming no dead layer.  Just no increase over the modeled channel.
 
  the_ion_dead_layer_dates = ['1970-01-01/00:00:00', $ ;sentinel(slightly abusing 
                              '2008-06-09/00:00:00', $
                              '2008-12-06/00:00:00', $
                              '2009-06-12/00:00:00', $
                              '2009-12-11/00:00:00', $
                              '2010-07-28/00:00:00', $
                              '2011-02-01/00:00:00', $
                              '2011-06-09/00:00:00', $
                              '2011-12-05/00:00:00', $
                              '2012-07-12/00:00:00']
  ;angle columns as listed in array below are theta look directions -52,-25,25,52
  ;non-monotone angle order matches the order that the data are stored in the SST data structures
  ;offsets are in keV      
  the_ion_dead_layer_offsets = [[4e,3,4,9],$
                                [4,3,4,9],$
                                [4,3,4,9],$
                                [5,5,5,10],$
                                [5,5,5,10],$
                                [5,5,5,10],$
                                [5,17,12,11],$
                                [18,24,25,23],$
                                [20,28,33,26],$
                                [20,28,33,26]]
                                
  the_electron_dead_layer_dates = ['1970-01-01/00:00:00']
  the_electron_dead_layer_offsets = [[0,0,0,0]] ;not actually assuming no dead layer.  Just no increase over the modeled channel.
                               
  tha_ion_anode_intercalibration_dates=['1970-01-01/00:00:00']
  tha_ion_anode_intercalibrations=[[1e,1,1,1]]
  tha_electron_anode_intercalibration_dates=['1970-01-01/00:00:00']
  tha_electron_anode_intercalibrations=[[1e,1,1,1]]
 
  thb_ion_anode_intercalibration_dates=['1970-01-01/00:00:00']
  thb_ion_anode_intercalibrations=[[1e,1,1,1]]
  thb_electron_anode_intercalibration_dates=['1970-01-01/00:00:00']
  thb_electron_anode_intercalibrations=[[1e,1,1,1]]
 
  thc_ion_anode_intercalibration_dates=['1970-01-01/00:00:00']
  thc_ion_anode_intercalibrations=[[1e,1,1,1]]
  thc_electron_anode_intercalibration_dates=['1970-01-01/00:00:00']
  thc_electron_anode_intercalibrations=[[1e,1,1,1]]
 
  thd_ion_anode_intercalibration_dates=['1970-01-01/00:00:00']
  thd_ion_anode_intercalibrations=[[1e,1,1,1]]
  thd_electron_anode_intercalibration_dates=['1970-01-01/00:00:00']
  thd_electron_anode_intercalibrations=[[1e,1,1,1]]
 
  the_ion_anode_intercalibration_dates=['1970-01-01/00:00:00']
  the_ion_anode_intercalibrations=[[1e,1,1,1]]
  the_electron_anode_intercalibration_dates=['1970-01-01/00:00:00']
  the_electron_anode_intercalibrations=[[1e,1,1,1]]
 
  ;angle columns as listed in array below are -52,52,-25,25(note, these should be reordered in the future to an ascending order for clarity)           
  ;(1/d) : Using reciprocal of the factors provided from Drew Turner, 
  ;Since Drew's factors are multiplicative, but the calibration code accepts divisors.                  
;  tha_ion_anode_intercalibrations=1d/[[1.16,1.24,0.70,1.40],$
;                                   [0.97,1.24,0.90,1.05],$
;                                   [1.06,1.56,0.66,1.42],$
;                                   [1.20,1.29,0.63,1.53],$
;                                   [1.21,1.17,0.68,1.45],$
;                                   [0.96,0.84,0.84,1.60]]
;                                 
;                                   
;  tha_electron_anode_intercalibrations=1d/[[0.98,0.99,0.94,1.06],$
;                                        [1.01,0.99,1.08,0.95],$
;                                        [0.99,0.96,1.04,1.02],$
;                                        [0.95,1.01,1.08,0.98],$
;                                        [0.96,1.02,0.93,1.08],$
;                                        [0.94,0.99,0.96,1.13]]
;                                        
;  thb_anode_intercalibration_dates=['1970-01-01/00:00:00',$
;                                    '2007-12-12/00:00:00',$
;                                    '2009-05-01/00:00:00',$
;                                    '2010-11-01/00:00:00',$
;                                    '2011-07-01/00:00:00',$
;                                    '2011-10-01/00:00:00',$
;                                    '2012-07-01/00:00:00']
;   
;  thb_ion_anode_intercalibrations=1d/[[0.91,0.71,0.68,26.4],$
;                                   [0.98,0.87,0.95,1.14],$
;                                   [0.92,0.79,1.08,1.24],$
;                                   [0.48,0.83,1.68,1.90],$
;                                   [0.60,0.92,1.45,1.53],$
;                                   [0.67,0.76,1.62,1.35],$
;                                   [0.47,0.82,2.22,2.14]]
;  
;  sst_build_anode_plot,thb_anode_intercalibration_dates,1d/thb_ion_anode_intercalibrations,'thb_ion'
;                                        
;  thb_electron_anode_intercalibrations=1d/[[0.77,1.03,1.04,1.04],$
;                                        [0.88,1.13,0.95,1.07],$
;                                        [0.89,1.13,0.95,1.05],$
;                                        [0.47,1.97,1.28,1.10],$
;                                        [0.52,1.81,1.33,1.13],$
;                                        [0.52,1.81,1.33,1.13],$
;                                        [0.48,1.87,1.56,1.33]]
;      
;  sst_build_anode_plot,thb_anode_intercalibration_dates,1d/thb_electron_anode_intercalibrations,'thb_ele'
;      
;  thc_anode_intercalibration_dates=['1970-01-01/00:00:00',$
;                                    '2007-12-12/00:00:00',$
;                                    '2009-05-01/00:00:00',$
;                                    '2010-11-01/00:00:00',$
;                                    '2011-07-01/00:00:00',$
;                                    '2012-07-01/00:00:00']
;                                        
;  thc_ion_anode_intercalibrations=1d/[[9.31,0.30,6.30,3.09],$
;                                   [1.08,0.71,1.36,0.99],$
;                                   [1.09,0.66,2.08,0.94],$
;                                   [0.66,0.61,3.38,0.95],$
;                                   [0.55,0.53,11.03,2.33],$
;                                   [0.52,0.61,16.97,2.07]]
;                                   
;  sst_build_anode_plot,thc_anode_intercalibration_dates,1d/thc_ion_anode_intercalibrations,'thc_ion'
; 
;  thc_electron_anode_intercalibrations=1d/[[0.79,1.12,1.02,1.14],$
;                                        [0.87,1.18,0.93,1.08],$
;                                        [0.83,1.14,0.94,1.11],$
;                                        [0.42,1.37,1.53,1.30],$
;                                        [0.42,1.37,1.53,1.30],$
;                                        [0.49,1.97,1.45,1.53]]
;    
;  sst_build_anode_plot,thc_anode_intercalibration_dates,1d/thc_electron_anode_intercalibrations,'thc_ele'
;     
;  thd_anode_intercalibration_dates=['1970-01-01/00:00:00',$
;                                    '2007-12-12/00:00:00',$
;                                    '2009-05-01/00:00:00']
;                                        
;  thd_ion_anode_intercalibrations=1d/[[0.96,0.75,4.86,0.68],$
;                                   [0.99,0.77,1.00,1.28],$
;                                   [0.93,0.66,1.19,1.88]]
;                                   
;  thd_electron_anode_intercalibrations=1d/[[0.94,0.97,1.02,1.04],$
;                                        [0.91,1.08,0.96,1.05],$
;                                        [0.87,1.02,1.07,1.09]]
;                                        
;  the_anode_intercalibration_dates=['1970-01-01/00:00:00',$
;                                    '2007-12-12/00:00:00',$
;                                    '2008-05-01/00:00:00',$
;                                    '2009-05-01/00:00:00']
;                                   
;  the_ion_anode_intercalibrations=1d/[[1.00,1.31,0.88,0.89],$
;                                   [0.95,1.13,0.93,1.04],$
;                                   [0.85,1.02,0.97,1.09],$
;                                   [0.79,0.95,1.09,1.24]]     
;                                   
;  the_electron_anode_intercalibrations=1d/[[1.30,0.85,1.05,0.84],$
;                                        [1.05,0.82,1.29,0.97],$
;                                        [1.14,0.73,1.21,1.12],$
;                                        [1.06,0.71,1.27,1.20]]
; 
; angle_swap=[1,0,3,2] ;switch the order of the columns in the cal file to [52,-52,25,-25], to match the order of angles in actual SST data   
  
  ;;;;;;;;;;;;;;;;;;;;;;;;; New generation with dead layer offsets instead of anode intercalibrations 
  
  angle_swap = [3,0,2,1] ;permute from [-52,-25,25,52] to [52,-52,25,-25]
  
  ;PROBE A
  
  
  thm_sst_build_cal_files_helper,cal_file_root+'tha_psif_calib_params_v02.txt',$
                                 '#THA PSIF CALIBRATION FILE VERSION 2, see thm_sst_build_cal_files.pro for detailed descriptions of each parameter' ,$
                                 ion_open_en_low,ion_open_en_high,deadtime,gf_nominal,$
                                 tha_ion_anode_intercalibration_dates,tha_ion_anode_intercalibrations,$
                                 tha_ion_dead_layer_dates,tha_ion_dead_layer_offsets[angle_swap,*],$
                                 attenuator_correction,ion_open_mono_channel_efficiencies
  
 thm_sst_build_cal_files_helper,cal_file_root+'tha_psef_calib_params_v02.txt',$
                                 '#THA PSEF CALIBRATION FILE VERSION 2, see thm_sst_build_cal_files.pro for detailed descriptions of each parameter' ,$
                                 electron_foil_en_low,electron_foil_en_high,deadtime,gf_nominal,$
                                 tha_electron_anode_intercalibration_dates,tha_electron_anode_intercalibrations,$
                                 tha_electron_dead_layer_dates,tha_electron_dead_layer_offsets[angle_swap,*],$
                                 attenuator_correction,electron_foil_mono_channel_efficiencies
  ;PROBE B                                
 thm_sst_build_cal_files_helper,cal_file_root+'thb_psif_calib_params_v02.txt',$
                                 '#thb PSIF CALIBRATION FILE VERSION 2, see thm_sst_build_cal_files.pro for detailed descriptions of each parameter' ,$
                                 ion_open_en_low,ion_open_en_high,deadtime,gf_nominal,$
                                 thb_ion_anode_intercalibration_dates,thb_ion_anode_intercalibrations,$
                                 thb_ion_dead_layer_dates,thb_ion_dead_layer_offsets[angle_swap,*],$
                                 attenuator_correction,ion_open_mono_channel_efficiencies
  
 thm_sst_build_cal_files_helper,cal_file_root+'thb_psef_calib_params_v02.txt',$
                                 '#thb PSEF CALIBRATION FILE VERSION 2, see thm_sst_build_cal_files.pro for detailed descriptions of each parameter' ,$
                                 electron_foil_en_low,electron_foil_en_high,deadtime,gf_nominal,$
                                 thb_electron_anode_intercalibration_dates,thb_electron_anode_intercalibrations,$
                                 thb_electron_dead_layer_dates,thb_electron_dead_layer_offsets[angle_swap,*],$
                                 attenuator_correction,electron_foil_mono_channel_efficiencies
    ;PROBE C                              
 thm_sst_build_cal_files_helper,cal_file_root+'thc_psif_calib_params_v02.txt',$
                                 '#thc PSIF CALIBRATION FILE VERSION 2, see thm_sst_build_cal_files.pro for detailed descriptions of each parameter' ,$
                                 ion_open_en_low,ion_open_en_high,deadtime,gf_nominal,$
                                 thc_ion_anode_intercalibration_dates,thc_ion_anode_intercalibrations,$
                                 thc_ion_dead_layer_dates,thc_ion_dead_layer_offsets[angle_swap,*],$
                                 attenuator_correction,ion_open_mono_channel_efficiencies
  
 thm_sst_build_cal_files_helper,cal_file_root+'thc_psef_calib_params_v02.txt',$
                                 '#thc PSEF CALIBRATION FILE VERSION 2, see thm_sst_build_cal_files.pro for detailed descriptions of each parameter' ,$
                                 electron_foil_en_low,electron_foil_en_high,deadtime,gf_nominal,$
                                 thc_electron_anode_intercalibration_dates,thc_electron_anode_intercalibrations,$
                                 thc_electron_dead_layer_dates,thc_electron_dead_layer_offsets[angle_swap,*],$
                                 attenuator_correction,electron_foil_mono_channel_efficiencies
   ;PROBE D                               
 thm_sst_build_cal_files_helper,cal_file_root+'thd_psif_calib_params_v02.txt',$
                                 '#thd PSIF CALIBRATION FILE VERSION 2, see thm_sst_build_cal_files.pro for detailed descriptions of each parameter' ,$
                                 ion_open_en_low,ion_open_en_high,deadtime,gf_nominal,$
                                 thd_ion_anode_intercalibration_dates,thd_ion_anode_intercalibrations,$
                                 thd_ion_dead_layer_dates,thd_ion_dead_layer_offsets[angle_swap,*],$
                                 attenuator_correction,ion_open_mono_channel_efficiencies
  
 thm_sst_build_cal_files_helper,cal_file_root+'thd_psef_calib_params_v02.txt',$
                                 '#thd PSEF CALIBRATION FILE VERSION 2, see thm_sst_build_cal_files.pro for detailed descriptions of each parameter' ,$
                                 electron_foil_en_low,electron_foil_en_high,deadtime,gf_nominal,$
                                 thd_electron_anode_intercalibration_dates,thd_electron_anode_intercalibrations,$
                                 thd_electron_dead_layer_dates,thd_electron_dead_layer_offsets[angle_swap,*],$
                                 attenuator_correction,electron_foil_mono_channel_efficiencies
     ;PROBE E                             
 thm_sst_build_cal_files_helper,cal_file_root+'the_psif_calib_params_v02.txt',$
                                 '#the PSIF CALIBRATION FILE VERSION 2, see thm_sst_build_cal_files.pro for detailed descriptions of each parameter' ,$
                                 ion_open_en_low,ion_open_en_high,deadtime,gf_nominal,$
                                 the_ion_anode_intercalibration_dates,the_ion_anode_intercalibrations,$
                                 the_ion_dead_layer_dates,the_ion_dead_layer_offsets[angle_swap,*],$
                                 attenuator_correction,ion_open_mono_channel_efficiencies
  
 thm_sst_build_cal_files_helper,cal_file_root+'the_psef_calib_params_v02.txt',$
                                 '#the PSEF CALIBRATION FILE VERSION 2, see thm_sst_build_cal_files.pro for detailed descriptions of each parameter' ,$
                                 electron_foil_en_low,electron_foil_en_high,deadtime,gf_nominal,$
                                 the_electron_anode_intercalibration_dates,the_electron_anode_intercalibrations,$
                                 the_electron_dead_layer_dates,the_electron_dead_layer_offsets[angle_swap,*],$
                                 attenuator_correction,electron_foil_mono_channel_efficiencies
  
  
  dprint,'Calibration File Generation Completed',dlevel=2  ;dlevel 2 is informational message
            
end
                                                
   