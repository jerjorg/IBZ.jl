module Plotting

ENV["MPLBACKEND"]="qt5agg"
include("Symmetry.jl")
include("Utilities.jl")
import .Symmetry: calc_bz, calc_ibz
import .Utilities: get_uniquefacets, sort_points_comparison
import QHull: Chull
import PyCall: PyObject, pyimport
import PyPlot: figaspect, figure, subplots

export plot_convexhulls

@doc """
    plot_2Dconvexhull(convexhull, ax, color)

Plot a 2D convex hull

# Arguments
- `convexhull::Chull{<:Real}`: a convex hull object.
- `ax::PyObject`: an axes object from matplotlib.
- `color::String`: the face color of the convex hull.

# Returns
- `ax::PyObject`: updated `ax` that includes a plot of the convex hull.

# Examples
```
using IBZ
real_latvecs = [1 0; 0 1]
convention = "ordinary"
bzformat = "convex hull"
bz = calc_bz(real_latvecs,convention,bzformat)

fig,ax=subplots(figsize=figaspect(1)*1.5)
ax = IBZ.Plotting.plot_2Dconvexhull(bz,ax,"deepskyblue");
color="deepskyblue"
IBZ.Plotting.plot_2Dconvexhull(bz,ax,color)
```
"""
function plot_2Dconvexhull(convexhull::Chull{<:Real}, ax::PyObject,
    color::String)::PyObject

    patch=pyimport("matplotlib.patches")
    collections=pyimport("matplotlib.collections")

    bzpts=Array(convexhull.points')
    middlept=[sum(bzpts[i,:])/size(bzpts,2) for i=1:2]
    bzpts=sortslices(bzpts, lt=(x,y)->sort_points_comparison(x,y,middlept),
            dims=2)

    (x,y)=[bzpts[i,:] for i=1:2]
    ax.fill(x,y, facecolor=color,edgecolor="black",linewidth=3)
    ax
end

@doc """
    plot_3Dconvexhull(convexhull, ax, color)

Plot a 3D convex hull

# Arguments
- `convexhull::Chull{<:Real}`: a convex hull object.
- `ax::PyObject`: an axes object from matplotlib.
- `color::String`: the face color of the convex hull.
- `plotrange=false`: the range over which to plot the convex hull.

# Returns
- `ax::PyObject`: updated `ax` that includes a plot of the convex hull.

# Examples
```
using IBZ
real_latvecs = [1 0 0; 0 1 0; 0 0 1]
convention = "ordinary"
bzformat = "convex hull"
bz = calc_bz(real_latvecs,convention,bzformat)
fig = figure(figsize=figaspect(1)*1.5)
ax = fig.add_subplot(111, projection="3d")
ax = IBZ.Plotting.plot_3Dconvexhull(bz,ax,"deepskyblue")
```
"""
function plot_3Dconvexhull(convexhull::Chull{<:Real}, ax::PyObject,
    color::String, plotrange=false)

    art3d=pyimport("mpl_toolkits.mplot3d.art3d")

    if plotrange ==false
        ϵ=0.1*convexhull.volume
        plotrange=[[minimum(convexhull.points[:,i])-ϵ,
                maximum(convexhull.points[:,i])+ϵ] for i=1:3]
    end

    facesᵢ=get_uniquefacets(convexhull)
    edgesᵢ=deepcopy(facesᵢ)
    for i=1:length(edgesᵢ)
        append!(edgesᵢ[i],edgesᵢ[i][1])
    end

    faces=[convexhull.points[i,:] for i in facesᵢ]
    edges=[convexhull.points[i,:] for i in edgesᵢ]

    # Reshape faces and edges
    faces=[[faces[j][i,:] for i=1:size(faces[j],1)] for j=1:length(faces)]
    edges=[[edges[j][i,:] for i=1:size(edges[j],1)] for j=1:length(edges)]

    p=art3d.Poly3DCollection(faces, alpha=0.2, facecolors=color)
    l=art3d.Line3DCollection(edges, colors="black", linewidths=1)

    ax.add_collection3d(p)
    ax.add_collection3d(l)

    #ax.view_init(-45,-45)
    ax.set_xlim3d(plotrange[1]...)
    ax.set_ylim3d(plotrange[2]...)
    ax.set_zlim3d(plotrange[3]...)
    return ax
end

@doc """
    plot_convexhulls(real_latvecs,atom_types,atom_pos,coords,convention,rtol,
      atol)

Plot the Brillouin and Irreducible Brillouin zone in 2D or 3D.

# Arguments
- `real_latvecs::AbstractArray{<:Real,2}`: the basis of a real-space lattice as
    columns of an array.
- `atom_types:AbstractArray{<:Int,1}`: a list of atom types as integers.
- `atom_pos::AbstractArray{<:Real,2}`: the positions of atoms in the crystal
    structure as columns of an array.
- `coords::String`: indicates the positions of the atoms are in \"lattice\" or
    \"Cartesian\" coordinates.
- `convention::String="ordinary"`: the convention used to go between real and
    reciprocal space. The two conventions are ordinary (temporal) frequency and
    angular frequency. The transformation from real to reciprocal space is
    unitary if the convention is ordinary.
- `rtol::Real=sqrt(eps(float(maximum(real_latvecs))))` a relative tolerance for
    floating point comparisons.
- `atol::Real=0.0`: an absolute tolerance for floating point comparisons.

# Returns
- `(fig,ax)`: the figure and axes Python objects.

# Examples
```
using IBZ
real_latvecs = [1 0; .5 1]
atom_types=[0]
coords = "Cartesian"
atom_pos = Array([0 0]')
convention = "ordinary"
(fig,ax)=plot_convexhulls(real_latvecs,atom_types,atom_pos,coords,convention)
```
"""
function plot_convexhulls(real_latvecs,atom_types,atom_pos,coords,convention,
        rtol::Real=sqrt(eps(float(maximum(real_latvecs)))),atol::Real=0.0)
    art3d=pyimport("mpl_toolkits.mplot3d.art3d")
    bzformat = "convex hull"
    bz = calc_bz(real_latvecs,convention,bzformat)
    ibzformat = "convex hull"
    ibz = calc_ibz(real_latvecs,atom_types,atom_pos,coords,ibzformat,convention,
        rtol,atol)

    dim = size(real_latvecs,1)
    if dim == 2
        fig,ax=subplots(figsize=figaspect(1)*1.5)
        ax = plot_2Dconvexhull(bz,ax,"deepskyblue")
        ax = plot_2Dconvexhull(ibz,ax,"coral")
    elseif dim == 3
        fig = figure(figsize=figaspect(1)*1.5)
        ax = fig.add_subplot(111, projection="3d")
        ϵ=0.1*bz.volume
        plotrange=[[minimum(bz.points[:,i])-ϵ,
                maximum(bz.points[:,i])+ϵ] for i=1:3]
        ax = plot_3Dconvexhull(bz,ax,"blue",plotrange)
        ax = plot_3Dconvexhull(ibz,ax,"red",plotrange)
    else
        throw(ArgumentError("The lattice vectors must be in a 2x2 or 3x3
            array."))
    end
    ax.set_axis_off()
    #ax.tick_params(axis="both", which="major", labelsize=18)
    (fig,ax)
end

end #module
