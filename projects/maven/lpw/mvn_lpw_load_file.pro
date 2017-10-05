;+
;PROCEDURE:   mvn_lpw_load_file
;PURPOSE:
;  Decomutater of the LPW telemetry data
;  This call uses three different ways to get data: cdf, L0 and ground data (no sc header)
;  This reads one file and creates the requested data products
;  Presently cannot merge two files <--------
;  
;
;USAGE:
;  mvn_lpw_load,filename, tplot_var=tplot_var, filetype=filetype, packet=packet,board=board, compression=compression, use_spice=use_spice
;
;INPUTS:
;       filename:      The full filename (including path) of a binary file containing zero or more LPW APID's.  
;
;KEYWORDS:
;       filetype:   'cdl' archive files (L2-data), 'L0' (L0 data, binary file with sc header),  
;                    or 'ground'/'ground_dir'a (file from ground testing, binary file without sc header)
;                    Default is l0. Entry can be upper or lower case.
;                    
;       packet:     Which packets to read into memeory, default all packets ['HSK','EUV','AVG','SPEC','HSBM','WPK'] . Entry can be
;                   upper or lower case.
;       
;       board:      board_names=['EM1','EM2','EM3','FM'] 
;       
;       tplot_var  'all' or 'sci' Which tplot variables to produce. 'sci' produces tplot variables which have physical unit 
;                                 associated with them, and is the default. 'all' produces all tplot variables and includes 
;                                 master cycle information etc. Can be upper or lower case.
;                                 
;       use_compression: String: 'y' or 'n'. For EUV ground data only. Default is 'y'. Upper or lower case accepted.
;       
;       nospice: set /nospice to not use SPICE within the pkt routines. SPICE must still be installed to use SPICE even if this 
;                keyword is not set.
;
;CREATED BY:   Laila Andersson  05-15-13
;FILE: mvn_lpw_load.pro
;VERSION:   1.0
;LAST MODIFICATION: 
; 2014, APril 17 CF: added kernel_dir keyword
; 2014, April 15, CF: made default filetype='L0'; added SPICE y/n keyword; fixed bug with compression keyword
; 2014, March 21, CF: added keyword spice to pkt routines
; 2014, March 12, Chris Fowler - added keyword "compression"
; 2014, Jannuary 5, Laila Andersson - added 'ground_dir'
; 2013, July 11th, Chris Fowler - added keyword tplot_var=['all', 'sci']  
;                   05/15/13
;25/04/14 L. Andersson changed spice/kernerl_dir so onlu spice is used and contains kernel_dir
;29/04/14 CF: Have automated kernel finding into routine so kernel_dir is not required to be set now. 
;30/04/14 CF: Reomved keyword kernel_dir. No longer needed as this is sorted in mvn_lpw_anc_wrapper. Edited /nospice keyword. 
;13/05/14 CF: Changed name to mvn_lpw_load_file       
;20/05/2014 CF: fixed bug with ground keyword.  
;;140718 clean up for check out L. Andersson 
;20140807: CF: fixed case statement - not recognizing 'or' statement - filetype must now be lowercase. 
;2014-10-06: CF: 'packet' is converted to all uppercase, so that user input can be any case. filetype converted to lower case to match existing code, but
;              ;user can now input as any case.     
;-

pro mvn_lpw_load_file,filename, tplot_var=tplot_var, filetype=filetype, packet=packet,board=board, use_compression=use_compression, nospice=nospice

