;+
;
; PROCEDURE: RBSP_LOAD_RBSPICE_READ
;
; PURPOSE:   Works on previously loaded RBSPICE tplot variables: adds energy channel energy values to primary data variable, separates non-H species variables,
;             creates variables for individual telescopes, and sets appropriate tplot options
;
; KEYWORDS:
;         probe:        RBSP spacecraft indicator [Options: 'a' (default), 'b']
;         datatype:     RBSPICE data type ['EBR','ESRHELT','ESRLEHT','IBR','ISBR','ISRHELT','TOFxEH' (default),'TOFxEIon','TOFxEnonH','TOFxPHHHELT','TOFxPHHLEHT'],
;                       but change for different data levels.
;         species:      particle species ['proton' (default),'helium','oxygen', or 'ions']
;         tplotnames:   This does not need to be defined, will load all previously loaded tplot variables
;         level:        data level ['l1','l2','l3' (default),'l3pap']
;                     
; REVISION HISTORY:
;     + ?, D. Turner, M. Gkioulidou, K. Keika,  : created with cdf reader provided by H. Korth.  
;     + 2013-04, K. Keika                       : ?
;     + 2016-09-12, I. Cohen                    : added trange keyword and introduced into call to rbsp_load_emphisis; commented out load and analysis of emphisis data
;     + 2017-02-21, I. Cohen                    : reconfigured redefinition of '*_F*DU' variables to separate oxygen and helium; defined species and yticks variables for y-axis labeling; 
;                                                 changed yrange and zrange limits
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-03-03 08:51:35 -0800 (Fri, 03 Mar 2017) $
;$LastChangedRevision: 22904 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/rbspice/rbsp_load_rbspice_read.pro $
;-
pro rbsp_load_rbspice_read, level=level, probe=probe, datatype=datatype, trange=trange
  if undefined(probe) then probe = 'a'
  if undefined(level) then level = 'l3'
  if (level ne 'l1') then begin
    units_label = '1/(cm!U2!N-sr-s-keV)'
    convert_factor = 1000.              ; to convert flux from 1/MeV to 1/keV
  endif else begin
    units_label = 'counts/s'
    convert_factor = 1.                 ; do not need to convert counts/s           
  endelse

  prefix = 'rbsp'+probe+'_rbspice_'+level+'_'+datatype+'_'
  ; find the flux/cps data name(s)
  data_var = tnames(prefix + 'F*DU')
  energy_var = tnames(prefix + 'F*DU_Energy')
  
  for i = 0,n_elements(data_var)-1 do begin
    
    get_data, (energy_var[i])[0], data = temp_energy, dlimits=temp_energydl
    get_data,(data_var[i])[0],data=temp,dlimits=temp_dl
    
    species_str = strmid(data_var[i],3,2,/reverse)
    case species_str of
      'FP': begin
              species='proton'
              yticks = 1
              if (datatype ne 'TOFxPHHHELT') then begin
                new_energy = temp_energy.y[*,0] * 1000.           ; convert energy from MeV to keV
                new_flux = temp.y / convert_factor                ; convert flux from 1/MeV to 1/keV
                zrange = [5.,1.e5]
              endif else begin
                new_energy = temp_energy.y[11:-1,0] * 1000.       ; convert energy from MeV to keV
                new_flux = temp.y[*,11:-1,*] / convert_factor       ; convert energy from MeV to keV
                zrange = [2.e2,1.e6]
              endelse
            end
      'He': begin
              species='helium'
              yticks = 1
              new_energy = temp_energy.y[0:10,0] * 1000.          ; convert energy from MeV to keV
              new_flux = temp.y[*,0:10,*] / convert_factor        ; convert flux from 1/MeV to 1/keV
              zrange = [1.,1.e3]
            end
      'FO': begin
              species='oxygen'
              yticks = 2
              if (datatype ne 'TOFxPHHHELT') then begin
                new_energy = temp_energy.y[11:18,0] * 1000.       ; convert energy from MeV to keV
                new_flux = temp.y[*,11:18,*] / convert_factor     ; convert flux from 1/MeV to 1/keV
                zrange = [1.,1.e2]
              endif else begin
                new_energy = temp_energy.y[0:10,0] * 1000.        ; convert energy from MeV to keV
                new_flux = temp.y[*,0:10,*] / convert_factor      ; convert flux from 1/MeV to 1/keV
                zrange = [1e1,1.e4]
              endelse
            end
    endcase
    new_name = prefix+species
    
    store_data,new_name,data={x:temp.x,y:new_flux,v:new_energy},dlimits=temp_dl
    options,new_name, spec=1, ylog=1, zlog=1, yrange=minmax(new_energy), ystyle=1, zrange=zrange, zstyle=1, minzlog = .01, $
      ytitle='rbsp'+probe+'!Crbspice!C'+species, ysubtitle='Energy!C[keV]', ztitle=units_label, yticks=yticks
  
    for j=0,5 do begin
      store_data,new_name+'_T'+strtrim(string(j),2),data={x:temp.x,y:new_flux[*,*,j],v:new_energy},dlimits=temp_dl
      options,new_name+'_T'+strtrim(string(j),2), spec=1, ylog=1, zlog=1, yrange=minmax(new_energy), ystyle=1, zrange=zrange, zstyle=1, minzlog = .01, $
        ytitle='rbsp'+probe+'!Crbspice!C'+species+'!CT'+strtrim(string(j),2), ysubtitle='[keV]', ztitle=units_label, yticks=yticks
    endfor
  endfor
  
end
