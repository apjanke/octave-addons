classdef datetime
  %DATETIME Date/time values
  %
  % Datetime represents points in time using the ISO calendar.
  %
  % This is an attempt to reproduce the functionality of Matlab's @datetime. It
  % also contains some Octave-specific extensions.
  %
  % TODO: Time zone support
  % TODO: Remove proxykeys; they're not needed for a single numeric field.
  
  % @planarprecedence(dnums)
  % @planarsetops
  % @planarrelops
  
  properties (Access = private)
    dnums % @planar
  end
  properties
    % Time zone code as charvec
    TimeZone = ''
  end
  
  methods (Static)
    function out = ofDatenum(dnums)
      %OFDATENUM Convert datenums to datetimes.
      %
      % This is an Octave extension.
      out = datetime(dnums, 'ConvertFrom', 'datenum');
    end
  end

  methods
    
    function this = datetime(varargin)
      %DATETIME Construct a new datetime array.
      
      % TODO: Going to have to redo this whole thing to support trailing name/val
      % options like 'TimeZone','local' and 'Format','xxxx'.
      switch nargin
        case 0
          this = datetime(now, 'ConvertFrom', 'datenum');
        case 1
          x = varargin{1};
          if isnumeric(x)
            % Convert date vectors
            this.dnums = datenum(x);
          elseif ischar(x) || iscellstr(x) || isa(x, 'string')
            x = cellstr(x);
            tfRelative = ismember(x, {'today','tomorrow','yesterday','now'});
            if all(tfRelative)
              if ~isscalar(x)
                error('Multiple arguments not allowed for relativeDay format');
              end
              switch x{1}
                case 'yesterday'
                  this.dnums = floor(now) - 1;
                case 'today'
                  this.dnums = floor(now);
                case 'tomorrow'
                  this.dnums = floor(now) + 1;
                case 'now'
                  this.dnums = now;
              end
            else
              % They're datestrs
              this.dnums = reshape(datenum(x), size(x));
            end
          end
        case 2
          error('Invalid number of inputs: %d', nargin);
        case 3
          [in1,in2,in3] = varargin{:};
          if isequal(in2, 'ConvertFrom')
            switch in3
              case 'datenum'
                this.dnums = double(in1);
              otherwise
                error('Unsupported ConvertFrom format: %s', in3);
                % TODO: Implement more formats
            end
          elseif isequal(in2, 'InputFormat')
            dstrs = cellstr(in1);
            format = in3;
            this.dnums = reshape(datenum(dstrs, format), size(dstrs));
          elseif isnumeric(in2)
            [Y,M,D] = varargin{:};
            this.dnums = datenum(Y, M, D);
          end
        case 4
          error('Invalid number of inputs: %d', nargin);
        case 5
          error('Invalid number of inputs: %d', nargin);
        case 6
          [Y,M,D,H,MI,S] = varargin{:};
          this.dnums = datenum(Y, M, D, H, MI, S);
        case 7
          [Y,M,D,H,MI,S,MS] = varargin{:};
          this.dnums = datenum(Y, M, D, H, MI, S, MS);
        otherwise
          error('Invalid number of inputs: %d', nargin);
      end    
    end
      
    function display(this)
      %DISPLAY Custom display.
      in_name = inputname(1);
      if ~isempty(in_name)
        fprintf('%s =\n', in_name);
      end
      disp(this);
    end

    function disp(this)
      %DISP Custom display.
      if isempty(this)
        fprintf('Empty %s %s\n', size2str(size(this)), class(this));
      elseif isscalar(this)
        str = dispstrs(this);
        str = str{1};
        if ~isempty(this.TimeZone)
          str = [str ' ' this.TimeZone'];
        end
        fprintf(' %s\n', str);
      else
        out = octave.internal.util.format_dispstr_array(dispstrs(this));
        fprintf('%s', out);
        if ~isempty(this.TimeZone)
          fprintf('%s', this.TimeZone);
        end
      end
    end
    
    function out = dispstrs(this)
      %DISPSTRS Custom display strings.
      % This is an Octave extension.
      strs = cellstr(datestr(this.dnums));
      out = reshape(strs, size(this));
    end
    
    function out = datestr(this, varargin)
      %DATESTR Format as date string.
      out = datestr(this.dnums, varargin{:});
    end
    
    function out = datestrs(this, varargin)
      %DATESTSRS Format as date strings.
      % Returns cellstr.
      % This is an Octave extension.
      s = datestr(this);
      c = cellstr(s);
      out = reshape(c, size(this));
    end
    
    function out = isnat(this)
      %ISNAT True if input is NaT.
      out = isnan(this.dnums);
    end
    
    function out = isnan(this)
      %ISNAN Alias for isnat.
      % This is an Octave extension
      out = isnat(this);
    end
    
    % Relational operations

    function out = lt(A, B)
      %LT Less than.
      [A, B] = promote(A, B);
      out = A.dnums < B.dnums;
    end

    function out = le(A, B)
      %LE Less than or equal.
      [A, B] = promote(A, B);
      out = A.dnums <= B.dnums;
    end

    function out = ne(A, B)
      %NE Not equal.
      [A, B] = promote(A, B);
      out = A.dnums ~= B.dnums;
    end

    function out = eq(A, B)
      %EQ Equals.
      [A, B] = promote(A, B);
      out = A.dnums == B.dnums;
    end

    function out = ge(A, B)
      %GE Greater than or equal.
      [A, B] = promote(A, B);
      out = A.dnums >= B.dnums;
    end

    function out = gt(A, B)
      %GT Greater than.
      [A, B] = promote(A, B);
      out = A.dnums > B.dnums;
    end

    % Arithmetic
    
    function out = plus(A, B)
      %PLUS Addition
      if ~isa(A, 'datetime')
        error('Expected left-hand side of A + B to be a datetime; got a %s', ...
          class(A));
      end
      if isa(B, 'duration')
        out = A;
        out.dnums = A.dnums + B.days;
      elseif isa(B, 'double')
        out = A + duration.ofDays(B);
      else
        error('Invalid input type: %s', class(B));
      end
    end
    
    function out = minus(A, B)
      %MINUS Subtraction
      out = A + -B;
    end
  end

  %%%%% START PLANAR-CLASS BOILERPLATE CODE %%%%%
  
  % This section contains code auto-generated by Janklab's genPlanarClass.
  % Do not edit code in this section manually.
  % Do not remove the "%%%%% START/END .... %%%%%" header or footer either;
  % that will cause the code regeneration to break.
  % To update this code, re-run jl.code.genPlanarClass() on this file.
  
  methods

    function out = numel(this)
    %NUMEL Number of elements in array.
    out = numel(this.dnums);
    end
    
    function out = ndims(this)
    %NDIMS Number of dimensions.
    out = ndims(this.dnums);
    end
    
    function out = size(this)
    %SIZE Size of array.
    out = size(this.dnums);
    end
    
    function out = isempty(this)
    %ISEMPTY True for empty array.
    out = isempty(this.dnums);
    end
    
    function out = isscalar(this)
    %ISSCALAR True if input is scalar.
    out = isscalar(this.dnums);
    end
    
    function out = isvector(this)
    %ISVECTOR True if input is a vector.
    out = isvector(this.dnums);
    end
    
    function out = iscolumn(this)
    %ISCOLUMN True if input is a column vector.
    out = iscolumn(this.dnums);
    end
    
    function out = isrow(this)
    %ISROW True if input is a row vector.
    out = isrow(this.dnums);
    end
    
    function out = ismatrix(this)
    %ISMATRIX True if input is a matrix.
    out = ismatrix(this.dnums);
    end
        
    function this = reshape(this, varargin)
    %RESHAPE Reshape array.
    this.dnums = reshape(this.dnums, varargin{:});
    end
    
    function this = squeeze(this, varargin)
    %SQUEEZE Remove singleton dimensions.
    this.dnums = squeeze(this.dnums, varargin{:});
    end
    
    function this = circshift(this, varargin)
    %CIRCSHIFT Shift positions of elements circularly.
    this.dnums = circshift(this.dnums, varargin{:});
    end
    
    function this = permute(this, varargin)
    %PERMUTE Permute array dimensions.
    this.dnums = permute(this.dnums, varargin{:});
    end
    
    function this = ipermute(this, varargin)
    %IPERMUTE Inverse permute array dimensions.
    this.dnums = ipermute(this.dnums, varargin{:});
    end
    
    function this = repmat(this, varargin)
    %REPMAT Replicate and tile array.
    this.dnums = repmat(this.dnums, varargin{:});
    end
    
    function this = ctranspose(this, varargin)
    %CTRANSPOSE Complex conjugate transpose.
    this.dnums = ctranspose(this.dnums, varargin{:});
    end
    
    function this = transpose(this, varargin)
    %TRANSPOSE Transpose vector or matrix.
    this.dnums = transpose(this.dnums, varargin{:});
    end
    
    function [this, nshifts] = shiftdim(this, n)
    %SHIFTDIM Shift dimensions.
    if nargin > 1
        this.dnums = shiftdim(this.dnums, n);
    else
        [this.dnums,nshifts] = shiftdim(this.dnums);
    end
    end
    
    function out = cat(dim, varargin)
    %CAT Concatenate arrays.
    args = varargin;
    for i = 1:numel(args)
        if ~isa(args{i}, 'datetime')
            args{i} = datetime(args{i});
        end
    end
    out = args{1};
    fieldArgs = cellfun(@(obj) obj.dnums, args, 'UniformOutput', false);
    out.dnums = cat(dim, fieldArgs{:});
    end
    
    function out = horzcat(varargin)
    %HORZCAT Horizontal concatenation.
    out = cat(2, varargin{:});
    end
    
    function out = vertcat(varargin)
    %VERTCAT Vertical concatenation.
    out = cat(1, varargin{:});
    end
    
    function this = subsasgn(this, s, b)
    %SUBSASGN Subscripted assignment.
    
    % Chained subscripts
    if numel(s) > 1
        rhs_in = subsref(this, s(1));
        rhs = subsasgn(rhs_in, s(2:end), b);
    else
        rhs = b;
    end
    
    % Base case
    switch s(1).type
        case '()'
            this = subsasgnParensPlanar(this, s(1), rhs);
        case '{}'
            error('jl:BadOperation',...
                '{}-subscripting is not supported for class %s', class(this));
        case '.'
            this.(s(1).subs) = rhs;
    end
    end
    
    function out = subsref(this, s)
    %SUBSREF Subscripted reference.
    
    % Base case
    switch s(1).type
        case '()'
            out = subsrefParensPlanar(this, s(1));
        case '{}'
            error('jl:BadOperation',...
                '{}-subscripting is not supported for class %s', class(this));
        case '.'
            out = this.(s(1).subs);
    end
    
    % Chained reference
    if numel(s) > 1
        out = subsref(out, s(2:end));
    end
    end
        
    function [out,Indx] = sort(this)
    %SORT Sort array elements.
    if isvector(this)
        isRow = isrow(this);
        this = subset(this, ':');
        % NaNs sort stably to end, so handle them separately
        tfNan = isnan(this);
        nans = subset(this, tfNan);
        nonnans = subset(this, ~tfNan);
        ixNonNan = find(~tfNan);
        proxy = proxyKeys(nonnans);
        [~,ix] = sortrows(proxy);
        out = [subset(nonnans, ix); nans];
        Indx = [ixNonNan(ix); find(tfNan)];
        if isRow
            out = out';
        end
    elseif ismatrix(this)
        out = this;
        Indx = NaN(size(out));
        for iCol = 1:size(this, 2)
            [sortedCol,Indx(:,iCol)] = sort(subset(this, ':', iCol));
            out = asgn(out, {':', iCol}, sortedCol);
        end
    else
        % I believe this multi-dimensional implementation is correct,
        % but have not tested it yet. Use with caution.
        out = this;
        Indx = NaN(size(out));
        sz = size(this);
        nDims = ndims(this);
        ixs = [{':'} repmat({1}, [1 nDims-1])];
        while true
            col = subset(this, ixs{:});
            [sortedCol,sortIx] = sort(col);
            Indx(ixs{:}) = sortIx;
            out = asgn(out, ixs, sortedCol);
            ixs{end} = ixs{end}+1;
            for iDim=nDims:-1:3
                if ixs{iDim} > sz(iDim)
                    ixs{iDim-1} = ixs{iDim-1} + 1;
                    ixs{iDim} = 1;
                end
            end
            if ixs{2} > sz(2)
                break;
            end
        end
    end
    end
    
    function [out,Indx] = unique(this, varargin)
    %UNIQUE Set unique.
    flags = setdiff(varargin, {'rows'});
    if ismember('rows', varargin)
        [~,proxyIx] = unique(this);
        proxyIx = reshape(proxyIx, size(this));
        [~,Indx] = unique(proxyIx, 'rows', flags{:});
        out = subset(this, Indx, ':');
    else
        isRow = isrow(this);
        this = subset(this, ':');
        tfNaN = isnan(this);
        nans = subset(this, tfNaN);
        nonnans = subset(this, ~tfNaN);
        ixNonnan = find(~tfNaN);
        keys = proxyKeys(nonnans);
        if isa(keys, 'table')
            [~,ix] = unique(keys, flags{:});
        else
            [~,ix] = unique(keys, 'rows', flags{:});
        end
        out = [subset(nonnans, ix); nans];
        Indx = [ixNonnan(ix); find(tfNaN)];
        if isRow
            out = out';
        end
    end
    end
    
    function [out,Indx] = ismember(a, b, varargin)
    %ISMEMBER True for set member.
    if ismember('rows', varargin)
        error('ismember(..., ''rows'') is unsupported');
    end
    if ~isa(a, 'datetime')
        a = datetime(a);
    end
    if ~isa(b, 'datetime')
        b = datetime(b);
    end
    [proxyA, proxyB] = proxyKeys(a, b);
    [out,Indx] = ismember(proxyA, proxyB, 'rows');
    out = reshape(out, size(a));
    Indx = reshape(Indx, size(a));
    end
    
    function [out,Indx] = setdiff(a, b, varargin)
    %SETDIFF Set difference.
    if ismember('rows', varargin)
        error('setdiff(..., ''rows'') is unsupported');
    end
    [tf,~] = ismember(a, b);
    out = parensRef(a, ~tf);
    Indx = find(~tf);
    [out,ix] = unique(out);
    Indx = Indx(ix);
    end
    
    function [out,ia,ib] = intersect(a, b, varargin)
    %INTERSECT Set intersection.
    if ismember('rows', varargin)
        error('intersect(..., ''rows'') is unsupported');
    end
    [proxyA, proxyB] = proxyKeys(a, b);
    [~,ia,ib] = intersect(proxyA, proxyB, 'rows');
    out = parensRef(a, ia);
    end
    
    function [out,ia,ib] = union(a, b, varargin)
    %UNION Set union.
    if ismember('rows', varargin)
        error('union(..., ''rows'') is unsupported');
    end
    [proxyA, proxyB] = proxyKeys(a, b);
    [~,ia,ib] = union(proxyA, proxyB, 'rows');
    aOut = parensRef(a, ia);
    bOut = parensRef(b, ib);
    out = [parensRef(aOut, ':'); parensRef(bOut, ':')];
    end
    
    function [keysA,keysB] = proxyKeys(a, b)
    %PROXYKEYS Proxy key values for sorting and set operations
    propertyValsA = {a.dnums};
    propertyTypesA = cellfun(@class, propertyValsA, 'UniformOutput',false);
    isAllNumericA = all(cellfun(@isnumeric, propertyValsA));
    propertyValsA = cellfun(@(x) x(:), propertyValsA, 'UniformOutput',false);
    if nargin == 1
        if isAllNumericA && isscalar(unique(propertyTypesA))
            % Properties are homogeneous numeric types; we can use them directly 
            keysA = cat(2, propertyValsA{:});
        else
            % Properties are heterogeneous or non-numeric; resort to using a table
            propertyNames = {'dnums'};
            keysA = table(propertyValsA{:}, 'VariableNames', propertyNames);
        end
    else
        propertyValsB = {b.dnums};
        propertyTypesB = cellfun(@class, propertyValsB, 'UniformOutput',false);
        isAllNumericB = all(cellfun(@isnumeric, propertyValsB));
        propertyValsB = cellfun(@(x) x(:), propertyValsB, 'UniformOutput',false);
        if isAllNumericA && isAllNumericB && isscalar(unique(propertyTypesA)) ...
            && isscalar(unique(propertyTypesB))
            % Properties are homogeneous numeric types; we can use them directly
            keysA = cat(2, propertyValsA{:});
            keysB = cat(2, propertyValsB{:});
        else
            % Properties are heterogeneous or non-numeric; resort to using a table
            propertyNames = {'dnums'};
            keysA = table(propertyValsA{:}, 'VariableNames', propertyNames);
            keysB = table(propertyValsB{:}, 'VariableNames', propertyNames);
        end
    end
    end
  
  end
  
  methods (Access=private)
  
    function this = subsasgnParensPlanar(this, s, rhs)
    %SUBSASGNPARENSPLANAR ()-assignment for planar object
    if ~isa(rhs, 'datetime')
        rhs = datetime(rhs);
    end
    this.dnums(s.subs{:}) = rhs.dnums;
    end
    
    function out = subsrefParensPlanar(this, s)
    %SUBSREFPARENSPLANAR ()-indexing for planar object
    out = this;
    out.dnums = this.dnums(s.subs{:});
    end
    
    function out = parensRef(this, varargin)
    %PARENSREF ()-indexing, for this class's internal use
    out = subsrefParensPlanar(this, struct('subs', {varargin}));
    end
    
    function out = subset(this, varargin)
    %SUBSET Subset array by indexes.
    % This is what you call internally inside the class instead of doing 
    % ()-indexing references on the RHS, which don't work properly inside the class
    % because they don't respect the subsref() override.
    out = parensRef(this, varargin{:});
    end
    
    function out = asgn(this, ix, value)
    %ASGN Assign array elements by indexes.
    % This is what you call internally inside the class instead of doing 
    % ()-indexing references on the LHS, which don't work properly inside
    % the class because they don't respect the subsasgn() override.
    if ~iscell(ix)
        ix = { ix };
    end
    s.type = '()';
    s.subs = ix;
    out = subsasgnParensPlanar(this, s, value);
    end
  
  end
  
  %%%%% END PLANAR-CLASS BOILERPLATE CODE %%%%%

end


%%%%% START PLANAR-CLASS BOILERPLATE LOCAL FUNCTIONS %%%%%

% This section contains code auto-generated by Janklab's genPlanarClass.
% Do not edit code in this section manually.
% Do not remove the "%%%%% START/END .... %%%%%" header or footer either;
% that will cause the code regeneration to break.
% To update this code, re-run jl.code.genPlanarClass() on this file.

function out = isnan2(x)
%ISNAN2 True if input is NaN or NaT
% This is a hack to work around the edge case of @datetime, which 
% defines an isnat() function instead of supporting isnan() like 
% everything else.
if isa(x, 'datetime')
    out = isnat(x);
else
    out = isnan(x);
end
end

%%%%% END PLANAR-CLASS BOILERPLATE LOCAL FUNCTIONS %%%%%

function varargout = promote(varargin)
  %PROMOTE Promote inputs to be compatible
  %
  % TODO: TimeZone comparison and conversion
  varargout = varargin;
  for i = 1:numel(varargin)
    if ~isa(varargin{i}, 'datetime')
      varargout{i} = datetime(varargin{i});
    end
  end
end
