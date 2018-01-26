;+
; NAME: mvn_euv_ionization
; SYNTAX: 
;       structure = mvn_euv_ionization(fismdata)
;       
; PURPOSE:
;       calculates ionization frequencies for six major species in the
;       Martian atmosphere
;
; ARGUMENTS:
;     fismdata is the structure produced when the procedure
;     get_data.pro is used To retrieve data from the tplot variable
;     'mvn_euv_l3_y'
;
; RETURNS:
;     a data structure containing ionization frequencies of the six
;     major species: CO2, O2, O, CO, N2, Ar according to the
;         photoionization cross-sections from the SwRI database:
;         http://phidrates.space.swri.edu/ 

; need a really simple integrator, should work the same way as
; int_tabulated
function int_simple, x, f, df = df, dx = dx, error= error
  nx = n_elements (x)
  deltax = x [1:*] -x [0: nx -2]
  area =  deltax*0.5*(f [1:*] +f [0: nx -2])
  
  if keyword_set (df) or keyword_set (dx) then begin
     if not keyword_set (df) then df = fltarr(nx)
     if not keyword_set (dx) then dx = fltarr(nx)

     integral = 0
     error = 0.0
     for K = 1, nx-1 do begin
        fterm = 0.5*(f[k-1] + f[k])
        xterm = x[k] - x[k-1]
        ferr = 0.5*sqrt(df[k-1]^2 + df[k]^2)
        xerr = sqrt(dx[k-1]^2 + dx[k]^2)
        z = xterm*fterm
        zerr = abs(z)*sqrt((xerr/xterm)^2 + (ferr/fterm)^2)
        integral = integral + z
        error = sqrt(error^2.0 + zerr^2)
     endfor
     return, integral
  endif else return,  total (area,/nan)
end


function mvn_euv_ionization,fismdata, photo = photo, no_tplot = no_tplot
  
  ndw = size (fismdata.v,/n_dimensions)
  if ndw eq 1 then wavelength = reform(fismdata.v) else if $
     ndw eq 2 then wavelength = reform(fismdata.v[0,*])
  if not keyword_set (photo) then begin
     path = FILE_DIRNAME(ROUTINE_FILEPATH('mvn_euv_l3_load'), /mark)
     Cross_section_file = path + 'photon_cross_sections.sav'
     
                                ;print, 'Loading cross-section file...'
     restore, cross_section_file
  endif
                                ;print, 'Done.'
  
  CO2_CO2plus_index = where(photo.CO2.process eq 'CO2 CO2+')
  CO2_O_COplus_index = where(photo.CO2.process eq 'CO2 CO+O')
  CO2_CO_Oplus_index = where(photo.CO2.process eq 'CO2 O+CO')
  CO2_O2_Cplus_index = where(photo.CO2.process eq 'CO2 C+O2')
;sCO is the (singlet) ground state of CO
  CO2_sCO_O1D_index = where(photo.CO2.process eq 'sCO/O1D')
  CO2_sCO_O_index = where(photo.CO2.process eq 'sCO/O')
