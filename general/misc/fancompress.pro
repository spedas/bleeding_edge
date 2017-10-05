;+ 
;NAME:
;
;  fancompress
;
;PURPOSE:
;  Decimates polylines in an aesthetically pleasing fashion.
;
;CALLING SEQUENCE:
;  outidx = fancompress(inpts,err)
;
;INPUT:
;  inpts: N x 2 dimension array, where inpts[*,0] are the x components of the polyline and inpts[*,1] are the y components of the polyline
;  err: The amount of error allowed before including a point 
; 
;Keywords:
;  vector:  Will enable the vectorized fan compression algorithm.
;  step:  Controls the number of steps to perform per loop, during vectorized implementation. 
;         At the limit, where step = N, the vectorized version works like the iterative
;         version. 
;OUTPUT:
;  An array of indexes into inpts.  Indices will range from 0 to N-1.  First and Last points are always included.
;
;NOTES:
;  1. Based almost entirely on the paper: 
;  Fowell, Richard A. and McNeil, David D. , “Faster Plots by Fan Data-Compression,” 
;  IEEE Computer Graphics & Applications, Vol. 9, No. 2,Mar. 1989, pp. 58-66.
;  
;  2. One modification from published algorithm, handles NaNs by always including the point
;  before a group of NaNs, 1 NaN and the point after the NaNs.  This ensures that gaps will
;  be drawn accurately.
;  
;  3. Algorithm is fairly slow, because it requires 1 pass over all data points.
;  Optimizing this algorithm by divide and conquer, vectorization, or dlm may be
;  a worthwhile use of time in the future. 
;
;  4. Vectorized version is essentially a divide and conquer version of the Fowell & McNeil algorithm.  
;  The idea being to split the array into sub-problems that can be addressed in parallel using IDL vector-ops.
;  The fan-comparison operation at the core of the fan-compression algorithm takes 3-sequential points to work.
;  So if step = 1, the algorithm will split the input array of length N in floor(N/3) segments; Making an independent
;  decision on whether to keep the middle point of each segment, based upon the start and end points of each segment.
;  If a point is removed, the 5-element fan vector at the start point is updated, and this will be applied in the subsequent test. 
;
;  5. If step is higher an internal loop will perform the operation iteratively within-segments, but in parallel across segments.
;  For example, If step is 3, N will be split into floor(N/5) segments(5-point segments). Operating on points 1-2-3 of the segment
;  in the first iteration of the internal loop, points 1-3-4 or 2-3-4 on the second iteration and points 1-4-5,2-4-5,or 3-4-5 on the
;  third iteration. Which sequence ends up being operated on depends on whether the point was accepted or rejected in the previous iteration.
;
;  6. Vectorized(step=1) version generally achieves a speed up of 1000% at decrease in compression by ~10%.
;     For example, if the iterative version creates a 1 Mb of output in 1 sec, this will create
;     1.1 Mb of output in .1 sec.  Higher values of step, tend to decrease compression rates until step becomes large,
;     then compression approaches the iterative solution
;
;$LastChangedBy: pcruce $
;$LastChangedDate: 2009-07-27 17:44:33 -0700 (Mon, 27 Jul 2009) $
;$LastChangedRevision: 6496 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/fancompress.pro $
;-----------------------------------------------------------------------------------


pro fn_iter_save_pt,n_out,outpts,o,k,i,n_in

  compile_opt idl2,hidden

  if n_out eq 0 then begin
    outpts = i
  endif else begin
    outpts = [outpts,i]
  endelse 

  n_out++
  o = i
  k = n_in

end

function fn_iter_dot_p,u,v

  compile_opt idl2,hidden
  
  return,total(u*v)
  
end

function fn_iter_norm,v

  compile_opt idl2,hidden

  return,sqrt(fn_iter_dot_p(v,v))

end

