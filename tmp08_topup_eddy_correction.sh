# topup/eddy correction
if [ ! -f $PRD/connectivity/predwi_denoised_preproc.mif ]; then
  view_step=1
  if [ "$TOPUP" = "eddy_correct" ]; then
    if ["$PE" = ""]
      # eddy maybe topup corrections depending of the encoding scheme
      echo "apply eddy and maybe topup if reverse phase-encoding scheme"
      dwipreproc $PRD/connectivity/predwi_denoised.mif \
               $PRD/connectivity/predwi_denoised_preproc.mif \
               -export_grad_mrtrix $PRD/connectivity/bvecs_bvals_final \
               -rpe_header -eddy_options ' --repol' -cuda -force \
               -nthreads "$NB_THREADS"    
    else
      echo "apply eddy and phase-encoding scheme set by user"
      dwipreproc $PRD/connectivity/predwi_denoised.mif \
               $PRD/connectivity/predwi_denoised_preproc.mif \
               -export_grad_mrtrix $PRD/connectivity/bvecs_bvals_final \
               -rpe_none -pe_dir $PE -eddy_options ' --repol' -force \
               -nthreads "$NB_THREADS" 
    fi
  else # no topup/eddy
    echo "no topup/eddy applied"
    mrconvert $PRD/connectivity/predwi_denoised.mif \
              $PRD/connectivity/predwi_denoised_preproc.mif \
	      -force -nthreads "$NB_THREADS"
              -export_grad_mrtrix $PRD/connectivity/bvecs_bvals_final \
              #-fslgrad $PRD/connectivity/bvecs $PRD/connectivity/bvals \
  fi
fi
# check preproc files
if [ "$view_step" = 1 -a "$CHECK" = "yes" ] || [ "$CHECK" = "force" ]  && [ -n "$DISPLAY" ]; then
  echo "check preprocessed mif file (no topup/no eddy)"
  view_step=0
  mrview $PRD/connectivity/predwi.mif \
         $PRD/connectivity/predwi_denoised.mif \
         $PRD/connectivity/predwi_denoised_preproc.mif 
fi