;tCO is the (Triplet) a^3Pi state of CO
  CO2_tCO_O_index = where(photo.CO2.process eq 'tCO/O')

  CO2_ionization_xsection = $
     reform (interpol(photo.CO2.xsection[CO2_CO2plus_index,*]+ $
                      photo.CO2.xsection[CO2_O_COplus_index,*]+ $
                      photo.CO2.xsection[CO2_CO_Oplus_index,*]+ $
                      photo.CO2.xsection[CO2_O2_Cplus_index,*],$
                      photo.Angstroms*0.1, $
                      wavelength))
  CO2_CO2plus_xsection = $
     reform (interpol(photo.CO2.xsection[CO2_CO2plus_index,*], $
                       photo.Angstroms*0.1, $
                      wavelength))
  CO2_O_COplus_xsection = $
     reform (interpol(photo.CO2.xsection[CO2_O_COplus_index,*], $
                      photo.Angstroms*0.1, $
                      wavelength))
  CO2_CO_Oplus_xsection = $
     reform (interpol(photo.CO2.xsection[CO2_CO_Oplus_index,*], $
                      photo.Angstroms*0.1, $
                      wavelength))
  CO2_O2_Cplus_xsection = $
     reform (interpol(photo.CO2.xsection[CO2_O2_Cplus_index,*], $
                      photo.Angstroms*0.1, $
                      wavelength))

  CO2_sCO_O1D_xsection = $
     reform (interpol(photo.CO2.xsection[CO2_sCO_O1D_index,*], $
                      photo.Angstroms*0.1, $
                      wavelength))

  CO2_sCO_O_xsection = $
     reform (interpol(photo.CO2.xsection[CO2_sCO_O_index,*], $
                      photo.Angstroms*0.1, $
                      wavelength))

  CO2_tCO_O_xsection = $
     reform (interpol(photo.CO2.xsection[CO2_tCO_O_index,*], $
                      photo.Angstroms*0.1, $
                      wavelength))

  
  O_ionization_process_index = where(photo.O3P.process eq 'O3P O+')
  O_ionization_xsection = $
     reform (interpol(photo.O3P.xsection[O_ionization_process_index,*], $
                      photo.Angstroms*0.1, $
                      wavelength))

  AR_ionization_process_index = where(photo.AR.process eq 'Ar Ar+')
  AR_ionization_xsection = $
     reform (interpol(photo.AR.xsection[AR_ionization_process_index,*], $
                      photo.Angstroms*0.1, $
                      wavelength))

  O2_O2plus_index = where(photo.O2.process eq 'O2 O2+')
  O2_O_Oplus_index = where(photo.O2.process eq 'O2 O+O')
  O2_O_O_index = where(photo.O2.process eq 'O2 O/O')
  O2_O_O1D_index = where(photo.O2.process eq 'O2 O/O1D')
  O2_O_Oplus_index = where(photo.O2.process eq 'O2 O1S/O1S')
  
  O2_ionization_xsection = $
     reform (interpol(photo.O2.xsection[O2_O2plus_index,*]+$
                      photo.O2.xsection[O2_O_Oplus_index,*],$
                      photo.Angstroms*0.1, $
                      wavelength))
  O2_O2plus_xsection= $
     reform (interpol(photo.O2.xsection[O2_O2plus_index,*], $
                      photo.Angstroms*0.1, $
                      wavelength))
  O2_O_Oplus_xsection= $
     reform (interpol(photo.O2.xsection[O2_O_Oplus_index,*], $
                      photo.Angstroms*0.1, $
                      wavelength))
 O2_O_O_xsection= $
     reform (interpol(photo.O2.xsection[O2_O_O_index,*], $
                      photo.Angstroms*0.1, $
                      wavelength))
 O2_O_O1D_xsection= $
     reform (interpol(photo.O2.xsection[O2_O_O1D_index,*], $
                      photo.Angstroms*0.1, $
                      wavelength))
 O2_O1S_O1S_xsection= $
     reform (interpol(photo.O2.xsection[O2_O1S_O1S_index,*], $
                      photo.Angstroms*0.1, $
                      wavelength))

  N2_N2plus_index = where(photo.N2.process eq 'N2 N2+')
  N2_N_Nplus_index = where(photo.N2.process eq 'N2 N+N')
  N2_N_N_index = where(photo.N2.process eq 'N2 N/N')
  N2_ionization_xsection = reform (interpol(photo.N2.xsection[N2_N2plus_index,*]+$
                                            photo.N2.xsection[N2_N_Nplus_index,*],$
                                            photo.Angstroms*0.1, $
                                            wavelength))
  N2_N2plus_xsection= $
     reform (interpol(photo.N2.xsection[N2_N2plus_index,*], $
                      photo.Angstroms*0.1, $
                      wavelength))
  N2_N_Nplus_xsection= $
     reform (interpol(photo.N2.xsection[N2_N_Nplus_index,*], $
                      photo.Angstroms*0.1, $
                      wavelength))
  N2_N_N_xsection= $
     reform (interpol(photo.N2.xsection[N2_N_N_index,*], $
                      photo.Angstroms*0.1, $
                      wavelength))


  CO_COplus_index = where(photo.CO.process eq 'CO CO+')
  CO_C_Oplus_index = where(photo.CO.process eq 'CO O+C')
  CO_O_Cplus_index = where(photo.CO.process eq 'CO C+O')
  CO_C3P_O3P_index = where (photo.CO.process eq 'CO C/O')
  CO_C1D_O1D_index = where (photo.CO.process eq 'CO C1D/O1D')
  
  CO_ionization_xsection = reform (interpol(photo.CO.xsection[CO_COplus_index,*]+$
                                            photo.CO.xsection[CO_C_Oplus_index,*]+$
                                            photo.CO.xsection[CO_O_Cplus_index,*],$
                                            photo.Angstroms*0.1, $
                                            wavelength))
  CO_COplus_xsection = $
     reform (interpol(photo.CO.xsection[CO_COplus_index,*], $
                      photo.Angstroms*0.1, $
                      wavelength))
  CO_C_Oplus_xsection = $
     reform (interpol(photo.CO.xsection[CO_C_Oplus_index,*], $
                      photo.Angstroms*0.1, $
                      wavelength))
  CO_O_Cplus_xsection = $
     reform (interpol(photo.CO.xsection[CO_O_Cplus_index,*], $
                      photo.Angstroms*0.1, $
                      wavelength))
  CO_C3P_O3P_xsection = $
     reform (interpol(photo.CO.xsection[CO_C3P_O3P_index,*], $
                      photo.Angstroms*0.1, $
                      wavelength))
  CO_C1D_O1D_xsection = $
     reform (interpol(photo.CO.xsection[CO_C1D_O1D_index,*], $
                      photo.Angstroms*0.1, $
                      wavelength))
  
  
  ntimes = n_elements (fismdata.x)
  ionization_frequency_CO2 = fltarr(ntimes)
  CO2_CO2plus_frequency = fltarr(ntimes)
  CO2_O_COplus_frequency = fltarr(ntimes)
  CO2_CO_Oplus_frequency = fltarr(ntimes)
  CO2_O2_Cplus_frequency = fltarr(ntimes)
  CO2_sCO_O1D_frequency = fltarr(ntimes)
  CO2_sCO_O_frequency = fltarr(ntimes)
  CO2_tCO_O_frequency = fltarr(ntimes)

  CO_C3P_O3P_frequency = fltarr(ntimes)
  CO_C1D_O1D_frequency = fltarr(ntimes)

  ionization_frequency_CO = fltarr(ntimes)
  CO_COplus_frequency = fltarr(ntimes)
  CO_C_Oplus_frequency = fltarr(ntimes)
  CO_O_Cplus_frequency = fltarr(ntimes)
  
  ionization_frequency_O = fltarr(ntimes)
  
  ionization_frequency_O2 = fltarr(ntimes)
  O2_O2plus_frequency = fltarr(ntimes)
  O2_O_Oplus_frequency = fltarr(ntimes)
  O2_O_O_frequency = fltarr(ntimes)
  O2_O_O1D_frequency = fltarr(ntimes)
  O2_O1S_O1S_frequency = fltarr(ntimes)
  
  ionization_frequency_N2 = fltarr(ntimes)
  N2_N2plus_frequency = fltarr(ntimes)
  N2_N_N_frequency = fltarr(ntimes)
  
  ionization_frequency_Ar = fltarr(ntimes)

  plank_constant = 6.6d-34      ; standard units
  speed_light = 2.99D8          ; standard units
  
  
  print, 'Calculating ionization frequencies...'
  
  for K = 0, nTIMES-1 do begin 