function fancompress_iter,inpts,err

  compile_opt idl2,hidden
  
  n_in = (dimen(inpts))[0]
  n_out = 0
  keep = 1
  
  i = 1
  
  fn_iter_save_pt,n_out,outpts,o,k,i,n_in
  
  if n_in eq 1 then begin
    return,lindgen(n_in)
  endif
  
  error = max([0,err])

  while i lt n_in - 1 do begin
    i++
    ;properly mark NaNs in data, this addition is currently the only significant
    ;modification from the published algorithm
    if ~finite(inpts[i-1,0]) || ~finite(inpts[i-1,1]) then begin
      if keep eq 0 then begin
        outpts = [outpts,i-1]
        n_out++
      endif
      outpts = [outpts,i]
      n_out++
      for k = i,n_in-1 do begin
        if finite(inpts[k-1,0]) && finite(inpts[k-1,1]) then begin
          break
        endif
      endfor
      i = k
      if k eq n_in-1 then begin
        fn_iter_save_pt,n_out,outpts,o,k,i,n_in
        break
      endif else if k eq n_in then begin
        break
      endif
      fn_iter_save_pt,n_out,outpts,o,k,i,n_in
    endif
    
    if i lt k then begin
      distance = fn_iter_norm(inpts[i-1,*] - inpts[o-1,*])
      if distance gt error then begin
        k = i
        p_i_u = distance
        u_hat = (inpts[i-1,*] - inpts[o-1,*]) / p_i_u
        v_hat = [-u_hat[1],u_hat[0]]
        f = [p_i_u,error/p_i_u,-error/p_i_u]
      endif
    endif
    if i ge k then begin
      keep = 1
      p_i1_u = fn_iter_dot_p((inpts[(i-1)+1,*] - inpts[(o-1),*]),u_hat)
      p_i1_v = fn_iter_dot_p((inpts[(i-1)+1,*] - inpts[(o-1),*]),v_hat)
      if p_i1_u ge f[0] then begin
        m_i = p_i1_v/p_i1_u
        if m_i le f[1] && m_i ge f[2] then begin
          delta_m_i = error / p_i1_u
          keep = 0
          f[0] = p_i1_u
          f[1] = min([f[1],m_i+delta_m_i])
          f[2] = max([f[2],m_i-delta_m_i])
        endif
      endif
      if keep then begin
        fn_iter_save_pt,n_out,outpts,o,k,i,n_in
      endif
    endif
  endwhile
  
  outpts = [outpts,n_in]
  
  return,outpts-1

end

function fn_vector_dot_p,a,b

  compile_opt idl2,hidden
  
  if n_elements(a) gt 2 then begin
    return, total(a*b,2)
  endif else begin
    return, total(a*b)
  endelse

end

