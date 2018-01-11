
######################## compute MEG and EEG forward projection matrices
# make BEM surfaces
if [ ! -h ${FS}/${SUBJ_ID}/bem/inner_skull.surf ]; then
  echo "generating bem surfaces"
  mne_watershed_bem --subject ${SUBJ_ID} --overwrite
  ln -s ${FS}/${SUBJ_ID}/bem/watershed/${SUBJ_ID}_inner_skull_surface \
        ${FS}/${SUBJ_ID}/bem/inner_skull.surf
  ln -s ${FS}/${SUBJ_ID}/bem/watershed/${SUBJ_ID}_outer_skin_surface  \
        ${FS}/${SUBJ_ID}/bem/outer_skin.surf
  ln -s ${FS}/${SUBJ_ID}/bem/watershed/${SUBJ_ID}_outer_skull_surface \
        ${FS}/${SUBJ_ID}/bem/outer_skull.surf
fi

# export to ascii
if [ ! -f ${FS}/${SUBJ_ID}/bem/inner_skull.asc ]; then
  echo "importing bem surface from freesurfer"
  mris_convert $FS/$SUBJ_ID/bem/inner_skull.surf $FS/$SUBJ_ID/bem/inner_skull.asc
  mris_convert $FS/$SUBJ_ID/bem/outer_skull.surf $FS/$SUBJ_ID/bem/outer_skull.asc
  mris_convert $FS/$SUBJ_ID/bem/outer_skin.surf $FS/$SUBJ_ID/bem/outer_skin.asc
fi

# triangles and vertices bem
if [ ! -f $PRD/$SUBJ_ID/surface/inner_skull_vertices.txt ]; then
  echo "extracting bem vertices and triangles"
  python2.7 extract_bem.py inner_skull 
  python2.7 extract_bem.py outer_skull 
  python2.7 extract_bem.py outer_skin 
fi

if [ ! -f ${FS}/${SUBJ_ID}/bem/${SUBJ_ID}-head.fif ]; then
  echo "generating head bem"
  view_step=1
  mkheadsurf -s $SUBJ_ID
  mne_surf2bem --surf ${FS}/${SUBJ_ID}/surf/lh.seghead --id 4 --check \
               --fif ${FS}/${SUBJ_ID}/bem/${SUBJ_ID}-head.fif --overwrite
fi

if [ "$view_step" = 1 -a "$CHECK" = "yes" ] || [ "$CHECK" = "force" ] && [ -n "$DISPLAY" ]; then
  echo "check bem surfaces"
  view_step=0
  # TODO: use mrview instead
  freeview -v ${FS}/${SUBJ_ID}/mri/T1.mgz \
           -f ${FS}/${SUBJ_ID}/bem/inner_skull.surf:color=yellow:edgecolor=yellow \
           ${FS}/${SUBJ_ID}/bem/outer_skull.surf:color=blue:edgecolor=blue \
           ${FS}/${SUBJ_ID}/bem/outer_skin.surf:color=red:edgecolor=red
fi

# Setup BEM
if [ ! -f ${FS}/${SUBJ_ID}/bem/*-bem.fif ]; then
  worked=0
  outershift=0
  while [ "$worked" == 0 ]; do
    echo "try generate forward model with 0 shift"
    worked=1
    mne_setup_forward_model --subject ${SUBJ_ID} --surf --ico 4 \
                            --outershift $outershift || worked=0 
    if [ "$worked" == 0 ]; then
      echo "try generate foward model with 1 shift"
      worked=1
      mne_setup_forward_model --subject ${SUBJ_ID} --surf --ico 4 --outershift 1 \
      || worked=0 
    fi
    if [ "$worked" == 0 ] && [ "$CHECK" = "yes" ]; then
      echo 'you can try using a different shifting value for outer skull, 
           please enter a value in mm'
      read outershift;
      echo $outershift
    elif [ "$worked" == 0 ]; then
      echo "bem did not worked"
      worked=1
    elif [ "$worked" == 1 ]; then
      echo "success!"
    fi
  done
fi