; photons per square centimeter per second per nm
     photon_flux = 1e-4*reform (FISMDATA.y[k,*])*(1e-9*wavelength)/$
                   (plank_constant*speed_light)
; ionizations per second per nm
     diff_ionization_frequency_CO2 = CO2_ionization_xsection*photon_flux 
     diff_CO2_CO2plus_frequency = CO2_CO2plus_xsection*photon_flux 
     diff_CO2_O_COplus_frequency = CO2_O_COplus_xsection*photon_flux 
     diff_CO2_CO_Oplus_frequency = CO2_CO_Oplus_xsection*photon_flux 
     diff_CO2_O2_Cplus_frequency = CO2_O2_Cplus_xsection*photon_flux 
     diff_CO2_sCO_O1D_frequency = CO2_sCO_O1D_xsection*photon_flux 
     diff_CO2_sCO_O_frequency = CO2_sCO_O_xsection*photon_flux 
     diff_CO2_tCO_O_frequency = CO2_tCO_O_xsection*photon_flux 
     
     diff_ionization_frequency_CO = CO_ionization_xsection*photon_flux 
     diff_CO_COplus_frequency = CO_COplus_xsection*photon_flux 
     diff_CO_C_Oplus_frequency = CO_C_Oplus_xsection*photon_flux 
     diff_CO_O_Cplus_frequency = CO_O_Cplus_xsection*photon_flux 
     diff_CO_C3P_O3P_frequency = CO_C3P_O3P_xsection*photon_flux 
     diff_CO_C1D_O1D_frequency = CO_C1D_O1D_xsection*photon_flux 
    
     diff_ionization_frequency_O2 = O2_ionization_xsection*photon_flux 
     diff_O2_O2plus_frequency = O2_O2plus_xsection*photon_flux 
     diff_O2_O_Oplus_frequency = O2_O_Oplus_xsection*photon_flux      
     diff_O2_O_O_frequency = O2_O_O_xsection*photon_flux      
     diff_O2_O_O1D_frequency = O2_O_O1D_xsection*photon_flux      
     diff_O2_O1S_O1S_frequency = O2_O1S_O1S_xsection*photon_flux      
     
     diff_ionization_frequency_N2 = N2_ionization_xsection*photon_flux
     diff_N2_N2plus_frequency = N2_N2plus_xsection*photon_flux 
     diff_N2_N_Nplus_frequency = N2_N_Nplus_xsection*photon_flux 
     diff_N2_N_N_frequency = N2_N_N_xsection*photon_flux 
     
     diff_ionization_frequency_O = O_ionization_xsection*photon_flux 
     diff_ionization_frequency_Ar = Ar_ionization_xsection*photon_flux 
