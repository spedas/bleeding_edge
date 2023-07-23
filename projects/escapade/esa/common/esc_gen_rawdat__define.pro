;+
;  ESC_GEN_RAWDAT
;  This basic object is the entry point for defining and obtaining all data for all apids
; $LastChangedBy: rlivi04 $
; $LastChangedDate: 2023-06-10 00:23:31 -0700 (Sat, 10 Jun 2023) $
; $LastChangedRevision: 31893 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/escapade/esa/common/esc_gen_rawdat__define.pro $
;-



FUNCTION esc_gen_rawdat::Init, _EXTRA=ex

   COMPILE_OPT IDL2
   void = self->IDL_Object::Init()
   self.dlevel = 2
   self.last_raw_data_p = ptr_new(!null)
   self.last_raw_pkt    = ptr_new(!null)
   self.name = 'esc_rawdat'
   nan = !VALUES.D_NAN

   ;; Raw EESA Data as ByteArray
   self.data = dynamicarray(!null, name = self.name)

   ;; Analog Housekeeping Polynomials (A1)
   self.ahkp_poly[[19,23,24,26,27,28,30,31],0] = $
    [-3.72/8.01, -3.72/8.01, 137.01, 137.01, -6.44/5., 137.01, 137.01, -6.44/5.]
   self.ahkp_poly[*,1] = [4.*1000./(0.787+0.392)/4095., 4*1001./4095.,             $
                          4*1001.33/1.33/4095.,         4*1001./4095.,             $
                          4/4095./0.0492,               4*1001./4095.,             $
                          4/4095.*25.,                  4*1001./4095.,             $
                          4*1000.787/0.787/4095,        4*1052.3/52.3/4095,        $
                          4*1000.787/0.787/4095,        4*1052.3/52.3/4095.,       $
                          4/4095.*25,                   4*1001./4095, 4/4095.*25., $
                          4*500/4095.,                  4*10000./(1.3+1.37)/4095., $
                          4*3./4095.,                   4/4095.,                   $
                          4/(4096*0.00801),             4./4095./0.13,             $
                          4*2/4095.,                    4/(4095*0.001),            $
                          4/(4096*0.00801),            -0.15828,                   $
                          4*2/4095.,                   -0.15828,                   $
                          4/(4095*0.005),              -0.15828,                   $
                          (4*20/6.8)/4095,             -0.15828,                   $
                          1.221]
   self.ahkp_poly[[24,26,28,30],2] =  1.1978E-4 
   self.ahkp_poly[[24,26,28,30],3] = -5.4877E-8
   self.ahkp_poly[[24,26,28,30],4] =  1.2712E-11
   self.ahkp_poly[[24,26,28,30],5] = -1.1790E-15

   ;; Electron Science Products
   e_sci = {nrg_spec:intarr(64), ano_spec:intarr(16), def_spec:intarr(16)}

   self.e_sci_empty = ptr_new(e_sci)
   self.e_sci_last  = ptr_new(e_sci)
   self.e_sci_tags  = tag_names(e_sci)
   self.e_sci = dynamicarray(!null, name = 'Electron_Science_Products')
   self.e_sci_tplot = 0



   ;; Analog Housekeeping
   str_ahkp = {imcpv:nan,   idef1v:nan,    emcpv:nan,    edef1v:nan, imcpi:nan,     $
               idef2v:nan,  emcpi:nan,     edef2v:nan,   irawv:nan,  ispoilerv:nan, $
               erawv:nan,   espoilerv:nan, irawi:nan,    ihemiv:nan, erawi:nan,     $
               ehemiv:nan,  iaccelv:nan,   p8v:nan,      p1_5v:nan,  p5vi:nan,      $
               iacceli:nan, p5v:nan,       p1_5vi:nan,   n5vi:nan,   ianalt:nan,    $
               n5v:nan,     digitalt:nan,  p8vi:nan,     eanalt:nan, n8v:nan,       $
               eanodet:nan, n8vi:nan,      $
               time:0.D, gap:0}

   self.ahkp_empty = ptr_new(str_ahkp)
   self.ahkp_last  = ptr_new(str_ahkp)
   self.ahkp_tags  = tag_names(str_ahkp)
   self.ahkp = dynamicarray(!null, name = 'Analog_Housekeeping')
   self.ahkp_tplot = 0


   
   ;; Digital Housekeeping
   self.dhkp_trans = [indgen(1)   +  0, nan, $
                      indgen(2)   +  3, nan, $
                      indgen(27)  +  9, nan, nan, $
                      indgen(1)   + 47, nan, nan, $
                      indgen(21)  + 55, nan, $
                      indgen(3)   + 79, nan, nan, $
                      indgen(102) + 89, nan, $
                      indgen(52)  +195, nan, $
                      indgen(2)   +249, $
                      nan, nan, nan, nan, nan, $
                      indgen(4)   +268]

   nan = ulong(0)
      
   str_dhkp = {$ 
                     cmds_received:nan,    cmd_errors:nan,      cmd_known:nan, $
                     fgpa_rev:nan,         mode_id:nan,         i_hv_mode:nan, $
                     e_hv_mode:nan,        hv_key_enabled:nan,  hv_enabled:nan,$
                     board_id:nan, $
                     reset_cnt:nan,        ihemi_cdi:nan,       ispoiler_cdi:nan, $
                     idef1_cdi:nan,        idef2_cdi:nan,       imcp:nan, $
                     iraw_hv:nan,          iaccel:nan,          ehemi_cdi:nan,$
                     espoiler_cdi:nan,     edef1_cdi:nan,       edef2_cdi:nan, $
                     emcp:nan,             eraw_hv:nan,         ihemi_addr:nan,$
                     ispoiler_addr:nan,    idef1_addr:nan,      idef2_addr:nan, $
                     ehemi_addr:nan,       espoiler_addr:nan,   edef1_addr:nan, $
                     edef2_addr:nan,       mlut_addr:nan,       mlimit_addr:nan, $
                     dump_addr:nan,        cmd_check_addr:nan,  itp_step_mode:nan,   $
                     tof_tp_mode:nan,      test_pulser_ena:nan, dll_pulser_mode:nan, $
                     ext_pulser_mode:nan,  dll1_select:nan,     dll2_select:nan, $
                     dll_stop_ena:nan,     dll_start_ena:nan,   dll_start_tp:nan, $
                     dll_stop_tp:nan,      easic_dout:nan,      act_open_stat:nan, $
                     act_close_stat:nan,   ecover_stat:nan,     icover_stat:nan, $
                     last_actuation:nan,   act_err:nan,         act_override:nan, $
                     act_timeout_cvr:nan,  act_timeout_atn:nan, actuation_time:nan, $
                     active_time:nan,      act_cooltime:nan, $

                     ch_offset_0:nan,ch_offset_1:nan,ch_offset_2:nan,ch_offset_3:nan,$
                     ch_offset_4:nan,ch_offset_5:nan,ch_offset_6:nan,ch_offset_7:nan,$
                     ch_offset_8:nan,ch_offset_9:nan,ch_offset_10:nan,ch_offset_11:nan,$
                     ch_offset_12:nan,ch_offset_13:nan,ch_offset_14:nan,ch_offset_15:nan,$
                     
                     raw_events_ena:nan,   raw_events_mode:nan, raw_events_chan:nan, $
                     raw_channel_mask:nan, raw_min_tof_val:nan, mhist_chan_mask:nan, $
                     tof_hist_ena:nan,     accum_rates_ena:nan, accum_rates1:nan, $
                     accum_rates2:nan,     accum_rates3:nan,    fast_hkp_ena:nan, $
                     fast_hkp_chan:nan, $

                     valid_0:nan, valid_1:nan, valid_2:nan, valid_3:nan,$
                     valid_4:nan, valid_5:nan, valid_6:nan, valid_7:nan,$
                     valid_8:nan, valid_9:nan, valid_10:nan,valid_11:nan,$
                     valid_12:nan,valid_13:nan,valid_14:nan,valid_15:nan,$

                     non_valid_0:nan, non_valid_1:nan, non_valid_2:nan, non_valid_3:nan,$
                     non_valid_4:nan, non_valid_5:nan, non_valid_6:nan, non_valid_7:nan,$
                     non_valid_8:nan, non_valid_9:nan, non_valid_10:nan,non_valid_11:nan,$
                     non_valid_12:nan,non_valid_13:nan,non_valid_14:nan,non_valid_15:nan,$

                     start_no_stop_0_1:nan, start_no_stop_2_3:nan, start_no_stop_4_5:nan, start_no_stop_6_7:nan,$
                     start_no_stop_8_9:nan, start_no_stop_10:nan,start_no_stop_11:nan,$
                     start_no_stop_12:nan,  start_no_stop_13:nan,start_no_stop_14:nan,start_no_stop_15:nan,$

                     emptyrate1:nan, $
                     
                     stop_no_start_0:nan, stop_no_start_1:nan, stop_no_start_2:nan, stop_no_start_3:nan,$
                     stop_no_start_4:nan, stop_no_start_5:nan, stop_no_start_6:nan, stop_no_start_7:nan,$
                     stop_no_start_8:nan, stop_no_start_9:nan, stop_no_start_10:nan,stop_no_start_11:nan,$
                     stop_no_start_12:nan,stop_no_start_13:nan,stop_no_start_14:nan,stop_no_start_15:nan,$
                     
                     start_0_1:nan, start_2_3:nan, start_4_5:nan, start_6_7:nan,$
                     start_8_9:nan, start_10:nan,  start_11:nan,$
                     start_12:nan,  start_13:nan,  start_14:nan,start_15:nan,$

                     stop_0:nan, stop_1:nan, stop_2:nan, stop_3:nan,$
                     stop_4:nan, stop_5:nan, stop_6:nan, stop_7:nan,$
                     stop_8:nan, stop_9:nan, stop_10:nan,stop_11:nan,$
                     stop_12:nan,stop_13:nan,stop_14:nan,stop_15:nan,$

                     emptyrate2:nan, $
                     
                     ihemi_checksum:nan,   ispoiler_checksum:nan, idef1_checksum:nan, $
                     idef2_checksum:nan,   ehemi_checksum:nan,  espoiler_checksum:nan, $
                     edef1_checksum:nan,   edef2_checksum:nan,  mlut_checksum:nan, $
                     mlimit_checksum:nan,  cmded_checksum:nan,  thist_chan_mask:nan, $
                     thist_stepmin:nan,    thist_stepmax:nan,   cal_disable:nan, $
                     read_nonVE:nan,       cal_clk_period:nan,  compress_tof:nan, $
                     cal_clk_pause:nan,    $
                     mram_write_addr_hi:nan, mram_write_addr_lo:nan, $
                     sweep_count:nan, $
                     pps_count:nan,        last_command:nan,    last_command_data:nan, $
                     sweep_utc_hi:nan, sweep_utc_lo:nan, $
                     cfd_setting_0:nan, cfd_setting_1:nan, cfd_setting_2:nan, cfd_setting_3:nan,$
                     cfd_setting_4:nan, cfd_setting_5:nan, cfd_setting_6:nan, cfd_setting_7:nan,$
                     cfd_setting_8:nan, cfd_setting_9:nan, cfd_setting_10:nan,cfd_setting_11:nan,$
                     cfd_setting_12:nan,cfd_setting_13:nan,cfd_setting_14:nan,cfd_setting_15:nan,$
                     cfd_setting_16:nan, cfd_setting_17:nan, cfd_setting_18:nan, cfd_setting_19:nan,$
                     cfd_setting_20:nan, cfd_setting_21:nan, cfd_setting_22:nan, cfd_setting_23:nan,$
                     cfd_setting_24:nan, cfd_setting_25:nan, cfd_setting_26:nan,$

                     easic_ch_0:nan, easic_ch_1:nan, easic_ch_2:nan, easic_ch_3:nan,$
                     easic_ch_4:nan, easic_ch_5:nan, easic_ch_6:nan, easic_ch_7:nan,$
                     easic_ch_8:nan, easic_ch_9:nan, easic_ch_10:nan,easic_ch_11:nan,$
                     easic_ch_12:nan,easic_ch_13:nan,easic_ch_14:nan,easic_ch_15:nan,$

                     ehemi_delta:nan,   ehemi_deadtime:nan,  $
                     easic_stim:nan,    iesa_tp_hv_step:nan, $
                     eidpu_fsm_err:nan, mram_fsm_err:nan,      tof_fsm_err:nan,   tlm_fsm_err:nan, $
                     hv_fsm_err:nan,    actuator_fsm_err:nan,  rates_fsm_err:nan, raw_fsm_err:nan, $
                     adc_fsm_err:nan,   cfd_fsm_err:nan,       ions_fsm_err:nan,  $
                     tof_mem_err:nan,   icounters_mem_err:nan, mlut_mem_err:nan, rates_mem_err:nan, $
                     raw_mem_err:nan,   mhist_mem_err:nan,     eesa_retrace_timeout:nan, $
                     tof_offset:nan,    iesa_test_val:nan,     eesa_test_val:nan,$

                     mram_write_addr:0.D, time:0.d};;!VALUES.D_NAN}
   
   
   self.dhkp_tags = tag_names(str_dhkp)
   self.dhkp_empty = ptr_new(str_dhkp)
   self.dhkp_last = ptr_new(str_dhkp)
   self.dhkp = dynamicarray(!null, name = 'Digital_Housekeeping')
   self.dhkp_tplot = 0
   
   RETURN, 1
   
