# -*- coding: utf-8 -*-
"""
Created on Thu Oct 12 20:27:41 2017

@author: naze
"""

import sys
import os
import nibabel as nib
import numpy as np
from scipy.spatial.distance import cdist
import matplotlib.pylab as plt
from scipy.sparse import csr_matrix, lil_matrix
from scipy.io import mmwrite

PRD = os.environ['PRD']
SUBJ_ID = os.environ['SUBJ_ID']
ALGO_TRACTO = 'TensorDet'
#PRD = '/usr/local/freesurfer/subjects/R008572786'
#PRD = '/media/naze/backup_ext4/2017_Q4/100307'
tmp_ascii_files_path = os.path.join(PRD, 'connectivity', 'tmp_ascii_tck_TensorDet_angle30_cutoff02')
tck_file_list = os.listdir(tmp_ascii_files_path)
tck_file_list = np.asarray(sorted(tck_file_list, key=str.lower))
print('extracting beginning and end coordinates of '+repr(len(tck_file_list))+' streamlines... and generate custom size connectivity matrix')

# get transforms to from diffusion to structural reference spaces
img = nib.load(os.path.join(PRD,'connectivity','brain.nii.gz'))
trans_vox2mm = img.affine
M_vox2mm = trans_vox2mm[:3, :3]
A_vox2mm = trans_vox2mm[:3,3]

brain = img.get_data()
M_RAS2LAS = [[-1,0,0],[0,1,0],[0,0,1]]
A_RAS2LAS = [brain.shape[0], 0, 0]

# get decimated cortical surface (structural space, RAS, mm)
lh_vtx = np.loadtxt(os.path.join(PRD,'surface','lh_white_vertices_low.txt'))
rh_vtx = np.loadtxt(os.path.join(PRD,'surface','rh_white_vertices_low.txt'))
vtx = np.vstack([lh_vtx, rh_vtx])

#custom_connectivity = csr_matrix((2*mesh_size, 2*mesh_size), dtype=np.int32)  # creates sparse matrix, mesh_size is for one hemisphere, whole brain connectome uses both hemispheres
#tract_lengths = lil_matrix((2*mesh_size, 2*mesh_size))
custom_connectivity = np.zeros((vtx.shape[0], vtx.shape[0]))  # creates sparse matrix, mesh_size is for one hemisphere, whole brain connectome uses both hemispheres

max_dist = 1.5 # max distance (in mm) from the fiber tract to the cortical surface to be considered
strmaxdist = str(int(max_dist*1000))
nsamples=int(os.environ['NUMBER_TRACKS'])

with open(os.path.join(PRD,'connectivity','harmonics_log.txt'), 'a+') as logfile: # a+ : append if exists, create otherwise
  logfile.write("Maximum distance between tracts bounds and cortical surface mesh : " + strmaxdist + "um\n")
  logfile.write("Number of tracts sampled for constructing the custom connectivity : " + str(nsamples) + "\n")
  

tract_lengths = []  #lil_matrix((2*mesh_size, 2*mesh_size))
dists = np.zeros((2,nsamples)) # first, last

