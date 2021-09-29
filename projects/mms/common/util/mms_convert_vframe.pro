;+
;NAME:	
;	mms_convert_vframe
;
;FUNCTION:  convert_vframe ,  dat,  velocity
;PURPOSE:   Change velocity frames 
;INPUT: 
;  dat: 3d data structure
;  velocity: SW velocity vector  [VX,VY,VZ]
;OUTPUT:  3d data structure.  Data will be in a different coordinate frame.
;    (data will also be in units of distrubution function.)
;KEYWORDS:
;   ETHRESH:  Threshold energy for interpolation.
;   BINS:     Angle bins to be used
;   EVALUES:
;   INTERPOLATE:  set to non-zero value to have the data evaluated 
;   (interpolated) at the original energy steps.
;
;CREATED BY:	Davin Larson
;
;Forked for MMS by egrimes, 12/12/2018
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2018-12-12 14:08:01 -0800 (Wed, 12 Dec 2018) $
;$LastChangedRevision: 26317 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/util/mms_convert_vframe.pro $
;-

function mms_convert_vframe,tdata,vframe  $
  ,EVALUES = evalues $
  ,e_shift = e_shift  $
  ,sc_pot = sc_pot  $
  ,INTERPOLATE = interpolate,EXTRAPOLATE = extrapolate $
  ,ethresh=ethresh,dfdv=dfdv,bins=bins, nonrelativistic=nonrelativistic

if tdata.valid eq 0 then  begin
   dprint, 'Invalid Data' 
   return,tdata
endif

if not keyword_set(e_shift) then e_shift = 0.
str_element,tdata,'e_shift',e_shift
data = tdata
data.energy =data.energy+e_shift
;data.e_shift=0

if ndimen(evalues) ne 1 then $
      evalues = average(tdata.energy,2)

data = conv_units(data,'df_km')
o_data= data.data
o_energy = data.energy

if n_params() lt 2 then vframe = data.vsw
if not keyword_set(sc_pot) then sc_pot = 0.
str_element,data,'sc_pot', sc_pot
;if debug() ne 0 then print,'sc_pot= ',sc_pot, '        e_shift= ',e_shift

energy = data.energy - sc_pot 
bad = where(data.energy lt sc_pot*1.3,nbad)
if nbad ne 0 then data.data[bad] = !values.f_nan

vel = velocity(energy,data.mass)
theta = data.theta
phi = data.phi

if keyword_set(ethresh) and keyword_set(dfdv) eq 0 then begin
   if keyword_set(bins) then ind = where(bins) else ind = indgen(data.nbins)
   dfavg = total(o_data[*,ind],2,/nan)/total(finite(o_data[*,ind]),2)
   vavg = total(vel[*,ind],2,/nan)/total(finite(vel[*,ind]),2)
   dfdv = deriv(vavg,alog(dfavg))
endif


if ~keyword_set(nonrelativistic) then mms_transform_velocity_lorentz,vel,theta,phi,vframe,sx=sx,sy=sy,sz=sz else mms_transform_velocity,vel,theta,phi,vframe,sx=sx,sy=sy,sz=sz
;data.energy = .5*data.mass*vel*vel
data.energy = velocity(/inverse,vel,data.mass)
data.theta = theta
data.phi = phi
;str_element,/add,data,'vframe',vframe

if keyword_set(interpolate) then begin
;   range = minmax(data.data,/POS)
   for i=0,data.nbins-1 do begin
      df_temp = data.data[*,i]
      th_temp = data.theta[*,i]
      ph_temp = data.phi[*,i]
      nrg = data.energy[*,i]
      w = where(finite(df_temp) eq 0,count)
      if count ne 0 then df_temp[w] = 0
      ind = where(df_temp gt 0,count)
      
      if count gt 1 then begin
          df_temp = interp(alog(df_temp[ind]),nrg[ind],evalues)
          th_temp = interp(th_temp[ind],nrg[ind],evalues)
          ph_temp = interp(ph_temp[ind],nrg[ind],evalues)
      endif
      if not keyword_set(extrapolate) then begin
         w = where(evalues lt min(nrg),count)
         if count ne 0 then df_temp[w] = !values.f_nan
      endif
      data.data[*,i]  = exp(df_temp)
      data.theta[*,i] = th_temp
      data.phi[*,i]   = ph_temp
   endfor
   data.energy = evalues # replicate(1.,data.nbins)
   if keyword_set(Ethresh)  then begin
      ind = where(tdata.energy gt ethresh,nind)
      if nind gt 0 then begin
        bdfdv = dfdv # replicate(1.,data.nbins)
        o_data = o_data*(1.+(sx*vframe[0]+sy*vframe[1]+sz*vframe[2])*bdfdv )
        data.data[ind] = o_data[ind]
      endif
   endif
endif

return,data
end

