function img = feReplaceImageValues(img,vals,coords,indexes)
% Takes a 3/4D image (img, like a dwi data file) and 
% replaces the values of the image at the coordinates (coords)
% with the values in vals.
% 
%   img  = feReplaceImageValues(img,vals,coords,indexes) 
%
% img:     img volume.
% vals:    A list of N values that will be placed into the img volume
% coords:  Nx3 matrix of coordinates in the volume.
%
% TODO - let's discuss whether this should only work for a 3D planning that
% we are using for ROIs and overlays, or we want really to do this special
% treatment of the 4th dimension.
%
% indexes is a subset of the 4th dimension of img if img is a 4D file. For
% example it helsp addressing the diffusion directions and not the b0
% images in the data set. Default is 1:size(img,4).
%
% Franco (C) 2012 Stanford VISTA team.

% If index is not passed, then copy the data into all of the slots in the
% 4th dimension
if notDefined('indexes'),   indexes = 1:size(img,4); end
if ~( length(indexes) <= size(img,4) )
  error('Image and vals do not have the same size.')
end

if ~( size(vals,2) == size(coords,1) )
  error('Vals and coords do not have the same size.')
end

if ~( length(indexes) == size(vals,1) )
  error('Image and vals do not have the same size.')
end

for ic = 1:size(coords,1)
  img(coords(ic,1),coords(ic,2),coords(ic,3),indexes)   = vals(:,ic);
end

end