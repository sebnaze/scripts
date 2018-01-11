
# Response function estimation
# Check if multi or single shell
shells=$(mrinfo -shells $PRD/connectivity/dwi.mif)
echo "shell b values are $shells"
nshells=($shells)
no_shells=${#nshells[@]}
echo "no of shells are $no_shells"

if [ "$no_shells" -gt 2 ]; then
# Multishell
  if [ ! -f $PRD/connectivity/response_wm.txt ]; then
    view_step=1
    if [ "$ACT" != "none" ]; then 
      echo "estimating response using msmt algorithm"
      dwi2response msmt_5tt $PRD/connectivity/dwi.mif \
                   $PRD/connectivity/act.mif \
                   $PRD/connectivity/response_wm.txt \
                   $PRD/connectivity/response_gm.txt \
                   $PRD/connectivity/response_csf.txt \
                   -voxels $PRD/connectivity/RF_voxels.mif \
                   -mask $PRD/connectivity/mask.mif -force \
                   -nthreads "$NB_THREADS"
    else
      echo "estimating response using dhollander algorithm"
      dwi2response dhollander $PRD/connectivity/dwi.mif \
                   $PRD/connectivity/response_wm.txt \
                   $PRD/connectivity/response_gm.txt \
                   $PRD/connectivity/response_csf.txt \
                   -voxels $PRD/connectivity/RF_voxels.mif \
                   -mask $PRD/connectivity/mask.mif -force \
                   -nthreads "$NB_THREADS"
    fi
  fi
else
# Single shell only
  if [ ! -f $PRD/connectivity/response_wm.txt ]; then
    echo "estimating response using dhollander algorithm"
    view_step=1
    # dwi2response tournier $PRD/connectivity/dwi.mif $PRD/connectivity/response.txt -force -voxels $PRD/connectivity/RF_voxels.mif -mask $PRD/connectivity/mask.mif
    dwi2response dhollander $PRD/connectivity/dwi.mif \
                 $PRD/connectivity/response_wm.txt \
                 $PRD/connectivity/response_gm.txt \
                 $PRD/connectivity/response_csf.txt \
                 -voxels $PRD/connectivity/RF_voxels.mif \
                 -mask $PRD/connectivity/mask.mif -force \
                 -nthreads "$NB_THREADS"
  fi
fi
if [ "$view_step" = 1 -a "$CHECK" = "yes" ] || [ "$CHECK" = "force" ] && [ -n "$DISPLAY" ]; then
  echo "check ODF image"
  view_step=0
  mrview $PRD/connectivity/meanlowb.mif \
         -overlay.load $PRD/connectivity/RF_voxels.mif \
         -overlay.opacity 0.5
fi


