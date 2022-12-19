from matplotlib import pyplot as plt
import numpy as np

f = open("data/input.txt", "r")
data = []
for line in f.readlines():
    data.append([x for x in line.split(",")])

data = np.array(data, dtype="int32")
# data = np.array([
#     [2,2,2],
#     [1,2,2],
#     [3,2,2],
#     [2,1,2],
#     [2,3,2],
#     [2,2,1],
#     [2,2,3],
#     [2,2,4],
#     [2,2,6],
#     [1,2,5],
#     [3,2,5],
#     [2,1,5],
#     [2,3,5]])

xmin = np.min(data)
xmax = np.max(data)

dx = np.max(data) + 2
u, v, w = np.indices([dx, dx, dx])

dims = u.shape

cubes = np.full((dims[0]-1,dims[1]-1,dims[2]-1), False, dtype=bool)
for row in data:
    i, j, k = row[0:3]
    cubes[i,j,k] = True

fig = plt.figure()
ax = fig.add_subplot(projection='3d')

ax.voxels(u,v,w,cubes, edgecolors='k')

plt.show()

# ax.scatter(x,y,z, marker='s')

# def midpoints(x):
#     sl = ()
#     for i in range(x.ndim):
#         x = (x[sl + np.index_exp[:-1]] + x[sl + np.index_exp[1:]]) / 2.0
#         sl += np.index_exp[:]
#     return x
# 
# # prepare some coordinates, and attach rgb values to each
# r, g, b = np.indices((17, 17, 17)) / 16.0
# rc = midpoints(r)
# gc = midpoints(g)
# bc = midpoints(b)
# 
# # define a sphere about [0.5, 0.5, 0.5]
# sphere = (rc - 0.5)**2 + (gc - 0.5)**2 + (bc - 0.5)**2 < 0.5**2
# print(sphere)
# 
# # combine the color components
# colors = np.zeros(sphere.shape + (3,))
# colors[..., 0] = rc
# colors[..., 1] = gc
# colors[..., 2] = bc
# 
# # and plot everything
# ax = plt.figure().add_subplot(projection='3d')
# ax.voxels(r, g, b, sphere,
#           facecolors=colors,
#           edgecolors=np.clip(2*colors - 0.5, 0, 1),  # brighter
#           linewidth=0.5)
# ax.set(xlabel='r', ylabel='g', zlabel='b')
# ax.set_aspect('equal')
# 
# plt.show()
