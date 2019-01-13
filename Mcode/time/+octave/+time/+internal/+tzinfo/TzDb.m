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
  end
  
  methods (Access = private)
    function out = readZoneTab(this)
      %READZONETAB Actually read and parse the zonetab file
      
      % Use the "deprecated" plain zone.tab because zone1970.tab is not present
      % on all systems.
      zoneTabFile = [this.path '/zone.tab'];
      
      [fid,msg] = fopen(zoneTabFile, 'r');
      if fid == -1
        error('Could not open tzinfo zone.tab file at %s: %s', zoneTabFile, msg);
      end
      
      cleanup.fid = onCleanup(@() fclose(fid));
      txt = char(fread(fid, Inf, 'char'));
      txt = txt';
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
