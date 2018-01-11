# denoising the volumes
if [ ! -f $PRD/connectivity/predwi_denoised.mif ]; then
  # denoising the combined-directions file is preferable to denoising \
  # predwi1 and 2 separately because of a higher no of volumes
  # see: https://github.com/MRtrix3/mrtrix3/issues/747
  echo "denoising dwi data"
  view_step=1
  dwidenoise $PRD/connectivity/predwi.mif \
             $PRD/connectivity/predwi_denoised.mif \
             -noise $PRD/connectivity/noise.mif -force -nthreads "$NB_THREADS"
  if [ ! -f $PRD/connectivity/noise_res.mif ]; then
    # calculate residuals noise
    mrcalc $PRD/connectivity/predwi.mif \
           $PRD/connectivity/predwi_denoised.mif \
           -subtract $PRD/connectivity/noise_res.mif -nthreads "$NB_THREADS"
  fi
fi
# check noise file: lack of anatomy is a marker of accuracy
if [ "$view_step" = 1 -a "$CHECK" = "yes" ] || [ "$CHECK" = "force" ] && [ -n "$DISPLAY" ]; then
  # noise.mif can also be used for SNR calculation
  echo "check noise/predwi_*_denoised.mif files"
  echo "lack of anatomy in noise_res is a marker of accuracy"
  view_step=0
  mrview $PRD/connectivity/predwi.mif \
         $PRD/connectivity/predwi_denoised.mif \
         $PRD/connectivity/noise.mif \
         $PRD/connectivity/noise_res.mif  
fi

