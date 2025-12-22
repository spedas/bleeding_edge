;	@(#)load_dc_fields.pro	1.67	
function load_dc_fields, hires=hires

catch,err_stat
if (err_stat ne 0) then begin
    message,!err_string,/continue
    if defined(new_names) then begin
        catch,/cancel
        return,new_names
    endif else begin
        catch,/cancel
        return,''
    endelse
endif


fnan = !values.f_nan
dnan = !values.d_nan
resolution = 0.05 ; seconds, gives 100 points per spin
spin_period = 5.01

pot = get_fa_potential(/spin,/repair)
v58 = get_fa_fields('V5-V8_S',/all,/cal,/repair)
magdc  = get_fa_fields('MagDC',/all,/cal,/repair)
dens = get_density(/all,/cal,/spin,/repair)

repeat begin
    get_data,'spin_times',data=spin_times,index=index
    if index eq 0 then begin
        message,'Loading spin times...',/continue
        if not load_spin_times(spin=180,/orbit_env) then begin
            message,'Cannot load spin times',/continue
            return,''
        endif
    endif
endrep until (index ne 0)

repeat begin
    get_data,'spt',data=spt,index=index
    if index eq 0 then begin
        summary_plot_times, times = times, ptypes = ptypes, $
          splot_time=splot_time
    endif
endrep until (index ne 0)
times = spt.times
ntimes = n_elements(times)
ptypes = spt.types
splot_time = spt.length
splot_sec = splot_time *60.d

if not(magdc.valid and v58.valid) then begin
    message,'Unable to load DC fields...',/continue
    return,''
endif

good = where((magdc.time ge min(spin_times.x)) and (magdc.time le $
                                              max(spin_times.x)),ngood)
if ngood eq 0 then begin
    message,'No MagDC data in current spin_time range...',/continue
    return,0
endif
    
by = -magdc.comp3(good)
b2raw = -magdc.comp2(good)
b3raw = magdc.comp1(good)

tmag = magdc.time(good)
mag = b3raw
spinmag = by
other_mag = b2raw

e58 = v58.comp1
t58 = v58.time

reduce_resolution,tmag,mag,resolution,kept = kept
reduce_resolution,t58,e58,resolution
other_mag = other_mag(kept)
spinmag = spinmag(kept)

some_good_data = 0
for i=0,ntimes-1 do begin
    epick = where((t58 ge times(i)) and (t58 lt times(i)+splot_sec))
    bpick = where((tmag ge times(i)) and (tmag lt times(i)+splot_sec))
    if ((epick(0) ge 0 ) and (bpick(0) ge 0)) then begin
        if spinfit4sumplots(t58(epick),e58(epick),tmag(bpick),mag(bpick), $
                  spinmag(bpick),tspint,ext,ezt,bxt,bzt,bspint, $
                  spin_anglet,other_mag(bpick),hires=hires) then begin 
            
            some_good_data = 1
            if ((ptypes(i) eq 'in') or (ptypes(i) eq 'os')) then begin
                sign = -1.d
            endif else begin
                sign = 1.d
            endelse
            ext = ext*sign
            bxt = bxt*sign
            
            
            if ((i eq 0) or not defined(tspin)) then begin
                tspin = [min(tspint),tspint,max(tspint)]
                ex = [fnan,ext,fnan]
                ez = [fnan,ezt,fnan]
                bx = [fnan,bxt,fnan]
                bz = [fnan,bzt,fnan]
                bspin = [fnan,bspint,fnan]
                spin_angle = [fnan,spin_anglet,fnan]
                if dens.valid then density = $
                  [fnan,interp(dens.comp1,dens.time,tspint),fnan]
                if pot.valid then potential = $
                  [fnan,interp(pot.comp1,pot.time,tspint),fnan]
                
            endif else begin
                tspin = [tspin,min(tspint),tspint,max(tspint)]
                ex = [ex,fnan,ext,fnan]
                ez = [ez,fnan,ezt,fnan]
                bx = [bx,fnan,bxt,fnan]
                bz = [bz,fnan,bzt,fnan]
                bspin = [bspin,fnan,bspint,fnan]
                spin_angle = [spin_angle,fnan,spin_anglet,fnan]
                if dens.valid then density = $
                  [density,fnan,interp(dens.comp1,dens.time,tspint),fnan] 
                if pot.valid then potential = $
                  [potential,fnan,interp(pot.comp1,pot.time,tspint),fnan]
            endelse
        endif
    endif 
endfor

if not some_good_data then begin
    message,'No DC fields data is available!',/continue
    return,''
endif

exc = ex
ezc = ez
bxc = bx
byc = bspin
bzc = bz

nan_set = where(finite(exc) eq 0,nns)
if nns gt 0 then begin
    spin_angle(nan_set) = fnan
endif


store_data,'Ex',data={x:tspin,y:exc}

store_data,'Ez',data={x:tspin,y:ezc}

store_data,'Bx',data={x:tspin,y:bxc}

store_data,'By',data={x:tspin,y:byc}

store_data,'Bz',data={x:tspin,y:bzc}

store_data,'spin angle',data={x:tspin,y:spin_angle}

if defined(density) then begin
    density = density > 0.1
    store_data,'DENSITY',data={x:tspin,y:density}
endif

if defined(potential) then begin
    store_data,'S/C potential',data={x:tspin,y:potential}
endif

default_dc_limits,/sdt

dcnames = ['Ex','Ez','DENSITY','Bx','By','Bz','S/C potential','spin angle']

cdfnames = dcnames
cdfdqds=cdfnames

;
;now do cdf stuff on raw fields quantities
;

ncdf = n_elements(cdfnames)
if ncdf ne n_elements(cdfdqds) then begin
    message,' cdfnames/dqds mismatched!',/continue
    return,''
endif

valid = where([find_handle(cdfnames(0)) $
              ,find_handle(cdfnames(1)) $
              ,find_handle(cdfnames(2)) $
              ,find_handle(cdfnames(3)) $
              ,find_handle(cdfnames(4)) $
              ,find_handle(cdfnames(5)) $
              ,find_handle(cdfnames(6)) $
              ,find_handle(cdfnames(7)) $
              ] gt 0,nval)


if nval gt 0 then begin
;
; store cdf data....an array of structures...
;
; now get the stored dcnames...put in cdfdat
;
    for i=0,nval-1 do begin
        get_data,cdfdqds(valid(i)),data=tmp
        
        if not defined(cdfdat) then begin
            cdfdat = create_struct('time',tmp.x,cdfnames(valid(i)),tmp.y)
            cdfout0 = create_struct('time',tmp.x(0),cdfnames(valid(i)),tmp.y(0))
        endif else begin
            cdfdat = create_struct(cdfdat,cdfnames(valid(i)),tmp.y)
            cdfout0 = create_struct(cdfout0,cdfnames(valid(i)),tmp.y(0))
        endelse
    endfor
;
; now create a prototype for structure array...
;
    ntime = n_elements(cdfdat.time)
    cdfout = replicate(cdfout0,ntime)
    protags = tag_names(cdfout0)
    for i=0,nval do begin
        cdfout(*).(i) = (cdfdat.(i))(*)
    endfor
    store_data,'dc_cdf',data = cdfout
    catch,/cancel
    return,dcnames
endif else begin
    catch,/cancel
    return,''
endelse

end
  
