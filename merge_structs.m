function merged = merge_structs(under, over)
% Merge over struct on top of under struct, where:
%   - Fields in over replace corresponding fields of under
%   - Fields in over not in under are lost
%   - Remaining fields in under not in over are kept
% Field names are case sensitive. This function is useful for assigning
%   default options.
merged = under;
overwrite_names = intersect(fieldnames(under), fieldnames(over));
n = length(overwrite_names);
for i = 1:n
    name = overwrite_names{i};
    merged.(name) = over.(name);
end
end

