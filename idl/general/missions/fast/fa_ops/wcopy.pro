;	@(#)wcopy.pro	1.4	04/29/99
;+
;
;  Copies the contents of one IDL window into another. By default,
;  current graphics window is copied into a new window. Very handy to
;  save a previous plot, for comparison with a new one. Tested only
;  with X. 
;
;-
pro wcopy, from = from, to = to

if !d.name ne 'X' then begin
    message,'only works for X',/continue
    return
endif

if not defined(from) then from = !d.window

window_save = !d.window

wshow, iconic=0
wset,from
a = tvrd()
as = size(a)
xsize = as[1]
ysize = as[2]

if defined(to) then begin
    if to ge 32 then begin 
        catch, err_stat
        if err_stat ne 0 then begin
            message, 'Unable to write to window ' + $
              ''+str(to)+'...',/continue
            wset, window_save
            return
        endif
        wset, to
    endif else begin
        window, to, xsize = xsize, ysize = ysize
    endelse
endif else begin
    window,/free, xsize = xsize, ysize = ysize
endelse

tv, a

wset, window_save
return    
end
