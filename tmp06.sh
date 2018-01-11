if [ ! -f $PRD/connectivity/predwi.mif ]; then 
  view_step=1
  select_images="n"
  i_im=1
  echo "generate dwi mif file"
  echo "if asked, please select a series of images by typing a number"
  mrconvert $PRD/data/DWI/data.nii.gz $PRD/connectivity/predwi_"$i_im".mif \
            -fslgrad $PRD/connectivity/bvecs $PRD/connectivity/bvals \
	    -export_grad_mrtrix $PRD/connectivity/bvecs_bvals_init \
            -datatype float32 -stride 0,0,0,1 -force -nthreads "$NB_THREADS"  
            #-export_pe_table $PRD/connectivity/pe_table \
  echo "Do you want to add another image serie (different phase encoding)? [y, n]"
  echo "You have 1 minute to answer, otherwise default is NO"
  read -t 60 select_images
  while [ "$select_images" != "y" ] && [ "$select_images" != "n" ]; do
    echo " please answer y or n"
    read -t 60 select_images
  done
  cp $PRD/connectivity/predwi_1.mif $PRD/connectivity/predwi.mif
  while [ "$select_images" == "y" ]; do
    i_im=$(($i_im + 1))
    mrconvert $PRD/data/DWI/data.nii.gz $PRD/connectivity/predwi_"$i_im".mif \
              -fslgrad $PRD/connectivity/bvecs $PRD/connectivity/bvals \
              -export_grad_mrtrix $PRD/connectivity/bvecs_bvals_init \
              -datatype float32 -stride 0,0,0,1 -force -nthreads "$NB_THREADS"
              #-export_pe_table $PRD/connectivity/pe_table \
    mrcat $PRD/connectivity/predwi.mif $PRD/connectivity/predwi_"$i_im".mif \
          $PRD/connectivity/predwi.mif -axis 3 -nthreads "$NB_THREADS" -force
    echo "Do you want to add another image serie (different phase encoding)? [y, n]"
    read select_images
    while [ "$select_images" != "y" ] && [ "$select_images" != "n" ]; do
      echo " please answer y or n"
      read select_images
    done
  done
  mrinfo $PRD/connectivity/predwi.mif \
        #-export_grad_mrtrix $PRD/connectivity/bvecs_bvals_init \
        #-export_pe_table $PRD/connectivity/pe_table -force 
fi
if [ "$view_step" = 1 -a "$CHECK" = "yes" ] || [ "$CHECK" = "force" ] && [ -n "$DISPLAY" ]; then
  view_step=0
  echo "check predwi_*.mif files"
  mrview $PRD/connectivity/predwi_*.mif
fi


