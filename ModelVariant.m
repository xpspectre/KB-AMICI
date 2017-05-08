classdef ModelVariant < handle
    % Variation of a model that (optionally) changes state initial values
    % and parameter values. For now, the constructor lets you override all
    % the vals (tip: take the model's initial conditions and modify select
    % ones). TODO: API for changing specific vals by name.
    
    properties
        Name
        Model
        StateInitialValues
        Parameters
    end
    
    methods
        function self = ModelVariant(name, model, x0, p)
            % Construct new model variant
            %
            % Inputs:
            %   name [ string ]
            %       Name of model variant
            %   model [ Model ]
            %       Base model this modifies. Sanity checks will be done on
            %       x0 and p to make sure this ModelVariant is valid.
            %   x0 [ nx double array {[]} ]
            %       Constant state initial values to override model's. Specify
            %       x0 for all states, but only the values corresponding to
            %       constant ICs (not ones specified by expression) will be
            %       used.
            %   p [ np double array {[]} ]
            %       Parameter values to override model's
            if nargin == 0 % for superclass constructor
                % Initialize everything to blank
                return
            end
            if nargin < 4
                p = [];
                if nargin < 3
                    x0 = [];
                end
            end
            if isempty(x0)
                x0 = [model.States.InitialValue];
            end
            if isempty(p)
                p = [model.Parameters.Value];
            end
            self.Name = name;
            self.Model = model;
            nx = model.nx;
            np = model.np;
            assert(length(x0) == nx)
            assert(length(p) == np)
            self.StateInitialValues = x0;
            self.Parameters = p;
        end
    end
    
end

