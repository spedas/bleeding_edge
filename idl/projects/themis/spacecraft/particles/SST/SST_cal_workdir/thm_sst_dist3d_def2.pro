;+
;NAME:
; thm_sst_dist3d_def
;PURPOSE:
;  This routine returns the appropriate distribution representation struct for 
;  a particular number of SST angles in the data type.
;  Default and/or constant values will be populated.  At this point,
;  the structure should be considered incomplete. 
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-02-05 14:02:49 -0800 (Fri, 05 Feb 2016) $
;$LastChangedRevision: 19904 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/SST/SST_cal_workdir/thm_sst_dist3d_def2.pro $
;-


function thm_sst_dist3d_def2,dformat=dformat  ;,ion=ion,elec=elec,time,probe=prb,index=index


dprint,dlevel=3,'Defining: ',  dformat

ion  = strmid(dformat,6,1) eq 'i'
elec = strmid(dformat,6,1) eq 'e'
prb  = strmid(dformat,2,1)
ang  = strmid(dformat,9,3)

case ang of
  '001' :  dat = thm_sst_dist3d_16x1(ion=ion,elec=elec,probe=prb)
  '006' :  dat = thm_sst_dist3d_16x6(ion=ion,elec=elec,probe=prb)
  '064' :  dat = thm_sst_dist3d_16x64_2(ion=ion,elec=elec,probe=prb)
  '128' : begin & dat = thm_sst_dist3d_16x64_2(ion=ion,elec=elec,probe=prb) & message & end
endcase

if ~is_struct(dat) then begin
  return,0
endif

dat.magf = !values.f_nan
dat.eclipse_dphi = !values.d_nan
;dat.sc_pot = !values.f_nan
dat.index = -1
dat.project_name = 'THEMIS'
dat.data_name = strmid(dformat,4,4)
dat.spacecraft = prb
dat.units_name = 'Compressed Counts'
;already set by lower level procedure
;dat.units_procedure = 'thm_sst_convert_units'
dat.tplotname = dformat

return,dat
end