sl = path_sep()  ;/ for unix, \ for windows

  if keyword_set(filetype) then filetype=strupcase(filetype) else filetype='L0' ;print,'mvn_lpw_load: No filetype was provided'
  if keyword_set(packet) then packet=strupcase(packet) else packet=['HSK','EUV','AVG','SPEC','HSBM','WPK']               ;default all
  
  if keyword_set(packet) and packet[0] eq 'ALL' then packet=['HSK','EUV','AVG','SPEC','HSBM','WPK']  
  if keyword_set(board) then board=board else board='FM'
  if keyword_set(tplot_var) then tplot_var=strupcase(tplot_var) else tplot_var='SCI'     ;default is science
  if keyword_set(use_compression) then begin
      use_compression = strupcase(use_compression)
      if use_compression eq 'Y' then compression = 1
      if use_compression eq 'N' then compression = 0
  endif else compression = 1           ;default is compression = 1 ('y') 
  
  ;Setting /nospice means we don't want to use SPICE. This means the keyword spice, in the packet routines, is not set. This keyword must be set
  ;for the pkt routines to use spice. So not setting it means they won't try to use spice. If we want to use spice we still need to check it's 
  ;installed before we can set the keyword spice, to feed into the pkt routines below:
  if not keyword_set(nospice) then begin
      if spice_test() eq 1 then spice = 1 else spice=0  ;spice_test is 1 for installed, 0 for not installed    
  endif else spice=0 
  ;Note: if a keyword eq 0, IDL sees it as not being set.
  
  
  Case filetype of 
      'L0':   begin                            
                     mvn_lpw_r_header_l0, filename,output,packet=packet 
                     tmp=size(output)
                     if tmp(0) NE 0 then begin                                                              ; check if any packets was found                                        
                         mvn_lpw_pkt_instrument_constants,board,lpw_const2=lpw_const                        ; set up the constants used in the below routines 
                         if output.p1+output.p2 +output.p3 +output.p4 +output.p5 GT 0 THEN mvn_lpw_wpkt,output,lpw_const             
                         mvn_lpw_pkt_atr,output,lpw_const,tplot_var=tplot_var,spice=spice
                         mvn_lpw_pkt_euv,output,lpw_const,tplot_var=tplot_var,spice=spice
                         mvn_lpw_pkt_adr,output,lpw_const, tplot_var=tplot_var,spice=spice
                         mvn_lpw_pkt_hsk,output ,lpw_const, tplot_var=tplot_var,spice=spice
                         mvn_lpw_pkt_e12_dc, output, lpw_const,'act', tplot_var=tplot_var,spice=spice
                         mvn_lpw_pkt_e12_dc, output, lpw_const,'pas', tplot_var=tplot_var,spice=spice
                         mvn_lpw_pkt_swp,output,lpw_const,1,tplot_var=tplot_var,spice=spice                           ;need the sweep to be read in before
                         mvn_lpw_pkt_swp,output,lpw_const,2,tplot_var=tplot_var,spice=spice                             ;need the sweep to be read in before
                         mvn_lpw_pkt_spectra,output,lpw_const,'act','lf',tplot_var=tplot_var,spice=spice
                         mvn_lpw_pkt_spectra,output,lpw_const,'act','mf',tplot_var=tplot_var,spice=spice
                         mvn_lpw_pkt_spectra,output,lpw_const,'act','hf',tplot_var=tplot_var,spice=spice
                         mvn_lpw_pkt_spectra,output,lpw_const,'pas','lf',tplot_var=tplot_var,spice=spice
                         mvn_lpw_pkt_spectra,output,lpw_const,'pas','mf',tplot_var=tplot_var,spice=spice
                         mvn_lpw_pkt_spectra,output,lpw_const,'pas','hf',tplot_var=tplot_var,spice=spice
get_data,'mvn_lpw_hsbm_spec_hf',data=data
help,data
                         mvn_lpw_pkt_hsbm, output,lpw_const,'lf',tplot_var=tplot_var,spice=spice
                         mvn_lpw_pkt_hsbm, output,lpw_const,'mf',tplot_var=tplot_var,spice=spice
                         mvn_lpw_pkt_hsbm, output,lpw_const,'hf',tplot_var=tplot_var,spice=spice