END


PRO esc_gen_rawdat::Clear, tplot_names=tplot_names

   stop
   
   COMPILE_OPT IDL2
   dprint,'clear arrays: ',self.apid,self.name,dlevel=4
   self.nbytes=0
   self.npkts = 0
   self.lost_pkts = 0
   ptr_free,ptr_extract(self.data.array)
   self.data.array = !null
   ptr_free,  ptr_extract(*self.ccsds_last)
   *self.ccsds_last = !null
   if keyword_set(tplot_names) && keyword_set(self.tname) then store_data,self.tname+'*',/clear

END



PRO esc_gen_rawdat::Cleanup

   stop
   
   COMPILE_OPT IDL2
   ;; Call our superclass Cleanup method
   ptr_free,self.ccsds_last
   self->IDL_Object::Cleanup
END



FUNCTION esc_gen_rawdat::info,header=header
   ;; rs =string(format="(Z03,'x ',a-14, i8,i8 ,i12,i3,i3,i8,' ',a-14,a-36,' ',a-36, ' ',a-20,a)",self.apid,self.name,self.npkts,self.lost_pkts, $
   ;; self.nbytes,self.save_flag,self.rt_flag,self.data.size,self.data.typename,string(/print,self),self.routine,self.tname,self.save_tags)
   fmt ="(Z03,'x ',a-14, i8,i8 ,i12,i3,i3,i3,i8,' ',a-14,a-26,' ',a-20,'<',a,'>','     ',a)"
   hfmt="( a4,' ' ,a-14, a8,a8 ,a12,a3,a3,a3,a8,' ',a-14,a-26,' ',a-20,'<',a,'>','     ',a)"
   ;; if keyword_set(header) then rs=string(format=hfmt,'APID','Name','npkts','lost','nbytes','save','rtf','size','type','objname','routine','tname','tags')
   rs =string(format=fmt,self.apid,self.name,self.npkts,self.lost_pkts, $
              self.nbytes,self.save_flag,self.rt_flag,self.dlevel,self.data.size,self.data.typestring,typename(self),self.tname,self.ttags,self.routine)

   if keyword_set(header) then rs=string(format=hfmt, 'APID','Name','Npkts','lost','nbytes','sv','rt','dl','size','type','objname','tname','tags','routine')+string(13b)+string(10b)+rs

   return,rs
