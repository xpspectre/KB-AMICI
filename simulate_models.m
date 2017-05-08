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
    % Get components from Models and ModelVariants
    switch class(m)
        case 'Model'
            model = m(im);
            p = [model.Parameters.Value];
        case 'ModelVariant'
            model = m(im).Model;
            p = m(im).Parameters;
    end
    nx = model.nx;
    
    % Get constant ICs
    ic_is_const = false(nx,1);
    ic_const = zeros(nx,1);
    for ix = 1:nx
        if isnumeric(model.States(ix).InitialValue)
            ic_is_const(ix) = true;
            switch class(m)
                case 'Model'
                    ic_const(ix) = model.States(ix).InitialValue;
                case 'ModelVariant'
                    ic_const(ix) = m(im).StateInitialValues(ix);
            end
        end
    end
    k = ic_const(ic_is_const);
    
    % Simulate
    [status, ~, x, y, ~, ~] = model.model_fun(t{im}, p, k, [], sim_opts);
    if status ~= 0
        error('Model integration failed')
    end
    xs{im} = x;
    ys{im} = y;
end

end
