function out = J_model_adjoint_hessian(t,x,p,k)
%J_MODEL_ADJOINT_HESSIAN
%    out = J_MODEL_ADJOINT_HESSIAN(T,X,P,K)

%    This function was generated by the Symbolic Math Toolbox version 7.0.
%    01-Sep-2016 16:45:15

out = sparse([],[],[],1,1,1);
out(1) = -p(1)*heaviside(t - 2);
