;+
;
; PROCEDURE:
;         rbsp_rbspice_omni
;
; PURPOSE:
;       Calculates the omni-directional flux for all 6 telescopes
;
; KEYWORDS:
;         probe:        RBSP spacecraft indicator [Options: 'a' (default), 'b']
;         datatype:     RBSPICE data type ['EBR','ESRHELT','ESRLEHT','IBR','ISBR','ISRHELT','TOFxEH' (default),'TOFxEIon','TOFxEnonH','TOFxPHHHELT','TOFxPHHLEHT'],
;                       but change for different data levels.
;         tplotnames:   This does not need to be defined, will load all previously loaded tplot variables
;         level:        data level ['l1','l2','l3' (default),'l3pap']
;
;
; REVISION HISTORY:
;       + 2016-12-09, I. Cohen      : created based on mms_eis_omni.pro; added level keyword; removed data_units and data_rate keywords
;       + 2017-02-21, I. Cohen      : defined species variable for y-axis labeling
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-03-03 08:08:58 -0800 (Fri, 03 Mar 2017) $
;$LastChangedRevision: 22902 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/rbspice/rbsp_rbspice_omni.pro $
;-
pro rbsp_rbspice_omni, probe=probe, datatype = datatype, tplotnames = tplotnames, level=level
  if undefined(probe) then probe = 'a'
  if undefined(datatype) then datatype = 'TOFxEH'
  if undefined(level) then level = 'l3'
  if (level ne 'l1') then units_label = '1/(cm!U2!N-sr-s-keV)' else units_label = 'counts/s'
  
  probe = strcompress(string(probe), /rem)
  prefix = 'rbsp'+probe+'_rbspice_'+level+'_'+datatype+'_'

  ; find the flux/cps data name(s)
  data_var = tnames(prefix + 'F*DU')

  if data_var(0) eq '' then begin
    dprint, dlevel = 0, 'Error, problem finding the RBSPICE data to calculate omni-directional spectrograms'
    return
  endif

  for i=0,n_elements(data_var)-1 do begin
    
    species_str = strmid(data_var(i),3,2,/reverse)
    case species_str of
      'FP': begin
              species='proton'
              if (datatype ne 'TOFxPHHHELT') then zrange = [5.,1.e5] else zrange = [2.e2,1.e6]
            end
      'He':   begin
                species='helium'
                zrange = [1.,5.e2]
              end
      'FO': begin
              species='oxygen'
              if (datatype ne 'TOFxPHHHELT') then zrange = [1.,1.e2] else zrange = [1e1,1.e4]
            end  
    endcase
    
    ; load the flux/cps data
    get_data, prefix+species, data = d, dlimits=dl
    
    if is_struct(d) then begin

      flux_omni = dblarr(n_elements(d.x),n_elements(d.y(0,*,0)))
      for k=0,n_elements(d.x)-1 do for l=0,n_elements(d.y(0,*,0))-1 do flux_omni(k,l) = mean(d.y(k,l,*),/NAN)
      newname = prefix+species+'_omni'
      store_data, newname, data={x:d.x, y:flux_omni, v:d.v}, dlimits=dl   
      options, newname, ylog = 1, zlog=1, spec = 1, yrange = minmax(d.v), ystyle=1,  /default, zrange=zrange, zstyle=1, minzlog = .01, $
        ytitle = 'rbsp-'+probe+'!Crbspice!C'+species+'!Comni', ysubtitle='[keV]', ztitle=units_label
      
      append_array, tplotnames, newname
    endif
  endfor
end