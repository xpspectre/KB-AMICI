function out = dxdotdp_model_adjoint_hessian(t,x,p,k)
%DXDOTDP_MODEL_ADJOINT_HESSIAN
%    out = DXDOTDP_MODEL_ADJOINT_HESSIAN(T,X,P,K)

%    This function was generated by the Symbolic Math Toolbox version 7.0.
%    01-Sep-2016 16:45:16

out = sparse([],[],[],1,3,2);
out(1) = -x(1)*heaviside(t - 2);
out(2) = 1;