randidx = np.random.randint(len(tck_file_list), size=(1,nsamples))
randidx = np.sort(randidx).flatten()
for i in np.arange(0,nsamples):
    fname = tck_file_list[randidx[i]]
    '''
    first = f.readline().rstrip()       # Read the first line.
    f.seek(-2, os.SEEK_END)             # Jump to the second last byte.
    while f.read(1) != b"\n":           # Until EOL is found...
        f.seek(-2, os.SEEK_CUR)         # ...jump back the read byte plus one more.
    last = f.readline().rstrip()        # Read last line.
    '''
    # get tracts (structural space, RAS, voxel) and trasnform to mm
    #lines = f.readlines()
    lines = np.loadtxt(os.path.join(tmp_ascii_files_path, fname))
    lines = np.dot(lines, M_RAS2LAS) + A_RAS2LAS
    lines = np.dot(lines, M_vox2mm) + A_vox2mm
    # transform into numpy arrays
    #first = np.fromstring(lines[0], dtype=np.float, sep=' ' )    
    #last = np.fromstring(lines[-1], dtype=np.float, sep=' ' )    
    #first = np.dot(M,lines[0].T)+A
    #last = np.dot(M,lines[-1].T)+A
    first = lines[0]
    last = lines[-1]
    
    # go from dti to mri space
    #first = nib.affines.apply_affine(dti_vox2mri_vox, first)
    #last = nib.affines.apply_affine(dti_vox2mri_vox, last)

    # find nearest neigbour vertices on cortical mesh
    first_dist = cdist(vtx, np.array([first]), 'euclidean')
    first_min_idx = np.argmin(first_dist)
    
    last_dist = cdist(vtx, np.array([last]), 'euclidean')
    last_min_idx = np.argmin(last_dist)

    # update connectivity matrix
    #if (first_min_idx != last_min_idx):
    dists[:,i] = [np.min(first_dist), np.min(last_dist)]
    if np.max(dists[:,i]) < max_dist :
        custom_connectivity[last_min_idx, first_min_idx] += 1
        tract_lengths.append(len(lines))
    
    sys.stdout.write('\r')        
    sys.stdout.write(fname+' done')
    #print [np.min(first_dist), np.min(last_dist)]
    sys.stdout.flush()

# post-processing connectivity tract lengths to get average tract length between 2 nodes
#tract_lengths /= custom_connectivity
#custom_connectivity += custom_connectivity.T 
#custom_connectivity *= np.eye(mesh_size)/2

#np.savetxt('custom_connectivity.txt', custom_connectivity)
mmwrite(os.path.join(PRD,'connectivity','sparse_custom_connectivity_'+ALGO_TRACTO+'_'+strmaxdist+'um'), csr_matrix(custom_connectivity + custom_connectivity.T))  # saves as text file
#mmwrite('sparse_tract_lengths', csr_matrix(tract_lengths))  # saves as text file
#np.save('distances_between dti_and_mri_vertices', dists)  # saves as text file

c_fig = plt.figure(figsize=(10,10)) # size in inches
plt.spy(csr_matrix(custom_connectivity+custom_connectivity.T), marker='.', markersize=0.5)
plt.xlabel('vertices')
plt.ylabel('vertices')
plt.title('Connectivity matrix')
#plt.show()
plt.savefig(os.path.join(PRD,'connectivity','img_'+SUBJ_ID, 'custom_connectivity_matrix_'+ALGO_TRACTO+'_'+strmaxdist+'um.svg'))
plt.savefig(os.path.join(PRD,'connectivity','img_'+SUBJ_ID, 'custom_connectivity_matrix_'+ALGO_TRACTO+'_'+strmaxdist+'um.png'))
plt.close(c_fig)

d_fig = plt.figure(figsize=(20,4))
d_fig.add_subplot(1,2,1)
plt.hist(dists.flatten(), bins=np.arange(0,50,0.25))
plt.xlabel('tck beg/end distance from nearest ctx mesh vrtex')
plt.ylabel('counts')

d_fig.add_subplot(1,3,2)
values, base = np.histogram(dists.flatten(), bins=np.arange(0,10,0.1))
cumulative = np.cumsum(values)
plt.plot(base[:-1], cumulative)
plt.xlabel('cumulative distribution of distances')
plt.ylabel('counts')

d_fig.add_subplot(1,3,3)
plt.hist(tract_lengths, bins=np.arange(0,250,5))
plt.xlabel('tracts lengths')
plt.ylabel('counts')
#plt.show()
plt.savefig(os.path.join(PRD,'connectivity','img_'+SUBJ_ID, 'distsFromVertexMesh_tractsLength_'+ALGO_TRACTO+'_'+strmaxdist+'um.svg')) 
plt.savefig(os.path.join(PRD,'connectivity','img_'+SUBJ_ID, 'distsFromVertexMesh_tractsLength_'+ALGO_TRACTO+'_'+strmaxdist+'um.png'))
plt.close(d_fig)
