function [xs, ys] = simulate_models(m, t, opts)
% Simulate multiple Models or ModelVariants. Does not support overwriting
%   state initial values or parameters - do this with the multiple models
%   or model variants.
%
% Inputs:
%   m [ nm array of Model or ModelVariant ]
%       Finalized Models or ModelVariants. All m must be either Models or
%       Model Variants, no mixing.
%   t [ nt double vector | nm cell array of nt double vectors ]
%       Timepoints to return results of simulation. A single double vector
%       indicates use the same times for all models; a cell array indicates
%       use those times for each corresponding model.
%   opts [ struct ]
%       Options struct with the following fields:
%       .
%
% Outputs:
%   xs [ nm cell array of nt x nx double matrices ]
%       States at each timepoint for each model
%   ys [ nm cell array of nt x ny double matrices ]
%       Observations at each timepoint for each model
%
% Note: This could be made a method (static method) of Model

if nargin < 3
    opts = [];
end

nm = length(m);

% Standardize times to cell array of nt x 1 double vectors
if isnumeric(t)
    t = num2cell(repmat(t(:), 1, nm), 1);
else
    assert(iscell(t) && length(t) == nm);
    for im = 1:nm
        t{im} = t{im}(:);
    end
end

% Simulate all models
sim_opts = amioption('sensi', 0);
xs = cell(nm,1);
ys = cell(nm,1);
for im = 1:nm
    switch class(m)
        case 'Model'
            p_i = [m(im).Parameters.Value];
            [status, ~, x, y, ~, ~] = m(im).model_fun(t{im}, p_i, [], [], sim_opts);
        case 'ModelVariant'
            p_i = m(im).Parameters;
            sim_opts_i = sim_opts;
            sim_opts_i.x0 = m(im).StateInitialValues(:);
            [status, ~, x, y, ~, ~] = m(im).Model.model_fun(t{im}, p_i, [], [], sim_opts_i);
    end
    if status ~= 0
        error('Model integration failed')
    end
    xs{im} = x;
    ys{im} = y;
end

end
