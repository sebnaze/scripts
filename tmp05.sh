# extract subcortical surfaces 
if [ ! -f $PRD/surface/subcortical/aseg_058_vert.txt ]; then
  echo "generating subcortical surfaces"
  ./aseg2srf -s $SUBJ_ID
  mkdir -p $PRD/surface/subcortical
  cp $FS/$SUBJ_ID/ascii/* $PRD/surface/subcortical
  python list_subcortical.py
fi

########################## build connectivity using mrtrix 3
mkdir -p $PRD/connectivity
mkdir -p $PRD/$SUBJ_ID/connectivity



