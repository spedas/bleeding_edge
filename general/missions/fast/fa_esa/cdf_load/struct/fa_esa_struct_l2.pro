;+
;PURPOSE:	To return a data structure for a specific time from a FAST l2 common block.
;USEAGE:	dat=fa_esa_struct_l2(t,all_dat=all_dat,get_ind=get_ind)
;	        dat=fa_esa_struct_l2(all_dat=all_dat,get_ind=get_ind) will call ctime.pro to get t.
;		The routine assumes the l2 common block for datatype is already loaded into IDL.
;               It also assumes that all_dat and get_ind keywords are set.
;KEYWORDS:	all_dat = the full data structure, this must be set.
;               get_ind = an index value for the current time, if not set, the default is zero
;               /START to return data structure for the first time in l2 common block.
;		/EN to return data structure for the last time in l2 common block.
;		/ADVANCE to return the next data structure in the l2 common block.
;		/RETREAT to return the previous data structure in the l2 common block.
;		INDEX=INDEX to return the INDEXth data structure in the l2 common block.
;		/TIMES returns array of starting times in l2 common block instead of data structure.
;UPDATES:	Hacked from fa_esa_struct_l1.pro, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2017-03-20 13:26:40 -0700 (Mon, 20 Mar 2017) $
; $LastChangedRevision: 22998 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/fast/fa_esa/cdf_load/struct/fa_esa_struct_l2.pro $
;-
Function fa_esa_struct_l2, t, $
                           start=start, $
                           en=en, $
                           advance=advance, $
                           retreat=retreat, $
                           index=index, $
                           times=times, $
                           all_dat=all_dat, $
                           get_ind=get_ind
  if(~keyword_set(all_dat) || ~is_struct(all_dat)) then begin
     dprint, 'Bad ALL_DAT input)'
     return, {data_name:'', valid:0}
  endif
  if(~keyword_set(get_ind)) then get_ind = 0

  if keyword_set(times) then return, all_dat.time
  ntimes=n_elements(all_dat.time)

  delta_time=all_dat.end_time[0]-all_dat.time[0]
  time_threshold=delta_time
  if n_elements(index) EQ 0 then begin
     if keyword_set(advance) then begin
        if get_ind EQ ntimes-1 then begin
           dprint,'Error: End of Data. Cannot Advance.'
           return, {data_name:'', valid:0}
        endif
        index=get_ind+1
     endif
     if keyword_set(retreat) then begin
        if get_ind EQ 0 then begin
           dprint,'Error: Beginning of Data. Cannot Retreat'
           return,{data_name:'', valid:0}
        endif
        index=get_ind-1
     endif
     if keyword_set(en) AND keyword_set(start) then begin
        dprint,'Error: Both /EN and /START Keywords Set'
        return,{data_name:'', valid:0}
     endif
     if keyword_set(start) then index=0
     if keyword_set(en) then index=ntimes-1
     if n_elements(index) EQ 0 then begin
        if keyword_set(t) then begin
           t=time_double(t)
           time_tmp=(all_dat.time+all_dat.end_time)/2
           min_tmp=min(time_tmp-t,index_tmp,/absolute)
           min_tmp=abs(min(all_dat.time-t,index_tmp2,/absolute))
           if min_tmp LT time_threshold then index_tmp=index_tmp2
           original_t=t
           index=index_tmp[0]
           if abs(min_tmp) GT 5 then begin
              dprint,'Warning: All Data Samples Further than 5 Seconds from t'
              original_flag=1
           endif
        endif else begin
           ctime,t,npoints=1
           if NOT keyword_set(t) then begin
              dprint,'Error @ fa_esa_struct_1l.pro: CTIME Failure!'
              return,{data_name:'', valid:0}
           endif
           time_tmp=(all_dat.time+all_dat.end_time)/2
           min_tmp=min(time_tmp-t,index_tmp,/absolute)
           min_tmp=abs(min(all_dat.time-t,index_tmp2,/absolute))
           if min_tmp LT time_threshold then index_tmp=index_tmp2
           original_t=t
           index=index_tmp[0]
           if abs(min_tmp) GT 5 then begin
              dprint,'Warning: All Data Samples Further than 5 Seconds from t'
              original_flag=1
           endif
        endelse
     endif
  endif

  if (index LT 0) OR (index GE ntimes) then begin
     dprint,'Error: Index Out of Bounds!'
     return,{data_name:'', valid:0}
  endif
;t=all_dat.time[index]
  get_ind=long(index)
  nbins=all_dat.nbins[index]
  nenergy=all_dat.nenergy[index]
  mode_ind=all_dat.mode_ind[index]

  end_time=all_dat.end_time[index]
  units_procedure=all_dat.units_procedure
  valid=all_dat.valid[index]

  gf=all_dat.gf[0:nenergy-1,0:nbins-1,all_dat.gf_ind[index]]
  theta_shift=all_dat.theta_shift[index]
  theta_max=all_dat.theta_max[index]
  theta_min=all_dat.theta_min[index]
  opp_theta_shift=360.*theta_shift/abs(theta_shift)
  theta=all_dat.theta[0:nenergy-1,0:nbins-1,mode_ind]+theta_shift
  where_theta_greater=where(theta GT theta_max)
  where_theta_lesser=where(theta LT theta_min)
  if where_theta_greater[0] NE -1 then theta[where_theta_greater]-=opp_theta_shift
  if where_theta_lesser[0] NE -1 then theta[where_theta_lesser]-=opp_theta_shift
  if keyword_set(original_t) AND (NOT keyword_set(original_flag)) then begin
     if (original_t LT (all_dat.time[index]-time_threshold)) OR $
        (original_t GT (end_time+time_threshold)) then $
           dprint,'Warning: t Not Between TIME and END_TIME'
  endif

  datastr={data_name:all_dat.data_name, $
           valid:valid, $
           data_quality:all_dat.data_quality[index], $
           project_name:'FAST', $
           units_name:'eflux', $
           units_procedure:units_procedure, $
           time:all_dat.time[index], $
           end_time:end_time, $
           integ_t:all_dat.integ_t[index], $
           nbins:nbins, $
           nenergy:nenergy, $
           energy:all_dat.energy[0:nenergy-1,0:nbins-1,mode_ind], $
           bins:all_dat.bins[0:nenergy-1,0:nbins-1,all_dat.bins_ind[index]], $
           theta:theta, $
           geom:gf, $
           gf:gf, $
           denergy:all_dat.denergy[0:nenergy-1,0:nbins-1,mode_ind], $
           dtheta:all_dat.dtheta[0:nenergy-1,0:nbins-1,mode_ind], $
           eff:all_dat.eff[0:nenergy-1,0:nbins-1,mode_ind], $
           dead:all_dat.dead, $
           mass:all_dat.mass, $
           geom_factor:all_dat.geom_factor[index], $
           geomfactor:all_dat.geom_factor[index], $
           sc_pot:all_dat.sc_pot[index], $
           charge:all_dat.charge, $
           header_bytes:reform(all_dat.header_bytes[index,*]), $
           index:index, $
           eflux:reform(all_dat.eflux[index,0:nenergy-1,0:nbins-1]), $
           energy_full:reform(all_dat.energy_full[index,0:nenergy-1,0:nbins-1]), $
           denergy_full:reform(all_dat.denergy_full[index,0:nenergy-1,0:nbins-1]), $
           pitch_angle:reform(all_dat.pitch_angle[index,0:nenergy-1,0:nbins-1]), $
           domega:reform(all_dat.domega[index,0:nenergy-1,0:nbins-1])}

  return,datastr

end