; total radiance over the appropriate wavelength range
     ionization_frequency_CO2[k] = $
        int_Simple (wavelength, $
                    diff_ionization_frequency_CO2)
     CO2_CO2plus_frequency[k] = int_Simple (wavelength, diff_CO2_CO2plus_frequency)
     CO2_O_COplus_frequency[k] = int_Simple (wavelength, diff_CO2_O_COplus_frequency)
     CO2_CO_Oplus_frequency[k] = int_Simple (wavelength, diff_CO2_CO_Oplus_frequency)
     CO2_O2_Cplus_frequency[k] = int_Simple (wavelength, diff_CO2_O2_Cplus_frequency)
     CO2_sCO_O1D_frequency[k] = int_Simple (wavelength, diff_CO2_sCO_O1D_frequency)
     CO2_sCO_O_frequency[k] = int_Simple (wavelength, diff_CO2_sCO_O_frequency)
     CO2_tCO_O_frequency[k] = int_Simple (wavelength, diff_CO2_tCO_O_frequency)


     ionization_frequency_CO[k] = int_Simple (wavelength, diff_ionization_frequency_CO)
     CO_COplus_frequency[k] = int_Simple (wavelength, diff_CO_COplus_frequency)
     CO_C_Oplus_frequency[k] = int_Simple (wavelength, diff_CO_C_Oplus_frequency)
     CO_O_Cplus_frequency[k] = int_Simple (wavelength, diff_CO_O_Cplus_frequency)
     CO_C3P_O3P_frequency[k] = int_Simple (wavelength, diff_CO_C3P_O3P_frequency)
     CO_C1D_O1D_frequency[k] = int_Simple (wavelength, diff_CO_C1D_O1D_frequency)
    
     
     ionization_frequency_O2[k] = $
        int_Simple (wavelength, diff_ionization_frequency_O2)
     O2_O2plus_frequency[k] = int_Simple (wavelength, diff_O2_O2plus_frequency)
     O2_O_Oplus_frequency[k] = int_Simple (wavelength, diff_O2_O_Oplus_frequency)
     O2_O_O_frequency[k] = int_Simple (wavelength, diff_O2_O_O_frequency)
     O2_O_O1D_frequency[k] = int_Simple (wavelength, diff_O2_O_O1D_frequency)
     O2_O1S_O1S_frequency[k] = int_Simple (wavelength, diff_O2_O1S_O1S_frequency)
     
     ionization_frequency_N2[k] = $
        int_Simple (wavelength, diff_ionization_frequency_N2)
     N2_N2plus_frequency[k] = int_Simple (wavelength, diff_N2_N2plus_frequency)
     N2_N_Nplus_frequency[k] = int_Simple (wavelength, diff_N2_N_Nplus_frequency)
     N2_N_N_frequency[k] = int_Simple (wavelength, diff_N2_N_N_frequency)
     
     ionization_frequency_O[k] = int_Simple (wavelength,diff_ionization_frequency_O)
     
     ionization_frequency_Ar[k] = int_Simple (wavelength, diff_ionization_frequency_Ar)
  endfor 
  print, 'Done'
  if not keyword_set(no_tplot) then begin
     store_data, 'ionization_frequency_CO2', $
                 Data = {x:fismdata.x, y:ionization_frequency_CO2},$
                 dlimits={ytitle:'CO2 Ionization !c Frequency, #/s'}
     store_data, 'CO2_CO2plus_frequency', $
                 Data = {x:fismdata.x, y:CO2_CO2plus_frequency},$
                 dlimits={ytitle:'CO2 -> CO2+ !c Frequency, #/s'}
     store_data, 'CO2_O_COplus_frequency', $
                 Data = {x:fismdata.x, y:CO2_O_COplus_frequency},$
                 dlimits={ytitle:'CO2 -> O, CO+ !c Frequency, #/s'}
     store_data, 'CO2_CO_Oplus_frequency', $
                 Data = {x:fismdata.x, y:CO2_CO_Oplus_frequency},$
                 dlimits={ytitle:'CO2 -> CO, O+ !c Frequency, #/s'}
     store_data, 'CO2_O2_Cplus_frequency', $
                 Data = {x:fismdata.x, y:CO2_O2_Cplus_frequency},$
                 dlimits={ytitle:'CO2 -> O2, C+!c Frequency, #/s'}
     store_data, 'CO2_sCO_O1D_frequency', $
                 Data = {x:fismdata.x, y:CO2_O2_Cplus_frequency},$
                 dlimits={ytitle:'CO2 -> sCO, O1D!c Frequency, #/s'}
     store_data, 'CO2_sCO_O_frequency', $
                 Data = {x:fismdata.x, y:CO2_O2_Cplus_frequency},$
                 dlimits={ytitle:'CO2 -> sCO, O!c Frequency, #/s'}
     store_data, 'CO2_tCO_O_frequency', $
                 Data = {x:fismdata.x, y:CO2_O2_Cplus_frequency},$
                 dlimits={ytitle:'CO2 -> tCO, O!c Frequency, #/s'}

     store_data, 'ionization_frequency_CO', Data = {x:fismdata.x, y:ionization_frequency_CO},$
                 dlimits={ytitle:'CO Ionization !c Frequency, #/s'}
     
     store_data, 'CO_COplus_frequency', $
                 Data = {x:fismdata.x, y:CO_COplus_frequency},$
                 dlimits={ytitle:'CO -> CO+ !c Frequency, #/s'}
     store_data, 'CO_C_Oplus_frequency', $
                 Data = {x:fismdata.x, y:CO_C_Oplus_frequency},$
                 dlimits={ytitle:'CO -> C, O+ !c Frequency, #/s'}
     store_data, 'CO_O_Cplus_frequency', $
                 Data = {x:fismdata.x, y:CO_O_Cplus_frequency},$
                 dlimits={ytitle:'CO -> O, C+ !c Frequency, #/s'}
     store_data, 'CO_C3P_O3P_frequency', $
                 Data = {x:fismdata.x, y:CO_C3P_O3P_frequency},$
                 dlimits={ytitle:'CO -> O3P, C3P !c Frequency, #/s'}
     store_data, 'CO_C1D_O1D_frequency', $
                 Data = {x:fismdata.x, y:CO_C1D_O1D_frequency},$
                 dlimits={ytitle:'CO -> O1D, C1D !c Frequency, #/s'}
     
     store_data, 'ionization_frequency_O2', Data = {x:fismdata.x, y:ionization_frequency_O2},$
                 dlimits={ytitle:'O2 Ionization !c Frequency, #/s'}
     store_data, 'O2_O2plus_frequency', $
                 Data = {x:fismdata.x, y:O2_O2plus_frequency},$
                 dlimits={ytitle:'O2 -> O2+ !c Frequency, #/s'}
     store_data, 'O2_O_Oplus_frequency', $
                 Data = {x:fismdata.x, y:O2_O_Oplus_frequency},$
                 dlimits={ytitle:'O2 -> O, O+ !c Frequency, #/s'}
     store_data, 'O2_O_O_frequency', $
                 Data = {x:fismdata.x, y:O2_O_O_frequency},$
                 dlimits={ytitle:'O2 -> O, O !c Frequency, #/s'}
     store_data, 'O2_O_O1D_frequency', $
                 Data = {x:fismdata.x, y:O2_O_O1D_frequency},$
                 dlimits={ytitle:'O2 -> O, O1D !c Frequency, #/s'}
     store_data, 'O2_O1S_O1S_frequency', $
                 Data = {x:fismdata.x, y:O2_O1S_O1S_frequency},$
                 dlimits={ytitle:'O2 -> O1S, O1S !c Frequency, #/s'}
     
     store_data, 'ionization_frequency_N2', Data = {x:fismdata.x, y:ionization_frequency_N2},$
                 dlimits={ytitle:'N2 Ionization !c Frequency, #/s'}
     store_data, 'N2_N2plus_frequency', $
                 Data = {x:fismdata.x, y:N2_N2plus_frequency},$
                 dlimits={ytitle:'N2 -> N2+ !c Frequency, #/s'}
     store_data, 'N2_N_Nplus_frequency', $
                 Data = {x:fismdata.x, y:N2_N_Nplus_frequency},$
                 dlimits={ytitle:'N2 -> N, N+ !c Frequency, #/s'}
     store_data, 'N2_N_N_frequency', $
                 Data = {x:fismdata.x, y:N2_N_N_frequency},$
                 dlimits={ytitle:'N2 -> N, N !c Frequency, #/s'}
     
     store_data, 'ionization_frequency_O', Data = {x:fismdata.x, y:ionization_frequency_O},$
                 dlimits={ytitle:'O Ionization !c Frequency, #/s'}
     store_data, 'ionization_frequency_Ar', Data = {x:fismdata.x, y:ionization_frequency_Ar},$
                 dlimits={ytitle:'Ar Ionization !c Frequency, #/s'}
  endif
