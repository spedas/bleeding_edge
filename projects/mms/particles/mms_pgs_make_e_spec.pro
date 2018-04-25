;+
;Procedure:
;  mms_pgs_make_e_spec
;
;Purpose:
;  Builds energy spectrogram from simplified particle data structure.
;
;
;Input:
;  data: single sanitized data structure
;  
;
;Input/Output:
;  spec: The spectrogram (ny x ntimes)
;  yaxis: The y axis (ny OR ny x ntimes)
;  
;  -Each time this procedure runs it will concatenate the sample's data
;   to the SPEC variable.
;  -Both variables will be initialized if not set
;  -The y axis will remain a single dimension until a change is detected
;   in the data, at which point it will be expanded to two dimensions.
;
;
;Notes:
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2018-04-24 16:23:53 -0700 (Tue, 24 Apr 2018) $
;$LastChangedRevision: 25106 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/particles/mms_pgs_make_e_spec.pro $
;-

pro mms_pgs_make_e_spec, data, spec=spec, sigma=sigma, yaxis=yaxis, enormalize=enormalize, energy=energy, _extra=ex

  compile_opt idl2, hidden
  
  if ~is_struct(data) then return
  
  ; if set, normalize spec between 0 and 1
  if keyword_set(enormalize) && enormalize ne 0 then begin
    data_energy = data.energy / max(data.energy,/NAN)
    outtable = data.orig_energy/max(data.orig_energy,/NAN)
  endif else begin
    data_energy = data.energy
    outtable = data.orig_energy
  endelse

  if ~keyword_set(energy) then erange = minmax(data_energy) else erange = energy
  
  ;copy data and zero inactive bins to ensure
  ;areas with no data are represented as NaN
  d = data.data
  idx = where(~data.bins,nd)
  if nd gt 0 then begin
    d[idx] = 0.
  endif
  
  outbins = dblarr(n_elements(d[*, 0]), n_elements(d[0, *]))

  ; rebin the data to the original energy table
  for ang_idx=0, n_elements(d[0, *])-1 do begin
    etable = data_energy[*, ang_idx]
    for binidx=0, n_elements(outtable)-1 do begin
      if d[binidx, ang_idx] ne 0.0 then begin
        this_en = find_nearest_neighbor(outtable, etable[binidx], /sort, /quiet)
        if this_en eq -1 then begin
          if etable[binidx] lt outtable[0] then outbins[0, ang_idx] += d[binidx, ang_idx]
          if etable[binidx] gt outtable[n_elements(outtable)-1] then outbins[n_elements(outtable)-1, ang_idx] += d[binidx, ang_idx]
        endif else begin
          whereen = where(outtable eq this_en)
          outbins[whereen, ang_idx] += d[binidx, ang_idx]
        endelse
      endif
    endfor
  endfor

  scaling = data.scaling
  
  where_out_of_erange = where(outtable lt erange[0] or outtable gt erange[1], outofrangecount)
  if outofrangecount ne 0 then outbins[where_out_of_erange] = !values.d_nan

  ;weighted average to create spectrogram piece
  ;energies with no valid data should come out as NaN
  if n_elements(d[0, *]) gt 1 then begin
    ave = total(outbins,2) / total(data.bins,2)
    ave_s = sqrt(  total( outbins * scaling ,2) / total(data.bins,2)^2  )
  endif else begin
    ave = outbins / data.bins
    ave_s = sqrt(  ( outbins * scaling ) / data.bins^2  )
  endelse

  ;output the y-axis values
  y = outtable
 
  ;set y axis
  if undefined(yaxis) then begin
    yaxis = y
  endif else begin
    spd_pgs_concat_yaxis, yaxis, y, ns=dimen2(spec)
  endelse
  
  ;concatenate spectra
  if undefined(spec) then begin
    spec = temporary(ave)
  endif else begin
    spd_pgs_concat_spec, spec, ave
  endelse 
  
  ;concatenate standard deviation
  if undefined(sigma) then begin
    sigma = temporary(ave_s)
  endif else begin
    spd_pgs_concat_spec, sigma, ave_s
  endelse 
    
end