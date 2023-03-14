import numpy as np
from scipy.spatial import distance_matrix
from scipy.spatial.transform import Rotation
from scipy.spatial.distance import cdist
from scipy.linalg import orthogonal_procrustes

threshold = 0.1

# Load the two SDFs from numpy files
sdf1 = np.load('./data/result_1_512_sdf.npy')
sdf2 = np.load('./data/result_2_512_sdf.npy')

# Sample points from both SDFs and extract the surface points
points1 = np.array(np.where(np.abs(sdf1) < threshold)).T
points2 = np.array(np.where(np.abs(sdf2) < threshold)).T

# Initialize the transformation parameters
T = np.eye(4)

# Define the maximum number of iterations and the convergence threshold
max_iterations = 100
convergence_threshold = 1e-6

# Define the initial residual and the iteration counter
residual = np.inf
iteration = 0

# Repeat until convergence
while residual > convergence_threshold and iteration < max_iterations:
    # Transform the points from SDF1 using the current transformation parameters
    transformed_points1 = points1 @ T[:3, :3].T + T[:3, 3]

    # Downsample the points by a factor of 10000
    points1_downsampled = transformed_points1[::10000]
    points2_downsampled = points2[::10000]

    # Find the closest corresponding points in SDF2
    distances = cdist(points1_downsampled, points2_downsampled)
    closest_points = points2_downsampled[np.argmin(distances, axis=1)]

    # Estimate the optimal rigid transformation that aligns the two sets of corresponding points
    R, scale = orthogonal_procrustes(points1_downsampled, closest_points)
    translation = closest_points.mean(axis=0) - transformed_points1.mean(axis=0)
    T_new = np.eye(4)
    T_new[:3, :3] = R
    T_new[:3, 3] = translation
    T_new[:3, :3] *= scale

    # Update the transformation parameters
    residual = np.sum(np.abs(T_new - T))
    T = T_new
    iteration += 1

print('done on' + iteration + 'iteration')
# Apply the final transformation to SDF1 to align it with SDF2
aligned_sdf1 = np.zeros_like(sdf2)
np.save("algined_sdf_1", aligned_sdf1)