; make a structure
  ionization_frequency = $
     {time:fismdata.x, $
      ionization_frequency_CO2: ionization_frequency_CO2, $
      CO2_CO2plus_frequency: CO2_CO2plus_frequency,$
      CO2_O_COplus_frequency: CO2_O_COplus_frequency,$
      CO2_CO_Oplus_frequency: CO2_CO_Oplus_frequency,$
      CO2_O2_Cplus_frequency: CO2_O2_Cplus_frequency,$      
      CO2_sCO_O1D_frequency: CO2_sCO_O1D_frequency,$      
      CO2_sCO_O_frequency: CO2_sCO_O_frequency,$      
      CO2_tCO_O_frequency: CO2_tCO_O_frequency,$      
      ionization_frequency_CO: ionization_frequency_CO, $
      CO_COplus_frequency: CO_COplus_frequency,$
      CO_C_Oplus_frequency: CO_C_Oplus_frequency,$
      CO_O_Cplus_frequency: CO_O_Cplus_frequency,$
      CO_C3P_O3P_frequency: CO_C3P_O3P_frequency,$
      CO_C1D_O1D_frequency: CO_C1D_O1D_frequency,$
      ionization_frequency_O2: ionization_frequency_O2, $
      O2_O2plus_frequency: O2_O2plus_frequency,$
      O2_O_Oplus_frequency: O2_O_Oplus_frequency,$      
      O2_O_O_frequency: O2_O_O_frequency,$      
      O2_O_O1D_frequency: O2_O_O1D_frequency,$      
      O2_O1S_O1S_frequency: O2_O1S_O1S_frequency,$      
      ionization_frequency_N2: ionization_frequency_N2, $
      N2_N2plus_frequency: N2_N2plus_frequency,$
      N2_N_Nplus_frequency: N2_N_Nplus_frequency,$      
      N2_N_N_frequency: N2_N_N_frequency,$      
      ionization_frequency_O: ionization_frequency_O, $
      ionization_frequency_Ar: ionization_frequency_Ar}

  return, ionization_frequency
end