END


PRO esc_gen_rawdat::print,dlevel=dlevel,verbose=verbose,strng,header=header
   print,self.info(header=header)
END



PRO esc_gen_rawdat::handler, raw_pkt ;;, source_dict=source_dict

   ;; Common Block
   COMMON esc_raw_pkt, initialized, raw_data, source_dict
   
   ;; Print raw binary content
   IF debug(self.dlevel+3,msg='handler') THEN BEGIN
      hexprint,*raw_pkt.pdata
   ENDIF

   ;;####################################
   ;;### Append Data to Final Product ###
   ;;####################################

   ;; Electron Science Products
   IF source_dict.index EQ 0 THEN BEGIN
      GOTO, skip
      ;; Add new structure
      self.e_sci.append, *self.e_sci_last
      
      ;; Clear Structure
      *self.e_sci_last = *self.e_sci_empty

      ;; Create tplot structure
      IF self.e_sci_tplot EQ 0 THEN BEGIN
         store_data, 'esc_e_sci', data=self.e_sci, tagnames='*', verbose=0, /silent
         self.e_sci_tplot = 1
      ENDIF
      skip:
      
   ENDIF

   
   
   ;; Digital Housekeeping
   IF source_dict.index EQ 0 THEN BEGIN

      ;; Add new structure
      self.dhkp.append, *self.dhkp_last
      
      ;; Clear Structure
      *self.dhkp_last = *self.dhkp_empty

      ;; Create tplot structure
      IF self.dhkp_tplot EQ 0 THEN BEGIN
         store_data, 'esc_dhkp', data=self.dhkp, tagnames='*', verbose=0, /silent
         self.dhkp_tplot = 1
      ENDIF
      
   ENDIF


   
   ;; Analog Housekeeping
   IF (source_dict.index MOD 32) EQ 0 THEN BEGIN

      ;; Add Timestamp to Analog Housekeeping
      IF self.dhkp.array ne !null THEN BEGIN
         p1 = n_elements(self.dhkp.array)
         IF p1 GE 3 THEN BEGIN
            (*self.ahkp_last).time = self.dhkp.array[p1-2].time + $
                                     source_dict.index/512.*8.
         ENDIF
      ENDIF

      ;; Add new structure
      self.ahkp.append, *self.ahkp_last
      
      ;; Clear Structure
      *self.ahkp_last = *self.ahkp_empty

      ;; Create tplot structure
      IF self.ahkp_tplot EQ 0 THEN BEGIN
         store_data, 'esc_ahkp', data=self.ahkp, tagnames='*', verbose=0, /silent
         options,'esc_ahkp'+'*',/ynozero,ystyle=3
         self.ahkp_tplot = 1
      ENDIF

   ENDIF

   ;; Decommutate the RAW Packet
   IF NOT self.ignore_flag THEN strct = self.decom(raw_pkt, source_dict=source_dict)

   ;; Append Full EESA Message
   self.data.append,  strct
      
   ;; Create / Append tplot variable
   IF self.rt_flag && keyword_set(strct) THEN BEGIN
      IF ccsds.gap EQ 1 THEN strct = [fill_nan(strct[0]),strct]
      store_data, self.tname, data=strct, tagnames=self.ttags , append = 1, gap_tag='GAP'
      stop
   ENDIF

