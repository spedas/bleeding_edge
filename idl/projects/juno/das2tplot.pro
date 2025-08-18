;+
; PROCEDURE:
;         das2tplot
;
; PURPOSE:
;         Converts Das2Stream format to tplot variables
;
; FILENAME:
;         filename of the DAS file to load
;
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-12-05 12:03:15 -0800 (Mon, 05 Dec 2016) $
;$LastChangedRevision: 22436 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/juno/das2tplot.pro $
;-

function process_packets, data, newline_flag = newline_flag
  packet_metadata = strmid(data, strpos(data, '<packet>'), strpos(data, '</packet>')+9)
  t = obj_new('das_xml_parser')
  t->ParseFile, packet_metadata, /xml_string
  pkt_metadata = t->getMetadata()
  data_left = strmid(data, strpos(data, '</packet>')+9, strlen(data))
  v = strmid(data_left, 0, strpos(data_left, '<packet>')-10)
  pkt_metadata['data_values'] = strsplit(v, '('+newline_flag+'){1}', /extract, /regex)

  return, pkt_metadata
end

function replace_strings, str, toreplace, replacement
  return, strjoin(strsplit(str, toreplace, /extract, /regex), replacement)
end

pro das2tplot, filename
    if undefined(filename) then begin
        dprint, dlevel = 0, 'Error, must provide a filename to load into tplot variables'
        return
    endif

    openr, lun, filename, /get_lun, /SWAP_IF_BIG_ENDIAN
    line = ''
    lines = ''
    while not eof(lun) do begin
      readf, lun, line
      lines = lines + line
    endwhile
    
    
    prefix_regex = '\[[0-9]{2}\]+[0-9]+' ; matches [00]000741; format of header prefixes
    
    header_prefix = stregex(lines, prefix_regex, /extract)
    
    datafile_without_prefix = strmid(lines, strpos(lines, header_prefix)+strlen(header_prefix), strlen(lines))
    next_header_prefix = stregex(datafile_without_prefix, prefix_regex, /extract)
    data_xml = strmid(lines, strpos(lines, header_prefix)+strlen(header_prefix), strpos(lines, next_header_prefix)-10)
    
    data_xml_clean = replace_strings(data_xml, '(String:){1}', '')
    data_xml_clean = replace_strings(data_xml_clean, '(DatumRange:){1}', '')

    ;;;  IDLffXMLSAX
    t = obj_new('das_xml_parser')
    t->ParseFile, data_xml_clean, /xml_string

    stream_metadata = t->getMetadata()
    
    file_no_stream = strmid(lines, strpos(lines, next_header_prefix)+strlen(next_header_prefix), strlen(lines))
    
    newline_flag = strmid(next_header_prefix, 1, 2)
    pkt_data = process_packets(file_no_stream, newline_flag=':'+newline_flag+':2016') ; note: 2016 here to avoid catching times that include :01:
    data_values = pkt_data['data_values']
    out_data = dblarr(n_elements(data_values), long(pkt_data['nitems']))
    
    ; create the tplot variable
    for time_idx = 0, n_elements(data_values)-1 do begin
      data_arr = strsplit(data_values[time_idx], /extract)
      time = '2016' + data_arr[0] ; need to add the 2016 back, because we're using it up ^^^^^^^^^^
      append_array, times, time_double(time_parse(time))
      out_data[time_idx, *] = data_arr[1:*]
    endfor
    
    varname = 'juno_'+stream_metadata['name']
    V_tag = float(strsplit(pkt_data['yTags'], ',', /extract))

    store_data, varname, data={x: times, y: out_data, v: V_tag}
    options, varname, spec=1
   ; ylim, varname, 40.6430, 1000., 1
   ; zlim, varname, 0, 0, 0
   
end