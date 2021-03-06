function out = isnanish(x)
  %ISNANISH True for NaN-like values.
  %
  % out = isna(x)
  %
  % isnanish() is a unification of isnan(), isnat(), and ismissing(). This is 
  % provided so you can write generic polymorphic code that operates on data
  % types that provide any of those functions.
  %
  % For string inputs, it does ismissing(x).
  % For datetime and duration inputs, it does isnat(x).
  % For all other inputs, it does isnan(x).
  %
  % This is an Octave extension.
  if isa(x, 'datetime') || isa(x, 'duration')
    out = isnat(x);
  elseif isa(x, 'string')
    out = ismissing(x);
  else
    out = isnan(x);
  end
end
