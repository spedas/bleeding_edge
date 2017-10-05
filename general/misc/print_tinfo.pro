;+
;
; Procedure:  print_tinfo
; 
; Purpose:
;             prints info on a tplot variable, including dimensions 
;             and what each dimension represents
; 
; Input:
;             tplot_name: name of the tplot variable to print info on; also
;             accepts tplot variable #
; 
; Keywords:
;             time:   show the first and last times in the variable
;             help:   show the output of help, /structure, data 
;                     and help, /structure, dlimits for the variable
; Note:
;             This procedure assumes that there haven't been any modifications
;             to the structure of the tplot variable; i.e., if you transpose the order
;             of the indices in d.Y manually using get_data, store_data, 
;             this routine will not know that (and will incorrectly report
;             the 'data format')
;             
; Example:  
;             MMS> print_tinfo, 'mms1_hpca_hplus_phase_space_density'
;                 *** Variable: mms1_hpca_hplus_phase_space_density
;                 ** Structure <221f3690>, 4 tags, length=165121216, data length=165121212, refs=1:
;                 X               DOUBLE    Array[20456]
;                 Y               DOUBLE    Array[20456, 63, 16]
;                 V1              DOUBLE    Array[16]
;                 V2              FLOAT     Array[63]
;                 Data format: [Epoch, mms1_hpca_ion_energy, mms1_hpca_polar_anode_number]
;                 v1: mms1_hpca_polar_anode_number
;                 v2: mms1_hpca_ion_energy
;  
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-08-23 15:30:42 -0700 (Tue, 23 Aug 2016) $
; $LastChangedRevision: 21698 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/print_tinfo.pro $
;-


; takes name of a tplot variable as a string, prints out information on the variable
pro print_tinfo, tplot_name, time = time, help = help
    if tnames(tplot_name) eq '' then begin
        dprint, dlevel = 1, 'Error, no tplot variable named ' + tplot_name + ' found.'
        return
    endif
    
    ; allow for tvariable # instead of name
    if is_num(tplot_name) then tplot_name = tnames(tplot_name)
    
    print, '*** Variable: ' + tplot_name
    get_data, tplot_name, data=d, dlimits=dl
    if is_struct(d) && ~undefined(help) then help, /st, d
    if ~undefined(time) then begin
      print, 'Start time: ' + time_string(d.X[0])
      print, 'End time: ' + time_string(d.X[n_elements(d.X)-1])
    endif 
    if is_struct(d) && ~undefined(help) then help, /st, dl
    if is_struct(dl.cdf) && ~undefined(help) then help, /st, dl.cdf
    

    if is_struct(dl.cdf.vatt) then begin
      ndimens = ndimen(d.Y)
      metadata = (dl.cdf.vatt)[0]
      help, d, /structure ; show the dimensions before showing what data they represent
      if ndimens eq 4 then print, 'Data format: ['+metadata.depend_0+', '+metadata.depend_3+', '+metadata.depend_2+', '+metadata.depend_1+']'
      if ndimens eq 3 then print, 'Data format: ['+metadata.depend_0+', '+metadata.depend_2+', '+metadata.depend_1+']'
      if ndimens eq 2 then begin
        str_element, metadata, 'depend_1', dep1, success=s
        ; not all have depend_1; if not, use fieldnam
        if s then $
          print, 'Data format: ['+metadata.depend_0+', '+metadata.depend_1+']' $
        else $
          print, 'Data format: ['+metadata.depend_0+', '+metadata.fieldnam+']'
      endif
    endif
    if tag_exist(d, 'v1') then print, 'v1: ' + metadata.depend_1
    if tag_exist(d, 'v2') then print, 'v2: ' + metadata.depend_2
    if tag_exist(d, 'v3') then print, 'v3: ' + metadata.depend_3
end