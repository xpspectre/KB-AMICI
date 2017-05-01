function D = build_amici_data(data)
% Construct model data in form AMICI expects from general data struct. The
%   input data struct is a series of arrays with corresponding entries
%   indicating each point.
%
% Inputs:
%   data [ struct ]
%       Struct of data with fields:
%       .output_inds [ nmeas int array ]
%           Output index of each measurement
%       .times [ nmeas double array ]
%           Time of each measurement
%       .measurements [ nmeas double array ]
%           Value of each measurement
%       .std_devs [ nmeas_double array ]
%           Std dev of each measurement
%       .ny [ scalar int ]
%           The total number of outputs. Values from data are filled where
%           specified and everything else is NaN.
%
% Outputs:
%   D [ amidata ]
%       amidata object for AMICI

% Convert data into proper form
t = unique(data.times);
nt = length(t);
ny = data.ny;
Y = nan(nt,ny);
SY = nan(nt,ny);
for iy = 1:ny
    mask_iy = data.output_inds == iy;
    times_iy = data.times(mask_iy);
    measurements_iy = data.measurements(mask_iy);
    std_devs_iy = data.std_devs(mask_iy);
    nm = length(times_iy);
    for im = 1:nm
        c_ind = closest_ind(times_iy(im), t, 1e-6); % get corresponding timepoint
        Y(c_ind,iy) = measurements_iy(im);
        SY(c_ind,iy) = std_devs_iy(im);
    end
end

% Assign data to AMICI options
D = [];
D.t = t;
D.Y = Y;
D.Sigma_Y = SY;
D = amidata(D);
end
