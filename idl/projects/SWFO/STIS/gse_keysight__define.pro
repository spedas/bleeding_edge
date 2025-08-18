;+
;gse_keysight
;  This object works with the common block files to decommutate data from Keysight power supplies
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2023-11-13 07:46:41 -0800 (Mon, 13 Nov 2023) $
; $LastChangedRevision: 32242 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/gse_keysight__define.pro $
;-

COMPILE_OPT IDL2


pro gse_keysight::read,payload,source_dict = source_dict

  dprint,dlevel=4,verbose=self.verbose,n_elements(payload),' Bytes for Handler: "',self.name,'"'
  ;if self.verbose eq 5 then hexprint,payload
  self.nbytes += n_elements(payload)
  self.npkts  += 1

  dprint,verbose=self.verbose,dlevel=3,'"'+string(payload)+'"'
  if self.run_proc then begin
    cmbhdr =  source_dict.cmbhdr

    fnan = !values.f_nan
    dnan = !values.d_nan
    sample={ $
      time:dnan, $
      dtime:fnan, $
      V: replicate(fnan,6), $
      I: replicate(fnan,6), $
      v1: fnan, $
      v2: fnan, $
      v3: fnan, $
      I1: fnan, $
      I2: fnan, $
      I3: fnan, $
      gap:0 $
      }
    
    str = string(payload)
    time1 = cmbhdr.time
    psnum = fix(cmbhdr.source)
    ss = strsplit(/extract,str,' ')
;printdat,str
    if n_elements(ss) eq 13 then begin
      time2 = time_double(ss[0])
      vals = float(ss[1:*])
;print,vals
      sample.time = time1
      sample.dtime = time2-time1  + 7 *3600d   ; correct this after time is corrected
 ;     dprint,sample.dtime
      sample.V =vals[[ 0,2,4,6,8,10] ]
      sample.I =vals[[ 1,3,5,7,9,11] ]   
      sample.v1 = vals[ 0 ]
      sample.v2 = vals[ 4 ]   
      sample.v3 = vals[ 8 ]
      sample.i1 = vals[ 1 ]
      sample.i2 = vals[ 5 ]
      sample.i3 = vals[ 9 ]
    endif
    tname = 'KEYSIGHT'+strtrim(psnum,2)
    
    store_data,/append,tname+'_',data=sample,tagnames='DTIME V I V? I?',gap=sample.gap

;    firstsample = self.dyndata.size  eq 0
;    self.dyndata.append,sample
;    if firstsample then begin
;      store_data,tname,data = self.dyndata,tagnames='DTIME V I V? I?',gap='GAP'
;    endif
    

    if debug(4,self.verbose,msg=self.name + ' handler') then begin
      ;print,strtrim(psnum) + '  '+string(str)
      printdat,vals
      ;print,vals
    endif
  endif
end



PRO gse_keysight__define
  void = {gse_keysight, $
    inherits socket_reader, $    ; superclass
    ddata: obj_new(),  $
    powersupply_num:0    $           ; not actually used
  }
END


