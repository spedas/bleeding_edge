;+
;gse_keithley
;  This object works with the common block files to decommutate data from Keysight power supplies
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2023-11-13 07:46:41 -0800 (Mon, 13 Nov 2023) $
; $LastChangedRevision: 32242 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/gse_keithley__define.pro $
;-

COMPILE_OPT IDL2


pro gse_keithley::read,payload,source_dict = source_dict

  self.eol =10
  dprint,dlevel=4,verbose=self.verbose,n_elements(payload),' Bytes for Handler: "',self.name,'"'
  ;if self.verbose eq 5 then hexprint,payload
  self.nbytes += n_elements(payload)
  self.npkts  += 1

  dprint,verbose=self.verbose,dlevel=3,'"'+string(payload)+'"'
  if self.run_proc then begin
    if isa(source_dict,'dictionary') then   cmbhdr =  source_dict.cmbhdr else cmbhdr= {time:0d,source:0}

    fnan = !values.f_nan
    dnan = !values.d_nan
    sample={ $
      time:dnan, $
      dtime:fnan, $
      I:  fnan, $
      s1: fnan, $
      s2: fnan, $
      gap:0 $
      }
    
    str = string(payload)
    time1 = cmbhdr.time
    psnum = fix(cmbhdr.source)
    ss = strsplit(/extract,str,' ')
;printdat,str
    size = self.dyndata.size
    if n_elements(ss) ge 3 then begin
      time2 = time_double(ss[0])
      vals = float(ss[1:*])
;print,vals
      sample.time = time1
      sample.dtime = time2-time1    ; correct this after time is corrected
      sample.I = vals[0] * 1e12
      sample.s1 = vals[1]
      sample.s2 = vals[2]
 ;     dprint,sample.dtime
     ; printdat,sample
      self.dyndata.append,sample
    endif
    tname = 'Keithley'+strtrim(psnum,2)
   ; if size eq 0 then store_data,tname,data = self.dyndata
  ;  store_data,/append,tname+'_',data=sample,tagnames='DTIME V I V? I?',gap=sample.gap

;    firstsample = self.dyndata.size  eq 0
;    self.dyndata.append,sample
;    if firstsample then begin
;      store_data,tname,data = self.dyndata,tagnames='DTIME V I V? I?',gap='GAP'
;    endif
    

    if debug(4,self.verbose,msg=self.name + ' handler') then begin
      ;print,strtrim(psnum) + '  '+string(str)
      printdat,vals
      printdat,source_dict
      ;print,vals
    endif
  endif
end



PRO gse_keithley__define
  void = {gse_keithley, $
    inherits socket_reader, $    ; superclass
    ddata: obj_new(),  $
    powersupply_num:0    $           ; not actually used
  }
END