;inner code for vector fan compress
;fancompress_vector decides which points should be compared and
;removes elements from bookeeping structs.
;this code does the comparisons
pro do_vector_compress,pts,start_idx,mid_idx,fan,acc,err

  compile_opt idl2,hidden
  
  ;find and mark for removal any consecutive non-finite values.  If either element of point is non-finite, it is counted as non-finite
  idx = where((~finite(pts[start_idx,0]) or ~finite(pts[start_idx,1])) and (~finite(pts[mid_idx,0]) or ~finite(pts[mid_idx,1])),c)
  
  if c gt 0 then begin
    acc[mid_idx[idx]] = 1
  endif
  
  diff = pts[mid_idx,*]-pts[start_idx,*]
  dist = sqrt(fn_vector_dot_p(diff,diff))
  
  ;cases where no fan exists, and mid_pt is within err of start_pt
  idx = where(fan[start_idx,0] eq 0 and fan[start_idx,1] eq 0 and $
              dist le err,c,ncomplement=nc)

  ;mark for removal
  if c gt 0 then begin
    acc[mid_idx[idx]] = 1  
  endif
   
  if nc eq 0 then begin
    return
  endif
  
  ;cases where no fan exists and mid_pt is outside err of start_pt
  idx = where(fan[start_idx,0] eq 0 and fan[start_idx,1] eq 0 and $
              dist gt err,c)
             
  ;create fan
  if c gt 0 then begin
    fan[start_idx[idx],0] = diff[idx,0]/dist[idx]
    fan[start_idx[idx],1] = diff[idx,1]/dist[idx]
    fan[start_idx[idx],2] = dist[idx]
    fan[start_idx[idx],3] = err/dist[idx]
    fan[start_idx[idx],4] = -err/dist[idx]
  endif
  
  ;cases where fan exists
  idx = where(fan[start_idx,0] ne 0 or fan[start_idx,1] ne 0,c)
  
  if c eq 0 then begin
    return
  endif
  
  ;project end_pt into u,v coordinates
  p_u = fn_vector_dot_p(pts[mid_idx[idx]+1,*]-pts[start_idx[idx],*],fan[start_idx[idx],0:1])
  p_v = fn_vector_dot_p(pts[mid_idx[idx]+1,*]-pts[start_idx[idx],*],[[-fan[start_idx[idx],1]],[fan[start_idx[idx],0]]])

  ;find points within the fan
  fidx = where(p_u ge fan[start_idx[idx],2] and p_v/p_u le fan[start_idx[idx],3] and p_v/p_u ge fan[start_idx[idx],4],fc) 

  ;points inside the fan
  if fc gt 0 then begin
    ;mark for removal
    acc[mid_idx[idx[fidx]]] = 1
   
    ;special case for min/max function when only single dim passes test 
    if fc eq 1 then begin
      minmax_dim = 1
    endif else begin
      minmax_dim = 2
    endelse
    
    ;update fan
    fan[start_idx[idx[fidx]],2] = max([[fan[start_idx[idx[fidx]],2]],[p_u[fidx]]],minmax_dim,/nan)
    fan[start_idx[idx[fidx]],3] = min([[fan[start_idx[idx[fidx]],3]],[(p_v+err)/p_u[fidx]]],minmax_dim,/nan)
    fan[start_idx[idx[fidx]],4] = max([[fan[start_idx[idx[fidx]],4]],[(p_v-err)/p_u[fidx]]],minmax_dim,/nan)  
  endif

end

function fancompress_vector,inpts,err,step

  compile_opt idl2,hidden

  n_in = (dimen(inpts))[0]
  
  loop_num = 0
    
  outpts = lindgen(n_in)
  
  if n_in le 2 then begin
    return,outpts
  endif
   
  error = max([0,err])
  use_pts = inpts
  fan = dblarr(n_in,5) ; bookeeping for fan, [u_hat_1,u_hat_2,p_u,m+,m-]
  
  repeat begin
  
    n_pts = n_elements(outpts)
    acc=lonarr(n_pts)

    start_idx = lindgen(n_pts/(step+2)+1)*(step+2)
    mid_idx = start_idx+1

    for i = 0,step-1 do begin
  
      ;if there are some points dangling off the end, that will not be
      ;useful for transformation, remove their indices
      if mid_idx[n_elements(mid_idx)-1]+1 ge n_pts then begin
        if n_elements(mid_idx) eq 1 then begin
          continue
        endif else begin
          mid_idx = mid_idx[0:n_elements(mid_idx)-2]
          start_idx = start_idx[0:n_elements(start_idx)-2]
        endelse
      endif
  
      do_vector_compress,use_pts,start_idx,mid_idx,fan,acc,err
    
      ;advance start idx, in all places where removal failed
      idx = where(acc[mid_idx] eq 0,c)
      if c gt 0 then begin
        start_idx[idx] = mid_idx[idx]
      endif
      
      mid_idx++
    
    endfor   
   
    idx = where(acc eq 0,c)
    if c gt 0 then begin
      outpts = outpts[idx]
      use_pts = use_pts[idx,*]
      fan = fan[idx,*]
    endif
   
    loop_num++
   
  endrep until n_pts eq n_elements(outpts) || n_elements(outpts) lt 3

  return, outpts

end

function fancompress,inpts,err,vector=vector,step=step

  compile_opt idl2
  
  if ~keyword_set(step) then begin
    step = 1
  endif
  
  if ~keyword_set(vector) then begin
    return,fancompress_iter(inpts,err)
  endif else begin
    return,fancompress_vector(inpts,err,step)
  endelse

end