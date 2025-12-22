;+
;PRO: update_fa_att, start, finish
;NAME: update_fa_att
;PURPOSE:
;Update attitude rows in database with level 0 attitude from FDF files.
;
;INPUT:
;  start   Any time acceptable by time_string()
;  finish  Any time acceptable by time_string()
;
;KEYWORDS:
;  null    update only null rows. 
;
;NOTE:
;Affects events_data table. Uses $FASTCONFIG/fast_dbupdate.conf file
;to get user, password, and database name to access the database to update.
;-



pro update_fa_att, start, finish

con = sybcon(appname='update_fa_att', config=(getenv('FASTCONFIG') + $
                                              '/fast_dbupdate.conf'))

if not obj_valid(con) then return

print, systime()
st = systime(1)

print, 'getting event times from database'

rowcriteria = '(attlevel = 0 or attlevel = NULL)'
if keyword_set(null) then rowcriteria = 'attlevel = NULL'

; get number of rows.

ret = con->send('select count(time) from events_data, ' + $
                'operational_events where time > ' + $
                time_string(start, /sql) + ' and time < ' + $
                time_string(finish, /sql) + ' and data = ident and ' + $
                rowcriteria + ' union ' + $
                'select count(time) from events_data, ' + $
                'ephemeris_events where time > ' + $
                time_string(start, /sql) + ' and time < ' + $
                time_string(finish, /sql) + ' and data = ident and ' + $
                rowcriteria')

count = 0
if con->fetch(row) eq 1 then count = row.col1
if con->fetch(row) eq 1 then count = count + row.col1

if count eq 0 then begin
    print, 'no rows with attlevel = 0 or NULL in time range to update'
    sybclose, con
    return
end
 
; make query for actual data.
   
ret = con->send('select time, ident from events_data, ' + $
                'operational_events where time > ' + $
                time_string(start, /sql) + ' and time < ' + $
                time_string(finish, /sql) + ' and data = ident and ' + $
                rowcriteria + ' union ' + $
                'select time, ident from events_data, ' + $
                'ephemeris_events where time > ' + $
                time_string(start, /sql) + ' and time < ' + $
                time_string(finish, /sql) + ' and data = ident and ' + $
                rowcriteria + ' order by time ',  $
                'update_fa_att_st')

rowarr = make_array(value={update_fa_att_st}, dim=count)

i = 0l
while con->fetch(row) eq 1 do begin
    rowarr(i) = row
    i = i + 1
end

print, 'getting attitude'

att = get_fa_fdf_att(rowarr.time)

print, 'updating database '

for i = 0l, count-1 do begin
;    print, i, '  ' + time_string(rowarr(i).time), rowarr(i).ident, att(i)
    if not finite(att(i).x) then begin
        ret = con->send('update events_data set attlevel = 0, ' + $
                        'Bphase = NULL, ' + $
                        'LX = NULL, ' + $
                        'LY = NULL, ' + $
                        'LZ = NULL, ' + $
                        'Z_sun = NULL, ' + $
                        'lambda = NULL, ' + $
                        'phi = NULL ' + $
                        'where ident = convert(numeric(8,0), ' +  $
                        string(rowarr(i).ident) + ')' )
    endif else begin
        ret = con->send('update events_data set attlevel = 0, ' + $
                        'Bphase = NULL, ' + $
                        'LX = ' + string(att(i).x) + ', ' + $
                        'LY = ' + string(att(i).y) + ', ' + $
                        'LZ = ' + string(att(i).z) + ', ' + $
                        'Z_sun = ' + string(att(i).zsun) + ', ' + $
                        'lambda = ' + string(att(i).lambda) + ', ' + $
                        'phi = ' + string(att(i).phi) + $
                        'where ident = convert(numeric(8,0), ' +  $
                        string(rowarr(i).ident) + ')' )
    endelse
end

print, long(count), ' rows updated in ', systime(1) - st, ' seconds'
print, systime()

sybclose, con

end
    
