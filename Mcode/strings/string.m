classdef string
    %STRING A basic Octave @string implementation for demo purposes
    %
    % This is not production-ready! It's just an example of how @string could be
    % implemented in M-code.
    %
    % This implementation uses the Java Standard Library for Unicode support. It
    % would need to be replaced with a C/C++ Unicode library of some sort, since
    % Java is not guaranteed to be available in all Octave builds.
    %
    % You'd also need to add all the string-manipulation stuff like erase(),
    % extract*(), insert*(), and so on.
    %
    % TODO: "missing" value support. Probably need a planar flag field for that.
    
    properties
        % The underlying char data, as cellstr
        strs = {''};  % @planar
    end
    
    methods
      function this = string(in)
        %STRING Construct a new string
        %
        % this = string(in)
        %
        % In may be:
        %  - char
        %  - cellstr
        %  - anything that supports cellstr(in)
        if nargin == 0
          return
        end
        if isa(in, 'string')
          this = in;
          return;
        end
        if isnumeric(in)
          s = cell(size(in));
          for i = 1:numel(in)
            s{i} = sprintf('%f', in(i));
          end
          this.strs = s;
        else
          this.strs = cellstr(in);
        end
      end
      
      function out = isstring(this)
        %ISSTRING True if input is a string array
        out = true;
      end

      function display(this)
        %DISPLAY Custom display
        in_name = inputname(1);
        if ~isempty(in_name)
          fprintf('%s =\n', in_name);
        end
        disp(this);
      end

      function disp(this)
        %DISP Custom display
        if isempty(this)
          fprintf('Empty %s string\n', size2str(size(this)));
          return;
        end

        my_dispstrs = strcat({'"'}, this.strs, {'"'});
        my_dispstrs = strrep(my_dispstrs, sprintf('\r'), '\r');
        my_dispstrs = strrep(my_dispstrs, sprintf('\n'), '\n');
        out = octave.internal.util.format_dispstr_array(my_dispstrs);
        fprintf('%s', out);
      end

      function [out,Indx] = sort(this, varargin)
        %SORT Sort array elements.
        out = this;
        [out.strs,Indx] = sort(this.strs, varargin{:});
      end

      function out = isnan(this)
        %ISNAN True for Not-a-Number.
        out = false(size(this.strs));
      end
      
      % String manipulation functions
      
      function out = strlength(this)
        %STRLENGTH Counts string length in *bytes*, not characters!
        out = cellfun(@numel, this.strs);
      end
      
      function out = strlengthu(this)
        %STRLENGTHU String length in Unicode characters (code points)
        out = NaN(size(this));
        for i = 1:numel(out)
          % This would need to be replaced with a non-Java implementation
          j_str = javaObject('java.lang.String', this.strs{i});
          out = javaMethod('codePointCount', j_str, 0, numel(this.strs{i}));
        end
      end
      
      function out = reverse(this)
        %REVERSE Reverse string, *byte-wise* (not character-wise)
        out = this;
        for i = 1:numel(this)
          out.strs{i} = out.strs{i}(end:-1:1);
        end
      end
      
      function out = reverseu(this)
        %REVERSEU Reverse string, character-wise
        out = this;
        % Transcode to UTF-32 (since UTF-32 is a fixed-width encoding), 
        % reverse that, and transcode back to original encoding
        bytess = encode(this, 'UTF-32LE');
        for i = 1:numel(this)
          bytes = bytess{i};
          utf32 = typecast(bytes, 'uint32');
          utf32_reverse = utf32(end:-1:1);
          bytes2 = typecast(utf32_reverse, 'uint8');
          java_str = javaObject('java.lang.String', bytes2, 'UTF-32LE');
          reversed = char(java_str);
          out.strs{i} = reversed;
        end
      end
      
      function out = strcat(varargin)
        %STRCAT Concatenate strings
        args = varargin;
        for i = 1:numel(args)
          if ~isa(args{i}, 'string')
              args{i} = string(args{i});
          end
        end
        args2 = cell(size(args));
        for i = 1:numel(args2)
          args2{i} = args{i}.strs;
        end
        out = string(strcat(args2{:}));
      end
      
      function out = plus(a, b)
        %PLUS Alias for strcat
        a = string(a);
        b = string(b);
        out = strcat(a, b);
      end
      
      function out = lower(this)
        %LOWER Convert to lower case
        out = this;
        out.strs = lower(this.strs);
      end
      
      function out = upper(this)
        %UPPER Convert to upper case
        out = this;
        out.strs = upper(this.strs);
      end
      
      function out = erase(this, match)
        %ERASE matching substring
        out = this;
        out.strs = strrep(this.strs, char(match), '');
      end
      
      function out = strrep(this, match, replacement, varargin)
        %STRREP Replace occurrences of pattern with other string
        out = this;
        out.strs = strrep(this.strs, char(match), char(replacement), varargin{:});
      end

      function out = strfind(this, pattern, varargin)
        %STRFIND Find pattern in string
        out = strfind(this.strs, char(pattern), varargin{:});
      end
      
      function out = regexprep(this, pat, repstr, varargin)
        %REGEXPREP Replace regular expression patterns in string
        args = demote_strings(varargin);
        out = this;
        out.strs = regexprep(this.strs, char(pat), char(repstr), args{:});
      end

      % TODO: split, findstr, startsWith, endsWith, regexp
      % regexp will be the hard one because its signature is so variable.
      
      % Type conversions
      
      function out = cellstr(this)
        %CELLSTR Convert to cellstr
        out = this.strs;
      end
      
      function out = cell(this)
        %CELL Convert to cell
        out = this.strs;
      end      
      
      function out = char(this)
        %CHAR Convert to char
        out = char(cellstr(this));
      end
      
      function out = double(this)
        %DOUBLE Convert to double
        out = str2double(this.strs);
        % TODO: A complex number conversion?        
      end
      
      % TODO: Conversion to int types. This may require extensions to sscanf, since
      % I don't see a way of parsing integers (especially wide ones like uint64)
      % with the current functionality.
      
      % Encoding
      
      function out = encode(this, charsetName)
        %ENCODE Encode this string in a given encoding
        %
        % Returns the encoded strings as uint8 arrays wrapped in a cell array.
        %
        % See also: STRING.DECODE
        out = cell(size(this));
        for i = 1:numel(this)
          java_str = javaObject('java.lang.String', this.strs{i});
          java_bytes = javaMethod('getBytes', java_str, charsetName);
          out{i} = typecast(java_bytes', 'uint8');
        end
      end
      
      % Structural, collection, and identity operations
      
      function out = eq(A, B)
        %EQ Equals.
        out = strcmp(A, B);
      end
      
      function out = cmp(A, B)
        %CMP C-style strcmp, with -1/0/+1 return value
        A = string(A);
        B = string(B);
        % In production code, you wouldn't scalarexpand; you'd do a scalar test
        % and smarter indexing.
        % Though really, in production code, you'd want to implement this whole function
        % as a built-in or MEX file.
        [A, B] = scalarexpand(A, B);
        out = NaN(size(A));
        for i = 1:numel(A)
          a = A.strs{i};
          b = B.strs{i};
          if isequal(a, b)
            out(i) = 0;
          else
            tmp = [a b];
            [tmp2,ix] = sort(tmp);
            if ix(1) == 1
              out(i) = -1;
            else
              out(i) = 1;
            end
          end
        end
      end
      
      function out = lt(A, B)
        %LT Less than.
        out = cmp(A, B) < 0;
      end

      function out = le(A, B)
        %LE Less than or equal.
        out = cmp(A, B) <= 0;
      end

      function out = gt(A, B)
        %GT Greater than.
        out = cmp(A, B) > 0;
      end

      function out = ge(A, B)
        %GE Greater than or equal.
        out = cmp(A, B) >= 0;
      end
      
      % TODO: max, min

      function [out,Indx] = ismember(a, b, varargin)
        %ISMEMBER True for set member.
        fprintf('ismember\n');
        if ~isa(a, 'string')
            a = string(a);
        end
        if ~isa(b, 'string')
            b = string(b);
        end
        [out, Indx] = ismember(a.strs, b.strs, varargin{:});
      end
      
      function [out,Indx] = setdiff(a, b, varargin)
        %SETDIFF Set difference.
        a = string(a);
        b = string(b);
        [s_out,Indx] = setdiff(a.strs, b.strs, varargin{:});
        out = string(s_out);
      end

      function [out,ia,ib] = intersect(a, b, varargin)
        %INTERSECT Set intersection.
        a = string(a);
        b = string(b);
        [s_out,ia,ib] = intersect(a.strs, b.strs, varargin{:});
        out = string(s_out);
      end
      
      function [out,ia,ib] = union(a, b, varargin)
        %UNION Set union.
        a = string(a);
        b = string(b);
        [s_out,ia,ib] = union(a.strs, b.strs, varargin{:});
        out = string(s_out);
      end

      function [out,Indx] = unique(this, varargin)
        %UNIQUE Set unique.
        [s_out,Indx] = unique(this.strs, varargin{:});
        out = string(s_out);
      end
      
      % Compatibility shims
      
      function out = sprintf(fmt, varargin)
        %SPRINTF Like printf, but returns a string
        fmt = char(string(fmt));
        args = demote_strings(varargin);
        out = string(sprintf(fmt, args{:}));
      end
      
      function out = fprintf(varargin)
        %FPRINTF Formatted output to stream or file handle
        args = demote_strings(varargin);
        out = fprintf(args{:});
        if nargout == 0
          clear out
        end
      end

      function out = printf(varargin)
        %PRINTF Formatted output
        args = demote_strings(varargin);
        printf(args{:});
        if nargout == 0
          clear out
        end
      end

      % TODO: fdisp, fputs, fwrite
      
      % plot() and related functions. Yuck.
      
      function out = plot(varargin)
        args = demote_strings(varargin);
        out = plot(args{:});
      end
      
      function out = plotyy(varargin)
        args = demote_strings(varargin);
        out = plotyy(args{:});
      end
      
      function out = loglog(varargin)
        args = demote_strings(varargin);
        out = loglog(args{:});
      end
      
      function out = semilogy(varargin)
        args = demote_strings(varargin);
        out = semilogy(args{:});
      end
      
      function out = bar(varargin)
        args = demote_strings(varargin);
        out = bar(args{:});
      end
      
      function out = barh(varargin)
        args = demote_strings(varargin);
        out = barh(args{:});
      end
      
      function varargout = hist(varargin)
        args = demote_strings(varargin);
        varargout = cell(1, nargout);
        [varargout{:}] = hist(args{:});
      end
      
      function out = stemleaf(varargin)
        args = demote_strings(varargin);
        out = stemleaf(args{:});
      end
      
      function out = stairs(varargin)
        args = demote_strings(varargin);
        out = stairs(args{:});
      end
      
      function out = stem3(varargin)
        args = demote_strings(varargin);
        out = stem3(args{:});
      end
      
      function out = scatter(varargin)
        args = demote_strings(varargin);
        out = scatter(args{:});
      end
      
      function out = stem(varargin)
        args = demote_strings(varargin);
        out = stem(args{:});
      end
      
      function out = surf(varargin)
        args = demote_strings(varargin);
        out = surf(args{:});
      end
      
      function out = title(varargin)
        args = demote_strings(varargin);
        out = title(args{:});
      end
      
      function out = legend(varargin)
        args = demote_strings(varargin);
        out = legend(args{:});
      end
      
      % ... and so on, and so on ...

    end

    %%%%% START PLANAR-CLASS BOILERPLATE CODE %%%%%
    
    % This section contains code auto-generated by Janklab's genPlanarClass.
    % Do not edit code in this section manually.
    % Do not remove the "%%%%% START/END .... %%%%%" header or footer either;
    % that will cause the code regeneration to break.
    % To update this code, re-run jl.code.genPlanarClass() on this file.
    
    methods
    
        function out = size(this)
        %SIZE Size of array.
        out = size(this.strs);
        end
        
        function out = numel(this)
        %NUMEL Number of elements in array.
        out = numel(this.strs);
        end
        
        function out = ndims(this)
        %NDIMS Number of dimensions.
        out = ndims(this.strs);
        end
        
        function out = isempty(this)
        %ISEMPTY True for empty array.
        out = isempty(this.strs);
        end
        
        function out = isscalar(this)
        %ISSCALAR True if input is scalar.
        out = isscalar(this.strs);
        end
        
        function out = isvector(this)
        %ISVECTOR True if input is a vector.
        out = isvector(this.strs);
        end
        
        function out = iscolumn(this)
        %ISCOLUMN True if input is a column vector.
        out = iscolumn(this.strs);
        end
        
        function out = isrow(this)
        %ISROW True if input is a row vector.
        out = isrow(this.strs);
        end
        
        function out = ismatrix(this)
        %ISMATRIX True if input is a matrix.
        out = ismatrix(this.strs);
        end
        
        function this = reshape(this, varargin)
        %RESHAPE Reshape array.
        this.strs = reshape(this.strs, varargin{:});
        end
        
        function this = squeeze(this, varargin)
        %SQUEEZE Remove singleton dimensions.
        this.strs = squeeze(this.strs, varargin{:});
        end
        
        function this = circshift(this, varargin)
        %CIRCSHIFT Shift positions of elements circularly.
        this.strs = circshift(this.strs, varargin{:});
        end
        
        function this = permute(this, varargin)
        %PERMUTE Permute array dimensions.
        this.strs = permute(this.strs, varargin{:});
        end
        
        function this = ipermute(this, varargin)
        %IPERMUTE Inverse permute array dimensions.
        this.strs = ipermute(this.strs, varargin{:});
        end
        
        function this = repmat(this, varargin)
        %REPMAT Replicate and tile array.
        this.strs = repmat(this.strs, varargin{:});
        end
        
        function this = ctranspose(this, varargin)
        %CTRANSPOSE Complex conjugate transpose.
        this.strs = ctranspose(this.strs, varargin{:});
        end
        
        function this = transpose(this, varargin)
        %TRANSPOSE Transpose vector or matrix.
        this.strs = transpose(this.strs, varargin{:});
        end
        
        function [this, nshifts] = shiftdim(this, n)
        %SHIFTDIM Shift dimensions.
        if nargin > 1
            this.strs = shiftdim(this.strs, n);
        else
            [this.strs,nshifts] = shiftdim(this.strs);
        end
        end
        
        function out = cat(dim, varargin)
        %CAT Concatenate arrays.
        args = varargin;
        for i = 1:numel(args)
            if ~isa(args{i}, 'string')
                args{i} = string(args{i});
            end
        end
        out = args{1};
        fieldArgs = cellfun(@(obj) obj.strs, args, 'UniformOutput', false);
        out.strs = cat(dim, fieldArgs{:});
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
    
    end
    
    methods (Access=private)
    
        function this = subsasgnParensPlanar(this, s, rhs)
        %SUBSASGNPARENSPLANAR ()-assignment for planar object
        if ~isa(rhs, 'string')
            rhs = string(rhs);
        end
        this.strs(s.subs{:}) = rhs.strs;
        end
        
        function out = subsrefParensPlanar(this, s)
        %SUBSREFPARENSPLANAR ()-indexing for planar object
        out = this;
        out.strs = this.strs(s.subs{:});
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
    
    methods (Static)
      function out = decode(bytes, charsetName)
        %DECODE Decode encoded text from bytes into a string object
        %
        % See also: STRING.ENCODE
        out = string(char(javaObject('java.lang.String', bytes, charsetName)));
      end
    end

end

function out = size2str(sz)
%SIZE2STR Format an array size for display
%
% out = size2str(sz)
%
% Sz is an array of dimension sizes, in the format returned by SIZE.
%
% Examples:
%
% size2str(magic(3))

strs = cell(size(sz));
for i = 1:numel(sz)
	strs{i} = sprintf('%d', sz(i));
end

out = strjoin(strs, '-by-');
end

function varargout = scalarexpand(varargin)
%SCALAREXPAND Expand scalar inputs to be same size as nonscalar inputs

sz = [];

for i = 1:nargin
	if ~isscalar(varargin{i})
		sz_i = size(varargin{i});
		if isempty(sz)
			sz = sz_i;
		else
			if ~isequal(sz, sz_i)
				error('jl:InconsistentDimensions', 'Matrix dimensions must agree (%s vs %s)',...
					size2str(sz), size2str(sz_i))
			end
		end
	end
end

varargout = varargin;

if isempty(sz)
	return
end

for i = 1:nargin
	if isscalar(varargin{i})
    varargout{i} = repmat(varargin{i}, sz);
	end
end

end

function out = demote_strings(args)
  %DEMOTE_STRINGS Turn all string arguments into chars
  out = args;
  for i = 1:numel(args)
    if isa(args{i}, 'string')
      out{i} = char(args{i});
    end
  end
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



