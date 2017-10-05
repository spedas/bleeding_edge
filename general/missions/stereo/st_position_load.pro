pro st_position_load,  source_options=source_options,trange=trange,probe=probes, $
     rotmatrix_name=rotmatrix_name, $
     Euler_angles_name = E_angles_name,$
     Euler_params_name  = E_params_name, $
     attitude=attitude,verbose=verbose,coord1=coord1

attitude = keyword_set(attitude)
attitude = attitude  || arg_present(rotmatrix_name) || keyword_set(rotmatrix_name)
attitude = attitude  || arg_present(E_angles_name) || keyword_set(E_angles_name)
attitude = attitude  || arg_present(E_params_name) || keyword_set(E_params_name)

if not keyword_set(coord1) then coord1 = 'SC'
if not keyword_set(source_options) then begin
    stereo_init

    source_options = !stereo ;file_retrieve(/struct)
    source_options.local_data_dir = !stereo.local_data_dir  ; root_data_dir()+'stereo/'
    source_options.remote_data_dir = 'http://www.srl.caltech.edu/STEREO2/'  ;  'behind/position_behind_2006_GSE.txt
    source_options.ignore_filedate =1 ; All files on remote system are updated daily (even if no differences).
    source_options.min_age_limit = 12*3600d  ; check no more often than once every 12 hours
endif
mystereo = source_options
;mystereo.remote_data_dir = 'http://www.srl.caltech.edu/STEREO2/Position/'  ;  'behind/position_behind_2006_GSE.txt

if n_elements(verbose)  eq 0 then verbose=0
;if not keyword_set(probes) then probes = ['a','b']
defprobe = struct_value(mystereo,'probe',def='a')    ; use default probe
if not keyword_set(probes) then probes = defprobe

;res = 3600l*24 *365.25    ; one year resolution in the files
tr = timerange(trange)
dates = time_struct(tr)
n = (dates[1].year - dates[0].year) +1   ; floor(tr[1]/res)-floor(tr[0]/res)+1)  > 1
dates = replicate(dates[0],n)
dates.year += indgen(n)
;tr = time_string(timerange(trange),prec=-5)
;tr = time_struct(timerange(trange))
;years = tr.year
;ny = (year[1]-year[0]) + 1

for p=0,n_elements(probes)-1 do begin
   probe = probes[p]
;   pref = 'st'+probe+'_' + (keyword_set(burst) ? '_b' : '')
   if not keyword_set(attitude) then begin
     coord='GSE'
     case probe of
       'a' :  path = 'Position/ahead/position_ahead_YYYY_'+coord+'.txt'
       'b' :  path = 'Position/behind/position_behind_YYYY_'+coord+'.txt'
     endcase
     nv = 3
     tlabel = '_pos_'+coord
     scale = 6400.
   endif else begin
     coord = 'RTN'
     case probe of
       'a' :  path = 'Pointing/ahead/pointing_ahead_YYYY_'+coord+'.txt'
       'b' :  path = 'Pointing/behind/pointing_behind_YYYY_'+coord+'.txt'
     endcase
     nv = 9
     tlabel = '_RotMat_SC>'+coord
     scale = 1.
   endelse

   relpathnames= time_string(dates,tformat= path)
;   relpathnames = relpathnames[uniq(relpathnames)]
   files = file_retrieve(relpathnames,_extra = mystereo)

   fformat = {year:0l, doy:0l,  sod:0l, flag:0,  pos:dblarr(nv)}
   data = 0
   for i=0,n_elements(files)-1 do $
      data = read_asc(files[i],format=fformat,append=data)

   tstr = replicate( time_struct(0d), n_elements(data) )
   tstr.year = data.year  & tstr.date=data.doy & tstr.fsec=data.sod & tstr.month=1
   tdbl = time_double(tstr)

   if not keyword_set(attitude) then begin
     store_data,'st'+probe+tlabel,data={x:tdbl,y:transpose(data.pos/scale)},dlimit={ystyle:2}
   endif else begin
    if keyword_set(get_rotmatrix) then     store_data,'st'+probe+tlabel,data={x:tdbl,y:transpose(data.pos/scale)},dlimit={ystyle:2}
    if coord1 eq 'SC' then rt = identity(3,/double)
    if coord1 eq 'SC2' && probe eq 'b' then rt = [[-1d,0,0],[0,0,-1],[0,-1,0]]
    if coord1 eq 'SC2' && probe eq 'a' then rt = [[-1d,0,0],[0,0,1],[0,1,0]]

    if keyword_set(E_angles_name) or arg_present(e_angles_name)  then begin
      nd = n_elements(data)
      par=0
      dprint,'Getting Euler angles for probe ',probe
      dummy = euler_ang_rot_matrix(0,param=par)
      str_element,/add,par,'chi2',0.
      pars = replicate(par,nd)
      minres=1e-8
      for j = 0,nd-1 do begin
         dprint,dwait=10,j,' of ',nd
         r = rt ## reform(data[j].pos,3,3)
         fit,0,r,param=par,minres=minres,chi2=chi2,verbose=verbose  ; ,/silent ;,/testname  ;,verbose=dlevel
         par.chi2 = chi2
;         par.the mod= 360  & par.phi mod= 360  & par.psi mod= 360
         pars[j] = par
      endfor
;      pars.the mod= 360  & pars.phi mod= 360  & pars.psi mod= 360
      e_angles_name ='st'+probe+'_euler_angles_'+coord1+'>'+coord
      store_data,e_angles_name,data={x:tdbl,y:[[pars.phi],[pars.the],[pars.psi]]},dlimit={colors:'bgr'}
      if keyword_set(get_chi2) then $
        store_data,e_angles_name+'_chi2',data={x:tdbl,y:pars.chi2}
;      stop
    endif
    if  keyword_set(E_params_name) || arg_present(e_params_name) then begin
      nd = n_elements(data)
      par = 0
      dprint,dlevel=2,'Getting Euler parameters for probe ',probe
      dummy = euler_rot_matrix(0,param=par)
      par.eulpar[*]=.5   ; initial condition
      str_element,/add,par,'chi2',0.
      pars = replicate(par,nd)
      minres=1e-8
      for j = 0,nd-1 do begin
         r = rt ## reform(data[j].pos,3,3)
         fit,0,r,param=par,minres=minres,chi2=chi2,verbose=verbose  ;,/testname  ;,verbose=dlevel
         par.chi2 =chi2
         dprint,dwait=10,j,' of ',nd,chi2
         par.eulpar /= sqrt(total(par.eulpar^2))
         pars[j] = par
      endfor
      E_params_name ='st'+probe+'_euler_param_'+coord1+'>'+coord
      store_data,E_params_name,data={x:tdbl,y:transpose(pars.eulpar)},dlimit={yrange:[-1,1],ystyle:2,colors:'dbgr'}
      if keyword_set(get_chi2) then $
        store_data,E_params_name+'_chi2',data={x:tdbl,y:pars.chi2},dlimit={ystyle:2,ylog:1}
    endif
;      store_data,'st'+probe+'_euler_angles_'+coord1+'>'+coord,data={x:tdbl,y:[[pars.phi],[pars.the],[pars.psi]]}
;      store_data,'st'+probe+'_euler_angles_'+coord1+'>'+coord+'_chi2',data={x:tdbl,y:pars.chi2}
   endelse
endfor


end

