from  pylab import *
import matplotlib
import nibabel as nib
import os
from mpl_toolkits.mplot3d import Axes3D
#%matplotlib

""" check visually if tracts and cortical surface are in the same space. """

PRD = '/media/naze/backup_ext4/2017_Q4/100307'

################################################################
## plot in structural space LAS (voxel) : MRI, surface and tracks
################################################################

struct_fname = 'brain.nii.gz'

# transformation matrices from voxel to mm
img = nib.load(os.path.join(PRD,'connectivity',struct_fname))
trans_vox2mm = img.affine
M_vox2mm = trans_vox2mm[:3, :3]  # rotation and scaling
A_vox2mm = trans_vox2mm[:3, 3]   # translation

# transformation matrices from RAS to LAS (only to plot with the nii.gz)
brain = img.get_data()
M_RAS2LAS = [[-1,0,0],[0,1,0],[0,0,1]] 
A_RAS2LAS = [brain.shape[0], 0, 0]

figure()
# load and plot brain (structural space, LAS in voxel)
idx_vox = [128, 128, 128]
#idx_vox = [255-108, 127, 124]
if len(brain.shape)==4 :
  brain = brain[:,:,:,0]
ax1 = subplot(221)
ax1.imshow(brain[:, idx_vox[1], :].T, origin='lower')
ax2 = subplot(222)
ax2.imshow(brain[idx_vox[0], :, :].T, origin='lower')
ax3 = subplot(223)
ax3.imshow(brain[:, :, idx_vox[2]].T, origin='lower')

# load and plot cortical surface (structural space, RAS (mm) to LAS (voxel))
lh_vtx = np.loadtxt(os.path.join(PRD,'surface','lh_white_vertices_low.txt'))
rh_vtx = np.loadtxt(os.path.join(PRD,'surface','rh_white_vertices_low.txt'))
vtx = np.vstack([lh_vtx, rh_vtx])
randidx = randint(vtx.shape[0], size=(1,1000))
vtx_vox = np.dot(np.linalg.inv(M_vox2mm), (vtx - A_vox2mm).T).T
ax1.scatter(vtx_vox[randidx,0], vtx_vox[randidx,2], color='g', alpha=0.3)
ax2.scatter(vtx_vox[randidx,1], vtx_vox[randidx,2], color='g', alpha=0.3)
ax3.scatter(vtx_vox[randidx,0], vtx_vox[randidx,1], color='g', alpha=0.3)

# load and plot tracks (structural space, RAS, voxel to structural space, LAS, voxel)
tmp_ascii_files_path = os.path.join(PRD,'connectivity','tmp_ascii_tck')
tck_file_list = os.listdir(tmp_ascii_files_path)
for fname in tck_file_list[:500]:
    lines = np.loadtxt(os.path.join(tmp_ascii_files_path, fname))
    # lines = np.dot(M_RAS2LAS, lines.T).T + A_RAS2LAS
    ax1.plot(lines[:, 0], lines[:, 2], color='r', alpha=0.3)
    ax2.plot(lines[:, 1], lines[:, 2], color='r', alpha=0.3)
    ax3.plot(lines[:, 0], lines[:, 1], color='r', alpha=0.3)



############################################################
## plot in diffusion space, RAS (mm) only surface and tracks
############################################################

struct_fname = 'brain.nii.gz'

# transformation matrices from voxel to mm
img = nib.load(os.path.join(PRD,'connectivity',struct_fname))
trans_vox2mm = img.affine
M_vox2mm = trans_vox2mm[:3, :3]  # rotation and scaling
A_vox2mm = trans_vox2mm[:3, 3]   # translation

# transformation matrices from RAS to LAS (only to plot with the nii.gz)
brain = img.get_data()
M_RAS2LAS = [[-1,0,0],[0,1,0],[0,0,1]] 
A_RAS2LAS = [brain.shape[0], 0, 0]

# load and plot cortical surface (structural space, RAS (mm) to diffusion space, RAS (mm))
randidx = randint(vtx.shape[0], size=(1,4000))
figure()
ax1 = subplot(221)
ax1.scatter(vtx[randidx,0], vtx[randidx,2], color='g', alpha=0.3)
ax2 = subplot(222)
ax2.scatter(vtx[randidx,1], vtx[randidx,2], color='g', alpha=0.3)
ax3 = subplot(223)
ax3.scatter(vtx[randidx,0], vtx[randidx,1], color='g', alpha=0.3)
ax4 = subplot(224, projection='3d')
ax4.scatter(vtx[randidx,0], vtx[randidx,1], vtx[randidx,2], color='g', alpha=0.3)

# load and plot tracks (structural space, RAS (voxel) to structural space, RAS (mm))
for fname in tck_file_list[:2000]:
    lines = np.loadtxt(os.path.join(tmp_ascii_files_path,fname))
    lines = np.dot(lines, M_RAS2LAS) + A_RAS2LAS
    lines = np.dot(lines, M_vox2mm) + A_vox2mm
    ax1.plot(lines[:, 0], lines[:, 2], color='m', alpha=0.3)
    ax2.plot(lines[:, 1], lines[:, 2], color='m', alpha=0.3)
    ax3.plot(lines[:, 0], lines[:, 1], color='m', alpha=0.3)
    ax4.plot(lines[:, 0], lines[:, 1], lines[:, 2], color='m')
show()
