classdef Fit < handle
    % Specifies fitting properties for simple weighted sum of squares
    % objective function (the built-in on in AAMICI) fit. This class just
    % holds stuff for a fitting function.
    %
    % TODO: Sanity checks on options - make sure they match model
    
    properties
        Name
        Model % can also be ModelVariant
        Data
        Opts
    end
    
    methods
        function self = Fit(name, model, data, opts)
            % Construct new Fit
            %
            % Inputs:
            %   name [ string ]
            %       Name of fit
            %   model [ Model | ModelVariant ]
            %       Base model or model variant this applies to.
            %   data [ struct ]
            %       Experimental data struct with fields:
            %       .obs_inds [ nd int array ]
            %           Observation index of each measurement
            %       .times [ nd double array ]
            %           Time of each nd
            %       .measurements [ nmeas double array ]
            %           Value of each measurement
            %       .std_devs [ nd double array ]
            %           Std dev of each measurement
            %   opts [ struct ]
            %       Options struct with fields:
            %       .sens_method [ {'fwd'} | 'adj' ]
            %           Forward or adjoint sensitivity calculation method. Forward is
            %           better tested and faster for smaller models. Adjoint is better
            %           for very large models.
            %       .p0 [ np double array {model parameter values} ]
            %           Initial guesses for fit parameters
            %       .p_lo [ np double array {-inf(1,np)} ]
            %           Lower bounds for fit parameters
            %       .p_hi [ np double array {inf(1,np)} ]
            %           Upper bounds for fit parameters
            %       .p_fit [ np int array {ones(1,np)} ]
            %           Specification of fitting status. 0 in a position
            %           indicates don't fit. Nonzero integers indicate fit,
            %           sharing the same value as parameters in other
            %           models with the same integer. Default is to fit all
            %           parameters, and if there are multiple models, to
            %           make them share the parameter (all 1 across models for
            %           each param).
            if nargin == 0 % for superclass constructor
                % Initialize everything to blank
                return
            end
            if nargin < 4
                opts = [];
            end
            
            % Default options
            opts_ = [];
            opts_.sens_method = 'fwd';
            switch class(model)
                case 'Model'
                    opts_.p0 = [model.Parameters.Value];
                case 'ModelVariant'
                    opts_.p0 = model.Parameters;
            end
            np = length(opts_.p0);
            opts_.p_lo = -inf(1,np);
            opts_.p_hi = inf(1,np);
            opts_.p_fit = ones(1,np);
            opts = merge_structs(opts_, opts);
            
            self.Name = name;
            self.Model = model;
            self.Data = data;
            self.Opts = opts;
        end
    end
    
end

