classdef TzDb
  %TZDB Interface to the tzinfo database
  %
  % This class is an interface to the tzinfo database (AKA the Olson database)
  
  properties
    % Path to the zoneinfo directory
    path
  end
  
  methods
    function this = TzDb(path)
      %TZDB Construct a new TzDb object
      %
      % this = TzDb(path)
      %
      % path (char) is the path to the tzinfo database directory. If omitted or
      % empty, it defaults to the default path ('/usr/share/zoneinfo' on Unix,
      % and an error on Windows).
      if nargin < 1;  path = [];  end
      if isempty(path)
        this.path = octave.time.internal.tzinfo.TzDb.defaultPath;
      else
        this.path = path;
      end
    end
        
    function out = zoneTab(this)
      %ZONETAB Get the zone definition table
      %
      % This lists
      %
      % Returns a struct with fields:
      %   CountryCode
      %   Coordinates
      %   TZ
      %   Comments
      % Each of which contains a cellstr column vector.
      
      persistent data
      if isempty(data)
        data = this.readZoneTab();
      end
      out = data;
    end
    
    function out = definedZones(this)
      %DEFINEDZONES List defined zone IDs
      tab = this.zoneTab;
      out = tab.TZ;
    end
    
    function out = zoneDefinition(this, zoneId)
      out = this.readZoneFile(zoneId);
    end
  end
  
  methods (Access = private)
    function out = readZoneTab(this)
      %READZONETAB Actually read and parse the zonetab file
      
      % Use the "deprecated" plain zone.tab because zone1970.tab is not present
      % on all systems.
      zoneTabFile = [this.path '/zone.tab'];
      
      txt = slurpTextFile(zoneTabFile);
      lines = strsplit(txt, sprintf('\n'));
      starts = regexp(lines, '^\s*#|^\s*$', 'start', 'once');
      tfComment = ~cellfun('isempty', starts);
      lines(tfComment) = [];
      tfBlank = cellfun('isempty', lines);
      lines(tfBlank) = [];
      pattern = '^(\w+)\s+(\S+)\s+(\S+)\s*(.*)';
      [match,tok] = regexp(lines, pattern, 'match', 'tokens');
      tfMatch = ~cellfun('isempty', match);
      if ~all(tfMatch)
        ixBad = find(~tfMatch);
        error('Failed parsing line in zone.tab file: "%s"', lines{ixBad(1)});
      end
      tok = cat(1, tok{:});
      tok = cat(1, tok{:});
      
      out = struct;
      out.CountryCode = tok(:,1);
      out.Coordinates = tok(:,2);
      out.TZ = tok(:,3);
      out.Comments = tok(:,4);
    end
    
    function out = readZoneFile(this, zoneId)
      %READZONEFILE Read and parse a zone definition file
      if ~ismember(zoneId, this.definedZones)
        error('Undefined time zone: %s', zoneId);
      end
      zoneFile = [this.path '/' zoneId];
      if ~exist(zoneFile)
        error(['tzinfo time zone file for zone %s does not exist: %s\n' ...
          'This is probably an error in the tzinfo database files.'], ...
            zoneId, zoneFile);
      end
      data = slurpBinaryFile(zoneFile);
      
      % Parse tzinfo format file
      %magic = data(1:4);
      %magic_char = char(magic);
      %format_id_byte = data(5);
      %format_id = char(format_id_byte);
      %reserved = data(6:20);
      %ix = 21;
      ix = 1;
      [section1, n_bytes_read] = this.parseZoneSection(data(ix:end), 1);
      out.section1 = section1;
      
      % Version 2 stuff
      if ismember(section1.header.format_id, {'2','3'})
        % A whole nother header/data, except using 8-byte transition/leap times
        ix = ix + n_bytes_read;
        % Now, this next section is supposed to follow immediately. But in my
        % tzinfo files on macOS, there's a textual time zone following the first
        % section (e.g. 'EWT','EPT', and some nulls). So either I'm misreading the
        % tzfile spec and parsing it wrong, or there's some extension there, or something.
        % So, scan for the magic cookie to determine where to continue parsing.
        magic_ixs = strfind(char(data(ix:end)), 'TZif');
        if isempty(magic_ixs)
          % No second section found
        else
          % Advance to where we found the magic cookie
          ix = ix + magic_ixs(1) - 1;
          [out.section2, n_bytes_read_2] = this.parseZoneSection(data(ix:end), 2);
          ix = ix + n_bytes_read_2;
          % And then there's the going-forward zone. Again, there's some leftover
          % data at the end of my parsing, so scan for LFs, which delimit it.
          data_left = data(ix:end);
          ixLF = find(data_left == uint8(sprintf('\n')));
          if numel(ixLF) >= 2
            out.goingForwardPosixZone = char(data_left(ixLF(1)+1:ixLF(2)-1));
          end
        end
      end
    end

    function [out, nBytesRead] = parseZoneSection(this, data, sectionFormat)
      function out = getint(my_bytes)
        out = swapbytes(typecast(my_bytes, 'int32'));
      end
      function out = getint64(my_bytes)
        out = swapbytes(typecast(my_bytes, 'int64'));
      end
      ix = 1; % "cursor" index pointing to current point of parsing
      function out = take_byte(n)
        if nargin < 1; n = 1; end
        out = data(ix:ix+n-1);
        ix = ix + n;
      end
      function out = take_int(n)
        if nargin < 1; n = 1; end
        out = getint(data(ix:ix+(4*n)-1));
        ix = ix + 4*n;
      end
      function out = take_int64(n)
        if nargin < 1; n = 1; end
        out = getint64(data(ix:ix+(8*n)-1));
        ix = ix + 8*n;
      end

      % Header
      h.magic = data(ix:ix+4-1);
      h.magic_char = char(h.magic);
      ix = ix + 4;
      format_id_byte = take_byte;
      h.format_id = char(format_id_byte);
      h.reserved = data(ix:ix+15-1);
      ix = ix + 15;
      h.counts_vals = take_int(6);
      counts_vals = h.counts_vals;
      h.n_ttisgmt = counts_vals(1);
      h.n_ttisstd = counts_vals(2);
      h.n_leap = counts_vals(3);
      h.n_time = counts_vals(4);
      h.n_type = counts_vals(5);
      h.n_char = counts_vals(6);
      
      % Body
      function out = take_timeval(n)
        if sectionFormat == 1
          out = take_int(n);
        else
          out = take_int64(n);
        end
      end
      transitions = take_timeval(h.n_time);
      time_types = take_byte(h.n_time);
      ttinfos = struct('gmtoff',int32([]), 'isdst',uint8([]), 'abbrind',uint8([]));
      function out = take_ttinfo()
        view = data(ix:ix+6-1);
        ttinfos.gmtoff(end+1) = getint(view(1:4));
        ttinfos.isdst(end+1) = view(5);
        ttinfos.abbrind(end+1) = view(6);
        ix = ix + 6;
      end
      for i = 1:h.n_type
        take_ttinfo;
      end
      if sectionFormat == 1
        leap_times = repmat(uint32(0), [h.n_leap 1]);
      else
        leap_times = repmat(uint64(0), [h.n_leap 1]);
      end
      leap_second_totals = repmat(uint32(0), [h.n_leap 1]);
      for i = 1:h.n_leap
        leap_times(i) = take_timeval(1);
        leap_second_totals(i) = take_int(1);
      end
      is_std = take_byte(h.n_ttisstd);
      is_gmt = take_byte(h.n_ttisgmt);

      out.header = h;
      out.transitions = transitions;
      out.time_types = time_types;
      out.ttinfos = ttinfos;
      out.leap_times = leap_times;
      out.leap_second_totals = leap_second_totals;
      out.is_std = is_std;
      out.is_gmt = is_gmt;      
      nBytesRead = ix - 1;
    end
  end

  
  methods (Static)
    function out = defaultPath()
      if ispc
        error('No default path to the tzinfo database is available on Windows');
      else
        out = '/usr/share/zoneinfo';
      end
    end
  end
end

function out = slurpTextFile(file)
  [fid,msg] = fopen(file, 'r');
  if fid == -1
    error('Could not open file %s: %s', file, msg);
  end
  cleanup.fid = onCleanup(@() fclose(fid));
  txt = fread(fid, Inf, 'char=>char');
  txt = txt';
  out = txt;
end

function out = slurpBinaryFile(file)
  [fid,msg] = fopen(file, 'r');
  if fid == -1
    error('Could not open file %s: %s', file, msg);
  end
  cleanup.fid = onCleanup(@() fclose(fid));
  out = fread(fid, Inf, 'uint8=>uint8');
  out = out';  
end
