

# postprocessing
if [ ! -f $PRD/connectivity/whole_brain_post.tck ]; then
  if [ "$SIFT" = "sift" ]; then
    echo "using sift"
    number_tracks=$(($NUMBER_TRACKS/$SIFT_MULTIPLIER))
    if [ "$ACT" != "none" ]; then
        echo "trimming tracks using sift/act" 
        tcksift $PRD/connectivity/whole_brain.tck \
                $PRD/connectivity/wm_CSD"$lmax".mif \
                $PRD/connectivity/whole_brain_post.tck \
                -act $PRD/connectivity/act.mif \
                -out_mu $PRD/connectivity/mu.txt \
                -term_number $NUMBER_TRACKS -fd_scale_gm -force \
                -nthreads "$NB_THREADS"
    else
        echo "trimming tracks using sift/without act" 
        tcksift $PRD/connectivity/whole_brain.tck \
                $PRD/connectivity/wm_CSD"$lmax".mif \
                $PRD/connectivity/whole_brain_post.tck \
                -out_mu $PRD/connectivity/mu.txt \
                -term_number $NUMBER_TRACKS -force \
                -nthreads "$NB_THREADS"
    fi
  elif [ "$SIFT" = "sift2" ]; then 
    echo "running sift2"
    ln -s $PRD/connectivity/whole_brain.tck $PRD/connectivity/whole_brain_post.tck
    if [ "$ACT" != "none" ]; then
      echo "using act" 
      tcksift2 $PRD/connectivity/whole_brain.tck \
               $PRD/connectivity/wm_CSD"$lmax".mif \
               $PRD/connectivity/streamline_weights.csv\
               -act $PRD/connectivity/act.mif \
               -out_mu $PRD/connectivity/mu.txt \
               -out_coeffs $PRD/connectivity/streamline_coeffs.csv \
               -fd_scale_gm -force -nthreads "$NB_THREADS"
    else
      tcksift2 $PRD/connectivity/whole_brain.tck \
               $PRD/connectivity/wm_CSD"$lmax".mif \
               $PRD/connectivity/streamline_weights.csv \
               -out_mu $PRD/connectivity/mu.txt \
               -out_coeffs $PRD/connectivity/streamline_coeffs.csv \
               -force -nthreads "$NB_THREADS"
    fi
  else 
    echo "not using sift2"
    ln -s $PRD/connectivity/whole_brain.tck \
          $PRD/connectivity/whole_brain_post.tck
  fi
fi

