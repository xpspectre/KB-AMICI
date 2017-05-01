function c_ind = closest_ind(x, xs, eps)
% Find the index of the closest value to x in vector xs. Optionally specify
%   eps, which if nothing is within that, c_ind is blank []. If eps is not
%   specifid, then the closest, of any distance, is returned.
if nargin < 3
    eps = Inf;
end

[~, c_ind] = min(abs(xs - x));
if abs(x - xs(c_ind)) > eps
    c_ind = [];
end

end