END



PRO esc_gen_rawdat::finish,ttags=ttags

   ;; Store Analog Housekeeping into tplot
   ;;store_data, 'esc_ahkp_', data=self.ahkp.array, tagnames='*', verbose=0;;, /append
   ;;store_data, 'esc_dhkp_', data=self.dhkp.array, tagnames='*', verbose=0, /append
   options,'esc_ahkp_'+'*',/ynozero,ystyle=3
   
END



PRO esc_gen_rawdat::GetProperty,data=data, array=array, npkts=npkts,lost_pkts=lost_pkts, $
                                apid=apid, name=name, typename=typename, $
                                nsamples=nsamples, nbytes=nbytes, strct=strct, ccsds_last=ccsds_last,$
                                tname=tname, dlevel=dlevel, ttags=ttags, last_data=last_data, $
                                window=window, cdf_pathname=cdf_pathname, ahkp=ahkp
   COMPILE_OPT IDL2
   IF (ARG_PRESENT(nbytes))    THEN nbytes = self.nbytes
   IF (ARG_PRESENT(name))      THEN name = self.name
   IF (ARG_PRESENT(tname))     THEN tname = self.tname
   IF (ARG_PRESENT(ttags))     THEN ttags = self.ttags
   IF (ARG_PRESENT(npkts))     THEN npkts = self.npkts
   IF (ARG_PRESENT(lost_pkts)) THEN lost_pkts = self.lost_pkts
   IF (ARG_PRESENT(data))      THEN data = self.data
   IF (arg_present(last_data)) THEN last_data = *(self.last_data_p)
   IF (arg_present(window))    THEN window = self.window_obj
   IF (ARG_PRESENT(array))     THEN array = self.data.array
   IF (ARG_PRESENT(typename))  THEN typename = typename(*self.data)
   IF (ARG_PRESENT(dlevel))    THEN dlevel = self.dlevel
   IF (arg_present(strct) )    THEN strct = self.struct()
   IF (ARG_PRESENT(ahkp))      THEN ahkp = self.ahkp

