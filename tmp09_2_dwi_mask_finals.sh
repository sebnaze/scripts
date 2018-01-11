if [ ! -f $PRD/connectivity/dwi.mif ]; then
  echo "upsample dwi"
  mrresize $PRD/connectivity/predwi_denoised_preproc_bias.mif - -scale 2 -force | \
  mrconvert - -datatype float32 -stride -1,+2,+3,+4 $PRD/connectivity/dwi.mif -force 
fi

if [ ! -f $PRD/connectivity/mask.mif ]; then
  # for dwi2fod step, a permissive, dilated mask can be used to minimize
  # streamline premature termination, see BIDS protocol: 
  # https://github.com/BIDS-Apps/MRtrix3_connectome/blob/master/run.py
  echo "upsample mask"
  view_step=1
  mrresize $PRD/connectivity/mask_native.mif - -scale 2 -force | \
  mrconvert - $PRD/connectivity/mask.mif -datatype bit -stride -1,+2,+3 \
            -force -nthreads "$NB_THREADS"
  maskfilter $PRD/connectivity/mask.mif dilate \
             $PRD/connectivity/mask_dilated.mif -npass 2 -force \
             -nthreads "$NB_THREADS" 
fi
# check upsampled files
if [ "$view_step" = 1 -a "$CHECK" = "yes" ] || [ "$CHECK" = "force" ] && [ -n "$DISPLAY" ]; then
  echo "check upsampled mif files"
  view_step=0
  mrview $PRD/connectivity/dwi.mif \
         -overlay.load $PRD/connectivity/mask.mif \
         -overlay.load $PRD/connectivity/mask_dilated.mif \
         -overlay.opacity 0.5 -norealign 
fi

