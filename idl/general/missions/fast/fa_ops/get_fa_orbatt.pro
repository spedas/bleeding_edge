;+
; inputs:
;   start    start time in any format accepted by time_double
;   finish   end time in any format accepted by time_double
;   qtylist  string containing comma separated list of desired columns from
;            the events_data table.  e.g. 'X, Y, Z'
;-

function get_fa_orbatt, start, finish, qtylist

con = sybcon()

if not obj_valid(con) then return, -1

ret = con->send('select count(time) from events_data, ' + $
              'operational_events where time > ' + $
              time_string(start, /sql) + ' and time < ' + $
              time_string(finish, /sql) + ' and data = ident union ' + $
              'select count(time) from events_data, ' + $
              'ephemeris_events where time > ' + $
              time_string(start, /sql) + ' and time < ' + $
              time_string(finish, /sql) + ' and data = ident')

ret = con->fetch(row)
count = row.col1
ret = con->fetch(row)
count = count+row.col1

; create structure name from column list by removing all spaces and
; commas.
strname = 'gfa_' + strcompress(string(str_sep(qtylist, ','),  $
                                      /print),  $
                               /remove_all)

if con->send('select time, ' + qtylist + ' from events_data, ' + $
                'operational_events where time > ' + $
                time_string(start, /sql) + ' and time < ' + $
                time_string(finish, /sql) + ' and data = ident union ' + $
                'select time, ' + qtylist + ' from events_data, ' + $
                'ephemeris_events where time > ' + $
                time_string(start, /sql) + ' and time < ' + $
                time_string(finish, /sql) + ' and data = ident order ' + $
                'by time ', strname) le 0 $
  then begin
    sybclose, con
    return, -1
end

ret = execute('rowarr = make_array(value={' + strname + $
              '}, dim=count)')

i = 0

while con->fetch(row) eq 1 do begin
    rowarr(i) = row
    i = i + 1
end

sybclose, con

return, rowarr
end