END



PRO esc_gen_rawdat__define

   void = {esc_gen_rawdat, $
           ;;inherits esc_gen_apdat,  $
           inherits generic_object, $ 
           sync: 0u, $
           name: '', $
           nbytes: 0UL, $
           npkts: 0UL,  $
           process_time: 0d, $
           lost_pkts: 0UL,  $
           drate: 0., $
           rt_flag: 0b, $
           save_flag: 0b, $
           sort_flag: 0b, $
           ignore_flag: 0b, $
           routine:  '', $
           tname: '', $
           ttags: '', $
           ;;ccsds_last:  ptr_new(), $
           last_raw_pkt: ptr_new(), $
           ;;last_data_p: ptr_new(), $
           last_raw_data_p: ptr_new(), $
           ;;ccsds_array: obj_new(), $
           raw_array: obj_new(), $
           data: obj_new(), $
           window_obj: obj_new(), $
           output_lun: 0, $

           ahkp:obj_new(), $
           dhkp:obj_new(), $
           e_sci:obj_new(),$

           ahkp_last:ptr_new(),$
           dhkp_last:ptr_new(),$
           e_sci_last:ptr_new(),$
           
           ahkp_poly:fltarr(32,6), $
           dhkp_poly:fltarr(32,6), $
           
           ahkp_tags:strarr(34),   $
           dhkp_tags:strarr(277),  $
           e_sci_tags:strarr(3),   $

           ahkp_empty:ptr_new(),   $
           dhkp_empty:ptr_new(),   $
           e_sci_empty:ptr_new(),  $

           ahkp_tplot:0,$
           dhkp_tplot:0,$
           e_sci_tplot:0,$
           
           dhkp_trans:intarr(231), $
           
           dhkp_ind:uintarr(229)  $
           
          }

END


