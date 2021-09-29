;+
;NAME:
;   icon_dimension_fix
;
;PURPOSE:
;   Fixes netcdf dimensions
;
;KEYWORDS:
;
;HISTORY:
;$LastChangedBy: nikos $
;$LastChangedDate: 2019-02-05 14:12:12 -0800 (Tue, 05 Feb 2019) $
;$LastChangedRevision: 26552 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/icon/common/icon_dimension_fix.pro $
;
;--------------------------------------------------------------------------------

pro icon_dimension_fix, netcdfi

  ; handle possible errors
  catch, errstats
  if errstats ne 0 then begin
    dprint, dlevel=1, 'Error in : icon_dimension_fix', !ERROR_STATE.MSG
    catch, /cancel
    return
  endif

  depend_ = ['depend_0','depend_1','depend_2','depend_3']

  n_t = n_tags(netcdfi.dims)
  n_v = n_tags(netcdfi.vars)

  dim_size = lonarr(n_t)
  dim_name = strarr(n_t)

  for i=0,n_t-1 do begin
    dim_size[i] = netcdfi.dims.(i).size
    dim_name[i] = netcdfi.dims.(i).name
    if(strmatch(dim_name[i],'epoch',/fold_case) eq 1 ) then begin
      dim_size[i] = size(*netcdfi.vars.epoch.dataptr,/n_elements)
    endif
    if(strmatch(dim_name[i],'epoch',/fold_case) eq 1 ) then time_size = dim_size[i]
  endfor

  for i=0,n_v-1 do begin

    cur_name = ''
    ; handle possible errors
    catch, errv
    if errv ne 0 then begin
      dprint, dlevel=1, 'Error in : icon_dimension_fix', !ERROR_STATE.MSG, cur_name
      catch, /cancel
      continue
    endif

    cur_name = netcdfi.vars.(i).name
    data_hld = *netcdfi.vars.(i).dataptr
    n_d = size(*netcdfi.vars.(i).dataptr)
    n_d_type = size(*netcdfi.vars.(i).dataptr,/type)
    if(n_d_type eq 7) then continue
    ;    if(i eq 22) then stop
    d = lonarr(n_d[0])
    w_d = lonarr(n_d[0])
    dind = lonarr(n_d[0])
    flg_miss_match = intarr(n_d[0])

    for j=0,n_d[0]-1 do begin
      status = tag_exist(netcdfi.vars.(i),depend_[j],index=dindex)
      ; If required since Epoch doesn't have a depend
      if(status eq 1b) then begin
        w_d[j] = where(string(netcdfi.vars.(i).(dindex)) eq dim_name,/null)
        d[j] = n_d[j+1]
        if(dim_size[w_d[j]] ne d[j]) then flg_miss_match[j] = 1
      endif
    endfor

    missing_dim = where(flg_miss_match eq 1,/null)
    if(missing_dim ne !NULL) then begin
      ;      if(i eq 22) then stop
      dum = []
      r = d/dim_size[w_d]
      for k=0,n_d[0]-1 do begin
        dum = [dum,dim_size[w_d[k]],r[k]]
      endfor
      data_hld2 = reform(data_hld,[dum])
      data_hdl = data_hld2
    endif

    time_out = 0
    ind_time = where(size(data_hld,/dimension) eq time_size)
    if(ind_time gt 0) then begin
      time_out = 1
      ind_nottime = where(size(data_hld,/dimension) ne time_size)
      dum_tr = [ind_time,ind_nottime]
      data_hld2 = transpose(data_hld,dum_tr)
      data_hld = data_hld2
    endif

    for k=0,n_d[0] do begin
      status = tag_exist(netcdfi.vars.(i),depend_[k],index=dindex)
      hld_size = size(data_hld,/dimensions)
      if(status eq 1b) && (k le n_elements(hld_size)-1) then begin
        ind_dim = where(dim_size eq hld_size[k],/null, count)
        if count gt 0 then netcdfi.vars.(i).(dindex) = dim_name[ind_dim]
      endif
    endfor

    if(missing_dim ne 0 || time_out ne 0) then begin
      netCDFi.vars.(i).dataptr = ptr_new(data_hld)
    endif

  endfor

end