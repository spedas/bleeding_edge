; Test for backstructure
;

;sav_file = '/Users/frederickwilder/back_structure_data.sav'

start_jul = julday(2, 4, 2009, 0, 0)
stop_jul = julday(2, 5, 2009, 0, 0)

start_unix = double(86400) * (start_jul - julday(1, 1, 1970, 0, 0, 0 ))
stop_unix = double(86400) * (stop_jul - julday(1, 1, 1970, 0, 0, 0 ))

start_tai = 702086410l
stop_tai = start_tai + 1*1*24*3600l

mms_get_back_structure, start_unix, stop_unix, backstr, pw_flag, pw_message

die

;save, file = sav_file, backstr, start_jul, stop_jul

;------------------------------------------------------------------------------------------------------------------
; Lets test modification of structure
;------------------------------------------------------------------------------------------------------------------

;restore, sav_file, /verbose

backstr.fom(19) = 145

old_backstr = backstr
new_backstr = backstr

; Modify some segments
loc = [2, 8, 17, 20]

new_backstr.fom(loc) = new_backstr.fom(loc) + 100
new_backstr.changestatus(loc) = 1
new_backstr.sourceid(loc) = 'SITL'

new_backstr.fom(4) = 280
new_backstr.changestatus(4) = 1
new_backstr.sourceid(4) = 'SITL'

new_backstr.changestatus(19) = 2

; This first call only checks the users modification on existing burst segments. In this case, we can only change
; the FOM or delete the segment.

mms_back_structure_check_modifications, new_backstr, old_backstr, mod_error_flags, mod_warning_flags, $
                                        mod_error_msg, mod_warning_msg, mod_error_times, mod_warning_times, $
                                        mod_error_indices, mod_warning_indices


;------------------------------------------------------------------------------------------------------------------
; Now lets add a few new segments to the backstructure that we can test.
;------------------------------------------------------------------------------------------------------------------
start_new = 702101150
stop_new = start_new + 300

new_start = [new_backstr.start, start_new]
new_stop = [new_backstr.stop, stop_new]
new_fom = [new_backstr.fom, 175]
new_seglengths = [new_backstr.seglengths, (stop_new - start_new)/10]
new_changestatus = [new_backstr.changestatus, 0]
new_datasegmentid = [new_backstr.datasegmentid, -1]
new_parametersetid = [new_backstr.parametersetid, 'Revision: 1.7 ; parm_set: Revision: 1.17']
new_ispending = [new_backstr.ispending, 0]
new_inplaylist = [new_backstr.inplaylist, 0]
new_status = [new_backstr.status, 'N/A']
new_numevalcycles = [new_backstr.numevalcycles, 1]
new_sourceid = [new_backstr.sourceid, 'SITL']
new_createtime = [new_backstr.createtime, '2014-03-10 20:31:18']
new_finishtime = [new_backstr.finishtime, '2014-03-10 20:33:01']

; Replace structure elements

str_element, new_backstr, 'start', /delete
str_element, new_backstr, 'start', new_start, /add

str_element, new_backstr, 'stop', /delete
str_element, new_backstr, 'stop', new_stop, /add

str_element, new_backstr, 'fom', /delete
str_element, new_backstr, 'fom', new_fom, /add

str_element, new_backstr, 'seglengths', /delete
str_element, new_backstr, 'seglengths', new_seglengths, /add

str_element, new_backstr, 'changestatus', /delete
str_element, new_backstr, 'changestatus', new_changestatus, /add

str_element, new_backstr, 'datasegmentid', /delete
str_element, new_backstr, 'datasegmentid', new_datasegmentid, /add

str_element, new_backstr, 'parametersetid', /delete
str_element, new_backstr, 'parametersetid', new_parametersetid, /add

str_element, new_backstr, 'ispending', /delete
str_element, new_backstr, 'ispending', new_ispending, /add

str_element, new_backstr, 'inplaylist', /delete
str_element, new_backstr, 'inplaylist', new_inplaylist, /add

str_element, new_backstr, 'status', /delete
str_element, new_backstr, 'status', new_status, /add

str_element, new_backstr, 'numevalcycles', /delete
str_element, new_backstr, 'numevalcycles', new_numevalcycles, /add

str_element, new_backstr, 'sourceid', /delete
str_element, new_backstr, 'sourceid', new_sourceid, /add

str_element, new_backstr, 'createtime', /delete
str_element, new_backstr, 'createtime', new_createtime, /add

str_element, new_backstr, 'finishtime', /delete
str_element, new_backstr, 'finishtime', new_finishtime, /add

mms_back_structure_check_new_segments, new_backstr, new_segs, new_error_flags, orange_warning_flags, $
  yellow_warning_flags, new_error_msg, orange_warning_msg, yellow_warning_msg, $
  new_error_times, orange_warning_times, yellow_warning_times, $
  new_error_indices, orange_warning_indices, yellow_warning_indices

die



local_dir = '/Users/frederickwilder/IDLWorkspace82/abs_data/'

mms_put_back_structure, new_backstr, old_backstr, local_dir, $
                        mod_error_flags, mod_warning_flags, $
                        mod_error_msg, mod_warning_msg, mod_error_times, mod_warning_times, $
                        mod_error_indices, mod_warning_indices, $
                        new_segs, new_error_flags, orange_warning_flags, $
                        yellow_warning_flags, new_error_msg, orange_warning_msg, yellow_warning_msg, $
                        new_error_times, orange_warning_times, yellow_warning_times, $
                        new_error_indices, orange_warning_indices, yellow_warning_indices, $
                        problem_status
                        
print, 'There are warnings and errors, so no submission'

; Since the last submit had errors, lets fix the error.
; For the warnings, we will simply use the '/warning_override' keyword

new_backstr.fom(4) = 121

mms_put_back_structure, new_backstr, old_backstr, local_dir, $
  mod_error_flags, mod_warning_flags, $
  mod_error_msg, mod_warning_msg, mod_error_times, mod_warning_times, $
  mod_error_indices, mod_warning_indices, $
  new_segs, new_error_flags, orange_warning_flags, $
  yellow_warning_flags, new_error_msg, orange_warning_msg, yellow_warning_msg, $
  new_error_times, orange_warning_times, yellow_warning_times, $
  new_error_indices, orange_warning_indices, yellow_warning_indices, $
  problem_status, /warning_override
  
; This second run submits the original backstructure
; Since there are no changed or new segments, the program doesn't submit anything


mms_put_back_structure, old_backstr, old_backstr, local_dir, $
    mod_error_flags, mod_warning_flags, $
    mod_error_msg, mod_warning_msg, mod_error_times, mod_warning_times, $
    mod_error_indices, mod_warning_indices, $
    new_segs, new_error_flags, orange_warning_flags, $
    yellow_warning_flags, new_error_msg, orange_warning_msg, yellow_warning_msg, $
    new_error_times, orange_warning_times, yellow_warning_times, $
    new_error_indices, orange_warning_indices, yellow_warning_indices, $
    problem_status, /warning_override

print, problem_status

end