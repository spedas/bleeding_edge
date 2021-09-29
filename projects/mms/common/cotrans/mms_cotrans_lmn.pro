;+
; PROCEDURE:
;         mms_cotrans_lmn
;
; PURPOSE:
;         Tranforms MMS vector fields from GSM coordinates to LMN (boundary-normal) coordinates
;         using the Shue et al., 1998 magnetopause model
;
; KEYWORDS:
;         gsm: input vector is in GSM coordinates (note: if the coordinate system is stored in the tplot metadata, these keywords are not required)
;         gse: input vector is in GSE coordinates
;         probe: MMS probe #; not required if the input variable follows the standard MMS naming scheme, e.g., mms1_mec_r_gsm
;         data_rate: data rate of the MEC data
;         resol: desired time resolution of the solar wind data in seconds
;             if not set, SW data are provided in original time resolution
;         wind - use WIND observations for solar wind data (they are convolved to desired resolution and
;             then time-shifted to the bow-shock nose using OMNI-2 methodology. The
;             code checks if the SW speed irregularities are too large and warns
;             user when more sophisticated processing may be needed.
;         min5 - use 5 min HRO merged database for solar wind inputs (default is to use 1 min HRO merged data)
;         h1 - use OMNI-2 1 hour SW database for solar wind inputs. No convolution employed and parameter
;             resol is ignored
;             
; NOTES:
;         Based on the THEMIS version, thm_cotrans_lmn
; 
;         Also accepts all keywords available to solarwind_load
;         
;$LastChangedBy: egrimes $
;$LastChangedDate: 2021-04-13 13:15:22 -0700 (Tue, 13 Apr 2021) $
;$LastChangedRevision: 29876 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/cotrans/mms_cotrans_lmn.pro $
;-

pro mms_cotrans_lmn, name_in, name_out, gsm=gsm, gse=gse, probe=probe, data_rate=data_rate, wind=wind, h1=h1, _extra=ex
  
  if undefined(wind) && undefined(h1) then hro = 1b
  
  get_data, name_in, data=data_in, limit=l_in, dlimits=dl_in
  
  if ~is_struct(data_in) then begin
    dprint, dlevel=0, 'Error reading tplot variable: ' + name_in
    return
  endif
  
  data_in_coord = strlowcase(cotrans_get_coord(name_in))
  
  if data_in_coord ne 'gse' and data_in_coord ne 'gsm' and ~keyword_set(gsm) and ~keyword_set(gse) then begin
    dprint, dlevel=0, 'Please specify the coordinate system of the input data'
    return
  endif
  
  ; we'll need the probe if it's not specified via keyword
  if undefined(probe) then begin
    sc_id = strsplit(name_in, '_', /extract)
    if sc_id[0] ne '' then probe = strmid(sc_id[0], strlen(sc_id[0])-1, strlen(sc_id[0]))
    if ~array_contains(['1', '2', '3', '4'], probe) then begin
      dprint, dlevel=0, "Error, probe not found; please specify the probe via the 'probe' keyword"
    endif
  endif

  ; load the spacecraft position data
  mms_load_mec, trange=minmax(data_in.x), probe=probe, data_rate=data_rate
  tinterpol, 'mms'+probe+'_mec_r_gsm', name_in, new_name='mms'+probe+'_mec_r_gsm_interp'
  get_data, 'mms'+probe+'_mec_r_gsm_interp', data=pos_data
  
  if data_in_coord ne 'gsm' then begin
    mms_qcotrans, name_in, name_in+'_gsm', out_coord='gsm'
    get_data, name_in+'_gsm', data=data_in
  endif

  ; load the solar wind data
  sw_times = minmax(data_in.x)
  solarwind_load, swdata, dst, sw_times, hro=hro, wind=wind, h1=h1, _extra=ex

  txyz = [[data_in.X], [pos_data.Y]]
  bxyz = data_in.Y
  
  ; now rotate GSM -> LMN
  gsm2lmn, txyz, bxyz, blmn, swdata
  
  store_data, name_out, data={x: data_in.X, y: blmn}, limit=l_in, dlimits=dl_in
  options, name_out, 'labels', ['L', 'M', 'N']
  options, name_out, 'colors', [2, 4, 6]

end