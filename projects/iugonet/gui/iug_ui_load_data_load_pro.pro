;+
;NAME:
;  iug_ui_load_data_load_pro
;
;PURPOSE:
;  Modularized gui iugonet data loader
;
;HISTORY:
;$LastChangedBy: nikos $
;$LastChangedDate: 2018-08-01 11:03:38 -0700 (Wed, 01 Aug 2018) $
; 
;Modifications:
;A. Shinbori, 12/05/2010
;A. Shinbori, 10/07/2010
;A. Shinbori, 25/11/2010
;A. Shinbori, 01/11/2011
;A. Shinbori, 01/02/2012
;A. Shinbori, 04/02/2012
;A. Shinbori, 06/03/2012
;A. Shinbori, 12/04/2012
;Y.-M. Tanaka,15/06/2012
;A. Shinbori, 24/10/2012
;A. Shinbori, 14/12/2012
;A. Shinbori, 18/02/2013
;Y.-M. Tanaka, 16/08/2013
;A. Shinbori, 07/01/2014
;Y.-M. Tanaka, 05/02/2014
;-
;--------------------------------------------------------------------------------

pro iug_ui_load_data_load_pro,    $
                      loadStruc,          $
                      loadedData,         $
                      statusBar,          $
                      historyWin,         $
                      replay=replay,      $
                      overwrite_selections=overwrite_selections 
                         
  compile_opt hidden,idl2

  iug_init
  loaded = 0
  notryload = 0

  new_vars = ''
  Answer = ''
  par_names2=''

  ; retrieve parameters from structure
  instrument=loadStruc.instrumentText
  datatype=loadStruc.typeText
  site_or_param=loadStruc.paramText
  parameters=loadStruc.param2Text
  timeRange=loadStruc.timeRange

  tn_before = [tnames('*',create_time=cn_before)]
  
  ;=================================
  ;===== Load the IUGONET data =====
  ;=================================
  case instrument of 
      ;----- AllSky Imager Keograms -----;
      'AllSky_Imager_Keograms' : begin       
          iug_load_ask_nipr, site =site_or_param, wavelength=parameters, trange = timeRange
          par_names=tnames('nipr_ask_*')
      end

      ;----- Automatic Weather Station -----;
      'Automatic_Weather_Station' : begin       
          iug_load_aws_rish, site =site_or_param, trange = timeRange
          if (parameters[0] eq '*') then begin
             par_names=tnames('iug_aws_*')
          endif else begin
             par_names=tnames('iug_aws_*_'+parameters)
          endelse
      end

      ;----- Bandary Layer Radar -----;
      'Boundary_Layer_Radar' : begin          
          iug_load_blr_rish, site =site_or_param, parameter=parameters, trange = timeRange
          par_names=tnames('iug_blr_*')
      end

      ;----- EISCAT radar -----;
      'EISCAT_radar' : begin
	  case datatype of
              'Vi_E_vectors': begin
                  iug_load_eiscat_vief, site=site_or_param, trange = timeRange
              end
              else: begin
                  vns=strmid(datatype,0,3)
                  iug_load_eiscat, site=site_or_param, ydatatype=vns, trange = timeRange
              end
          endcase
          if parameters[0] eq '*' then begin
              par_names=tnames('eiscat_*')
          endif else begin
              par_names=tnames('eiscat_*_'+parameters)
          endelse
      end

      ;----- Equatorial Atmosphere Radar -----;
      'Equatorial_Atmosphere_Radar' : begin
          iug_load_ear, datatype = datatype, parameter = site_or_param, trange = timeRange
          if parameters[0] eq '*' then begin
              vns='*'
          endif else begin
              vns=parameters
          endelse
          case datatype of
              'troposphere': par_names=tnames('iug_ear_trop_'+vns)
              'e_region':  par_names=tnames('iug_ear_fai*_'+vns)
              'ef_region': par_names=tnames('iug_ear_fai*_'+vns)
              'v_region':  par_names=tnames('iug_ear_fai*_'+vns)
              'f_region':  par_names=tnames('iug_ear_fai*_'+vns)
          endcase
      end 
  
      ;----- geomagnetic field index ----;
      'geomagnetic_field_index' : begin
          case datatype of
              'ASY_index' : begin
                  if parameters[0] eq '*' then begin
                      vns=['asy','sym']
                  endif else begin
                      vns=parameters
                  endelse
                  for i=0, n_elements(vns)-1 do begin
                      iug_load_gmag_wdc, site=vns[i], trange=timeRange 
                  endfor
                  par_names=tnames('wdc_mag_*')        
              end
              'Dst_index': begin
                  vns='dst'
                  if parameters[0] eq '*' then begin
                      iug_load_gmag_wdc, site=vns, trange=timeRange
                  endif else begin
                      for i=0, n_elements(parameters)-1 do begin
                          iug_load_gmag_wdc, site=vns, trange=timeRange, level=parameters[i]
                      endfor
                  endelse
                  par_names=tnames('wdc_mag_'+vns+'*')
              end
              'AE_index': begin
                  vns='ae'
                  if parameters[0] eq '*' then begin
                      iug_load_gmag_wdc, site=vns, trange=timeRange, resolution='min'
                      iug_load_gmag_wdc, site=vns, trange=timeRange, resolution='hour'
                  endif else begin
                      for i=0, n_elements(parameters)-1 do begin
                          if parameters[i] eq 'min' then begin
                              vns2='final'
                              vns3='min'
                          endif else if parameters[i] eq 'hour' then begin
                              vns2='final'
                              vns3='hour'
                          endif else if parameters[i] eq 'prov_min' then begin
                              vns2='prov'
                              vns3='min'
                          endif else if parameters[i] eq 'prov_hour' then begin
                              vns2='prov'
                              vns3='hour'
                          endif
                          iug_load_gmag_wdc, site=vns, trange=timeRange, level=vns2, resolution=vns3
                      endfor
                  endelse
                  par_names=tnames('wdc_mag_'+vns+'*')  
              end
              'Wp_index': begin
                  vns='Wp'
                  iug_load_gmag_wdc, site=vns, trange=timeRange
                  par_names=tnames('wdc_mag_'+vns+'*')
              end
          endcase
      end

      ;----- geomagnetic field fluxgate ----;
      'geomagnetic_field_fluxgate' : begin
          case datatype of
              'icswse' : begin
                  iug_load_gmag_icswse_iaga, trange = timeRange, site = site_or_param, resolution = parameters
                  par_names=tnames('kyumag_mag_*') 
              end
              'magdas#' : begin
                  erg_load_gmag_magdas_1sec, trange = timeRange, site = site_or_param
                  par_names=tnames('magdas_mag_*') 
              end 
              '210mm#' : begin
                  erg_load_gmag_mm210, trange = timeRange, site = site_or_param, datatype = parameters 
                  par_names=tnames('mm210_mag_*')
              end
              'ISEE#' : begin
                  erg_load_gmag_isee_fluxgate, trange = timeRange, site = site_or_param, datatype = parameters 
                  par_names=tnames('isee_fluxgate_mag_*')
              end
              'WDC_kyoto' : begin
                  if parameters[0] eq '*' then begin
                      vns=['min', 'hour']
                  endif else begin
                      vns=parameters
                  endelse
                  for i=0, n_elements(vns)-1 do begin
                      iug_load_gmag_wdc, trange=timeRange, site = site_or_param, resolution=vns[i]
                  endfor
                  par_names=tnames('wdc_mag_*')
              end
              'NIPR#' : begin
                  iug_load_gmag_nipr, trange=timeRange, site = site_or_param, datatype = parameters
                  par_names=tnames('nipr_mag_*')
              end
          endcase
      end

      ;----- geomagnetic field induction ----;
      'geomagnetic_field_induction' : begin
          trd=time_double(timeRange)
          tssec=trd[1]-trd[0]
          if tssec gt 86400 then begin
              notryload=1
          endif else begin
              case datatype of
                  'NIPR#' : begin
                      iug_load_gmag_nipr_induction, trange=timeRange, site = site_or_param
                      par_names=tnames('nipr_imag_*')
                  end
                  'ISEE#' : begin
                      erg_load_gmag_isee_induction, trange = timeRange, site = site_or_param
                      par_names=tnames('isee_induction_*')
                  end
              endcase
          endelse
      end

      ;----- GPS_Radio_Occultation_CHAMP ----;
      'GPS_radio_occultation' : begin
        iug_load_gps_ro_rish, site = site_or_param, trange = timeRange
        if parameters[0] eq '*' then begin
          par_names=tnames('gps_ro_*_fsi_*')
        endif else begin
          par_names=tnames('gps_ro_*_fsi_'+parameters)
        endelse
      end


      ;----- HF_Solar_Jupiter_radio_spectrometer ----;
      'HF_Solar_Jupiter_radio_spectrometer' : begin

          print, site_or_param
          print, parameters

          iug_load_hf_tohokuu, site=site_or_param, trange = timeRange
          if parameters[0] eq '*' then begin
              par_names=tnames('iug_*_hf_*')
          endif else begin
              par_names=tnames('iug_*_hf_'+strupcase(parameters))
          endelse
      end

      ;----- IPRT ----;
      'Iitate_Planetary_Radio_Telescope' : begin       
          iug_load_iprt, datatype=datatype, trange = timeRange
          if parameters[0] eq '*' then begin
              par_names=tnames('iprt_*')
          endif else begin
              par_names=tnames('iprt_sun_'+strupcase(parameters))
          endelse
      end

      ;----- Imaging_Riometer ----;
      'Imaging_Riometer' : begin
          freq=strmid(datatype,0,2)
          iug_load_irio_nipr, site=site_or_param, datatype=freq, /keogram, trange = timeRange
          if parameters[0] eq '*' then begin
              par_names=tnames('nipr_irio*_*_cna_*')
          endif else begin
              par_names=tnames('nipr_irio*_*_cna_'+parameters)
          endelse
      end

      ;----- Ionosonde -----;
      'Ionosonde' : begin       
          iug_load_ionosonde_rish, site =site_or_param, trange = timeRange,/fixed_freq
          if (parameters[0] eq '*') then begin
                par_names=tnames('iug_ionosonde_sgk_freq_*')
           endif else begin
                par_names=tnames('iug_ionosonde_sgk_freq_'+parameters)
           endelse
      end

      ;----- Lower Troposphere Radar -----;
      'Lower_Troposphere_Radar' : begin       
          iug_load_ltr_rish, site =site_or_param, parameter=parameters, trange = timeRange
          par_names=tnames('iug_ltr_*')
      end

      ;----- Lower Troposphere Radar -----;
      'Low_Frequency_radio_transmitter' : begin       
          iug_load_lfrto, site = datatype, trans = site_or_param, parameter = parameters, $
              trange = timeRange
          if parameters[0] eq '*' then begin
              par_names=tnames('lfrto_'+datatype+'_*_*')
          endif else begin
              par_names=tnames('lfrto_'+datatype+'_*_'+strmid(parameters,0,3)+'*')
          endelse
      end

      ;----- Medium Frequency radar -----;
      'Medium_Frequency_radar' : begin
          iug_load_mf_rish, site =site_or_param, trange = timeRange 
          if parameters[0] eq '*' then begin
              par_names=tnames('iug_mf_*')
          endif else begin
              par_names=tnames('iug_mf_*_'+parameters)
          endelse
      end

      ;----- Meteor Wind radar -----;
      'Meteor_Wind_radar' : begin
          iug_load_meteor_rish, site=site_or_param, parameter=parameters, trange=timeRange
          par_names=tnames('iug_meteor_*')
      end

      ;----- Middle Upper atmosphere radar -----;
      'Middle_Upper_atmosphere_radar' : begin
         case datatype of
           'troposphere': begin
               iug_load_mu, datatype =datatype, trange = timeRange
               if parameters[0] eq '*' then begin
                  vns='*'
               endif else begin
                  vns=parameters
               endelse
               par_names=tnames('iug_mu_trop_'+vns)
            end
           'mesosphere': begin
               iug_load_mu, datatype =datatype, level = site_or_param, trange = timeRange
               if parameters[0] eq '*' then begin
                  vns='*'
               endif else begin
                  vns=parameters
               endelse
               par_names=tnames('iug_mu_meso_'+vns+'_*')
            end
           'ionosphere': begin
               iug_load_mu, datatype =datatype, trange = timeRange
               if parameters[0] eq '*' then begin
                  vns='*'
               endif else begin
                  vns=parameters
               endelse
               par_names=tnames('iug_mu_iono_'+vns)
            end  
           'meteor': begin
               iug_load_mu, datatype = datatype, parameter = parameters, trange = timeRange
               if parameters[0] eq '*' then begin
                  vns='*'
               endif else begin
                  vns=parameters
               endelse
               par_names=tnames('iug_mu_meteor_*_'+vns)
            end 
           'rass': begin
               iug_load_mu, datatype = datatype, parameter = parameters, trange = timeRange
               if parameters[0] eq '*' then begin
                  vns='*'
               endif else begin
                  vns=parameters
               endelse
               par_names=tnames('iug_mu_rass_'+vns)
            end   
           'fai': begin
               iug_load_mu, datatype = datatype, parameter = site_or_param, trange = timeRange
               if parameters[0] eq '*' then begin
                  vns='*'
               endif else begin
                  vns=parameters
               endelse
               par_names=tnames('iug_mu_fai_*_'+vns)
            end 
         endcase     
      end

      ;----- Radiosonde -----;
      'Radiosonde' : begin       
          iug_load_radiosonde_rish, datatype =datatype, site =site_or_param, trange = timeRange
          if parameters[0] eq '*' then begin
              par_names=tnames('iug_radiosonde_*')
          endif else begin
              par_names=tnames('iug_radiosonde_*_'+parameters)
          endelse
      end
      
      ;----- SuperDARN radar ----;
      'SuperDARN_radar#' : begin
          if site_or_param[0] eq '*(all)' then begin
              notryload=1
          endif else begin
              erg_load_sdfit, trange=timeRange, sites=site_or_param

              ;Delete the tplot variables not allowed on the GUI:
              store_data, 'sd_*_position_tbl_*',/delete
              store_data, 'sd_*_positioncnt_tbl_*',/delete
              store_data, 'sd_*_veast_bothscat_*',/delete
              store_data, 'sd_*_vnorth_bothscat_*',/delete
              store_data, 'sd_*_vlos_bothscat_*',/delete
    
              if parameters[0] eq '*' then begin
                  par_names=tnames('sd_*')
              endif else begin
                  par_names=tnames('sd_*_' + parameters +'_?')
              endelse
          endelse
      end
  
      ;----- Wind Profiler Radar (LQ-7) -----;
      'Wind_Profiler_Radar_(LQ-7)' : begin       
          iug_load_wpr_rish, site =site_or_param, parameter=parameters, trange = timeRange
          par_names=tnames('iug_wpr_*')
      end

  endcase

  ;----- Clean up tplot -----;  
  spd_ui_cleanup_tplot,tn_before,create_time_before=cn_before,del_vars=to_delete,new_vars=new_vars

  if new_vars[0] ne '' then begin
      ;----- only add the requested new parameters -----;
      new_vars = ssl_set_intersection([par_names],[new_vars])

      if size(new_vars[0], /type) eq 7 then begin
          loaded = 1
    
          ;----- loop over loaded data -----;
          for i = 0,n_elements(new_vars)-1 do begin

              ;----- In case of more than two observatoies -----;
              site_name=strsplit(new_vars[i],'_',/extract)
              if (instrument eq 'Iitate_Planetary_Radio_Telescope') or (instrument eq 'SuperDARN_radar#') or $
                  (instrument eq 'EISCAT_radar') or (instrument eq 'HF_Solar_Jupiter_radio_spectrometer') then begin
                  site_name2 = site_name[1]
              endif else if (instrument eq 'geomagnetic_field_fluxgate') and $
                  (datatype eq 'ISEE#') then begin
                  site_name2 = site_name[3]
              endif else if (instrument eq 'geomagnetic_field_induction') and $
                  (datatype eq 'ISEE#') then begin
                  site_name2 = site_name[4]
              endif else if (instrument eq 'Middle_Upper_atomosphere_radar') then begin
                  if n_elements(site_name) eq 5 then begin 
                     if site_name[4] eq 'org' then site_name2 = 'meso(org)'
                     if site_name[4] eq 'scr' then site_name2 = 'meso(scr)'
                  endif else begin
                     site_name2 = site_name[2]
                  endelse
              endif else begin
                  site_name2 = site_name[2]
              endelse

              ;----- Show data policy -----;
              Answer = gui_acknowledgement(instrument=instrument, datatype=datatype, $
                  site_or_param=site_name2, par_names=new_vars[i])

              if Answer eq 'OK' then begin
                  ;----- Add the time clip of tplot variable between start and end times -----;   
                  trange = timeRange
                  time_clip, new_vars[i],trange[0],trange[1],/replace 

                  result = loadedData->add(new_vars[i],mission='IUGONET',observatory=instrument, instrument=site_name2)
        
                  if ~result then begin
                      statusBar->update,'Error loading: ' + new_vars[i]
                      historyWin->update,'IUGONET: Error loading: ' + new_vars[i]
                      return
                  endif
              endif else begin
                  break
              endelse
          endfor
      endif
  endif 
  
  if n_elements(to_delete) gt 0 && is_string(to_delete) then begin
    store_data,to_delete,/delete
  endif
                                     
  if (loaded eq 1) and (Answer eq 'OK') then begin     
     statusBar->update,'IUGONET Data Loaded Successfully'
     historyWin->update,'IUGONET Data Loaded Successfully'
  endif else if (loaded eq 1) and (Answer eq 'Cancel') then begin     
     statusBar->update,'You must accept the rules of the load for IUGONET data before you load and plot the data.'
     historyWin->update,'You must accept the rules of the load for IUGONET data before you load and plot the data.'
  endif else if (notryload eq 1) and (instrument eq 'SuperDARN_radar#') then begin
     statusBar->update,'SuperDARN radar does not support *(all) as a site or parameter(s)-1. Please select others.'
     historyWin->update,'SuperDARN radar does not support *(all) as a site or parameter(s)-1. Please select others.'      
  endif else if (notryload eq 1) and (instrument eq 'geomagnetic_field_induction') then begin
     statusBar->update,'Time range for induction magnetometer must be less than 24 hours.'
     historyWin->update,'Time range for induction magnetometer must be less than 24 hours.'      
  endif else begin
     statusBar->update,'No IUGONET Data Loaded.  Data may not be available during this time interval.'
     historyWin->update,'No IUGONET Data Loaded.  Data may not be available during this time interval.' 
  endelse

end
