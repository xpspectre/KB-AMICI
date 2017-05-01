classdef Model < handle
    % ODE kinetic model
    %
    % TODO:
    % - dir path should probably generate the absolute path. If Model is called
    % from a script in another dir, alternatively fix path in caller.
    %   - General tweaks to improve reliability of managing paths and locations
    %   of functions
    % - Convert all names into internal symbolic names for flexibility in
    % handling invalid names. May also fix string->sym deprecation warning.
    
    properties
        Name
        Directory
        States
        Parameters
        Reactions
        Observations
        nx
        np
        nr
        ny
        sym_model
        model_fun
    end
    
    methods
        function self = Model(name, dir)
            if nargin == 0 % for superclass constructor
                self.Name = '';
                self.Directory = '';
            end
            self.Name = name;
            self.Directory = dir;
            
            self.States = struct('Name', {}, 'InitialValue', {});
            self.Parameters = struct('Name', {}, 'Value', {});
            self.Reactions = struct('Name', {}, 'Reactants', {}, 'Products', {}, 'Rate', {});
            self.Observations = struct('Name', {}, 'Value', {});
            
            self.nx = 0;
            self.np = 0;
            self.nr = 0;
            self.ny = 0;
        end
        
        function AddState(self, name, initial_value)
            ix = self.nx + 1;
            self.States(ix).Name = name;
            self.States(ix).InitialValue = initial_value;
            self.nx = ix;
        end
        
        function AddParameter(self, name, value)
            ip = self.np + 1;
            self.Parameters(ip).Name = name;
            self.Parameters(ip).Value = value;
            self.np = ip;
        end
        
        function AddReaction(self, name, reactants, products, fwd_rate, rev_rate)
            % Add reaction, optionally including reverse reaction
            % Note: nargin includes self
            %
            % Inputs:
            %   name [ string | 2 cell array of strings ]
            %       Name of forward reaction only, or cell array of forward and
            %       reverse reaction names. If rev_rate is specified, the
            %       2-element cell array must be specified.
            %   reactants [ cell array of strings ]
            %       Fwd reaction reactants. Blank cell array for no reactants.
            %   products [ cell array of strings ]
            %       Fwd reaction products. Blank cell array for no products.
            %   fwd_rate [ string ]
            %       Fwd reaction rate, including reactants (as needed)
            %   rev_rate [ string, optional ]
            %       Rev reaction rate, including products (as needed)
            if nargin == 5
                fwd_name = name;
            elseif nargin == 6 % reverse reaction present
                fwd_name = name{1};
                rev_name = name{2};
            end
            
            ir = self.nr + 1;
            self.Reactions(ir).Name = fwd_name;
            self.Reactions(ir).Reactants = reactants;
            self.Reactions(ir).Products = products;
            self.Reactions(ir).Rate = fwd_rate;
            
            if nargin == 6
                ir = ir + 1;
                self.Reactions(ir).Name = rev_name;
                self.Reactions(ir).Reactants = products;
                self.Reactions(ir).Products = reactants;
                self.Reactions(ir).Rate = rev_rate;
            end
            
            self.nr = ir;
        end
        
        function AddObservation(self, name, value)
            iy = self.ny + 1;
            self.Observations(iy).Name = name;
            self.Observations(iy).Value = value;
            self.ny = iy;
        end
        
        function Finalize(self, build_model)
            % Validate (in progress), generate, and compile model.
            %
            % Inputs:
            %   build_model [ {true} | false ]
            %       Optionally specify false to suppress amiwrap call.
            
            if nargin < 2
                build_model = true;
            end
            
            x_names = {self.States.Name};
            x = sym(x_names);
            x0 = {self.States.InitialValue};
            
            p_names = {self.Parameters.Name};
            p = sym(p_names);
            
            S = zeros(self.nx,self.nr);
            v = sym('v', [self.nr,1]);
            for ir = 1:self.nr
                reac = self.Reactions(ir).Reactants;
                nri = length(reac);
                for iri = 1:nri
                    ind = find(ismember(x_names, reac{iri}));
                    S(ind, ir) = S(ind, ir) - 1; % takes care of stoich > 1
                end
                
                prod = self.Reactions(ir).Products;
                npi = length(prod);
                for ipi = 1:npi
                    ind = find(ismember(x_names, prod{ipi}));
                    S(ind, ir) = S(ind, ir) + 1; % takes care of stoich > 1
                end
                
                rate = self.Reactions(ir).Rate;
                
                if ~verLessThan('matlab', '9.0'); st = warning('off', 'symbolic:sym:sym:DeprecateExpressions'); end
                v(ir) = sym(rate); % this just works if state names are valid. Need a step of string subs if they're not.
                if ~verLessThan('matlab', '9.0') && strcmp(st.state, 'on'); warning('on', 'symbolic:sym:sym:DeprecateExpressions'); end
            end
            xdot = S*v;
            
            y_vals = {self.Observations.Value};
            y = sym(y_vals);
            
            model.sym.x = x;
            model.sym.k = [];
            model.sym.event = [];
            model.sym.xdot = xdot;
            model.sym.p = p;
            model.sym.x0 = x0;
            model.sym.y = y;
            % model.sym.sigma_y = [];
            % model.sym.sigma_t = [];
            
            if ~exist(self.Directory, 'dir')
                mkdir(self.Directory);
            end
            
            o2_flag = false;
            
            if build_model
                amiwrap(self.Name, model, self.Directory, o2_flag);
            end
            addpath(self.Directory); % adding to path is idempotent
            self.model_fun = str2func(['simulate_' self.Name]);
        end
    end
    
end