get_data,'mvn_lpw_hsbm_spec_hf',data=data
help,data
                         
                         mvn_lpw_pkt_htime, output,lpw_const,tplot_var=tplot_var                                                                                               
                     endif
                      end
                      
      'CDF': begin
                      spice = 0 ;No spice when loading CDF files
                             ;print,'mvn_lpw_load: Not yet written the CDF loader, sorry'
                            cdf_files = mvn_lpw_load_find_cdf(filename)  ;string array of full cdf directories
                            
                            if size(cdf_files, /type) eq 7 then mvn_lpw_load_cdf, cdf_files else begin  ;feed into here to load the cdf files into memory                           
                                print, "#### WARNING ####: mvn_lpw_load_file: No cdf files for date entered. Returning."
                                retall
                            endelse
                       end
                       
      'GROUND': begin              ;use the file name given in the loader. Filename must be include path to file
                     spice = 0. ;don't use SPICE on ground data even if installed, as no SPICE kernels before launch!
                     tplot_var='ALL'
                     mvn_lpw_r_header, filename,output,compressed=compression,packet=packet   
                     tmp=size(output)
                     if tmp(0) NE 0 then begin                                                              ; check if any packets was found   
                        mvn_lpw_pkt_instrument_constants,board,lpw_const2=lpw_const                         ; set up the constants used in the below routines 
                        if output.p1+output.p2 +output.p3 +output.p4 +output.p5 GT 0 THEN mvn_lpw_wpkt,output,lpw_const             
                        mvn_lpw_pkt_atr,output,lpw_const,tplot_var=tplot_var,spice=spice
                        mvn_lpw_pkt_euv,output,lpw_const,tplot_var=tplot_var,spice=spice        
                        mvn_lpw_pkt_adr,output,lpw_const,tplot_var=tplot_var,spice=spice
                        mvn_lpw_pkt_hsk,output ,lpw_const,tplot_var=tplot_var,spice=spice
                        mvn_lpw_pkt_e12_dc,output,lpw_const,tplot_var=tplot_var,'pas',spice=spice
                        mvn_lpw_pkt_e12_dc,output,lpw_const,tplot_var=tplot_var,'act',spice=spice
                        mvn_lpw_pkt_swp,output,lpw_const,1,tplot_var=tplot_var,spice=spice                              ;need the sweep to be read in before
                        mvn_lpw_pkt_swp,output,lpw_const,2,tplot_var=tplot_var,spice=spice                              ;need the sweep to be read in before
                        mvn_lpw_pkt_spectra,output,lpw_const,'act','lf',tplot_var=tplot_var,spice=spice
                        mvn_lpw_pkt_spectra,output,lpw_const,'act','mf',tplot_var=tplot_var,spice=spice
                        mvn_lpw_pkt_spectra,output,lpw_const,'act','hf',tplot_var=tplot_var,spice=spice
                        mvn_lpw_pkt_spectra,output,lpw_const,'pas','lf',tplot_var=tplot_var,spice=spice
                        mvn_lpw_pkt_spectra,output,lpw_const,'pas','mf',tplot_var=tplot_var,spice=spice
                        mvn_lpw_pkt_spectra,output,lpw_const,'pas','hf',tplot_var=tplot_var,spice=spice
                        mvn_lpw_pkt_hsbm, output,lpw_const,'lf',tplot_var=tplot_var,spice=spice
                        mvn_lpw_pkt_hsbm, output,lpw_const,'mf',tplot_var=tplot_var,spice=spice
                        mvn_lpw_pkt_hsbm, output,lpw_const,'hf',tplot_var=tplot_var,spice=spice
                        mvn_lpw_pkt_htime, output,lpw_const,tplot_var=tplot_var                                                                                        
                     endif
                   end  
     'GROUND_DIR': begin                                                            ;if the packets are in the same directory than this can be selected and only give the directory
                    spice = 0  ;don't use spice on ground data as no spice kernels before launch!
                    mvn_lpw_pkt_instrument_constants,board,lpw_const2=lpw_const                            ; set up the constants used in the below routines 
                    tplot_var='ALL'
                    filter = '*.dat'                                                                       ; search all data files       
                    filename1 = file_search(filename,filter,count=count)
                    for i =0 , count-1 do begin
                       print,'$$$$ ',i,'   ',filename1[i]
                       mvn_lpw_r_header,filename1[i],output, compressed=compression,packet=packet
                       if output.p1+output.p2 +output.p3 +output.p4 +output.p5 GT 0 THEN mvn_lpw_wpkt,output,lpw_const             
                       mvn_lpw_pkt_atr,output,lpw_const,tplot_var=tplot_var,spice=spice
                       mvn_lpw_pkt_euv,output,lpw_const,tplot_var=tplot_var,spice=spice             
                       mvn_lpw_pkt_adr,output,lpw_const,tplot_var=tplot_var,spice=spice
                       mvn_lpw_pkt_hsk,output ,lpw_const,tplot_var=tplot_var,spice=spice
                       mvn_lpw_pkt_e12_dc,output,lpw_const,tplot_var=tplot_var,'pas',spice=spice
                       mvn_lpw_pkt_e12_dc,output,lpw_const,tplot_var=tplot_var,'act',spice=spice
                       mvn_lpw_pkt_swp,output,lpw_const,1,tplot_var=tplot_var,spice=spice                              ;need the sweep to be read in before
                       mvn_lpw_pkt_swp,output,lpw_const,2,tplot_var=tplot_var,spice=spice                              ;need the sweep to be read in before
                       mvn_lpw_pkt_spectra,output,lpw_const,'act','lf',tplot_var=tplot_var,spice=spice
                       mvn_lpw_pkt_spectra,output,lpw_const,'act','mf',tplot_var=tplot_var,spice=spice
                       mvn_lpw_pkt_spectra,output,lpw_const,'act','hf',tplot_var=tplot_var,spice=spice
                       mvn_lpw_pkt_spectra,output,lpw_const,'pas','lf',tplot_var=tplot_var,spice=spice
                       mvn_lpw_pkt_spectra,output,lpw_const,'pas','mf',tplot_var=tplot_var,spice=spice
                       mvn_lpw_pkt_spectra,output,lpw_const,'pas','hf',tplot_var=tplot_var,spice=spice
                       mvn_lpw_pkt_hsbm, output,lpw_const,'lf',tplot_var=tplot_var,spice=spice
                       mvn_lpw_pkt_hsbm, output,lpw_const,'mf',tplot_var=tplot_var,spice=spice
                       mvn_lpw_pkt_hsbm, output,lpw_const,'hf',tplot_var=tplot_var,spice=spice
                       mvn_lpw_pkt_htime, output,lpw_const,tplot_var=tplot_var
                     endfor                                                                                       
                     end
  ELSE:              BEGIN 
                         print,' mvn_lpw_load_file: no filetype match was found ',filename,' ',filetype
                     END                    
  ENDCASE                             
  ;###############################################################
end

