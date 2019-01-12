function out = startsWith(str, pattern, varargin)
  %STARTSWITH Determine if string starts with pattern
  str = cellstr(str);
  pattern = char(pattern);
  if isequal(varargin, {'IgnoreCase',true})
    str = lower(str);
    pattern = lower(pattern);
  end
  out = false(size(str));
  n = numel(pattern);
  for i = 1:numel(str)
    str_i = str{i};
    if numel(str_i) >= n
      out(i) = isequal(str_i(1:n), pattern);
    end
  end
end
