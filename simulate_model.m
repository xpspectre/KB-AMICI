function [x, y] = simulate_model(m, t, x0, p, opts)
% Simulate Model
%
% Inputs:
%   m [ Model ]
%       Finalized Model
%   t [ nt double vector ]
%       Timepoints to return results of simulation
%   x0 [ nx double vector, optional ]
%       Initial state values. If blank, use default values in model.
%   p [ np double vector, optional ]
%       Parameter values. If blank, use default values in model.
%   opts [ struct ]
%       Options struct with the following fields:
%       .
%
% Outputs:
%   x [ nt x nx double matrix ]
%       States at each timepoint
%   y [ nt x ny double matrix ]
%       Observations at each timepoint
%
% Note: This could be made a method (static method) of Model

if nargin < 5
    opts = [];
    if nargin < 4
        p = [];
        if nargin < 3
            x0 = [];
        end
    end
end

if isempty(p)
    p = [m.Parameters.Value];
end
assert(length(p) == m.np, 'Number of parameters does not match model')

sim_opts = amioption('sensi', 0);

if ~isempty(x0)
    assert(length(x0) == m.nx, 'Number of initial state values does not match model')
    sim_opts.x0 = x0;
end

[status, ~, x, y, ~, ~] = m.model_fun(t, p);
if status ~= 0
    error('Model integration failed')
end

end
