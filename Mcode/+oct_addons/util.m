classdef util
  %UTIL Utility functions for Octave Addons
  
  methods (Static)
    
    function out = format_dispstr_array(strs)
      lines = {};
      col_lens = max(cellfun(@numel, strs));
      col_fmts = cell(1, numel(col_lens));
      for i = 1:numel(col_lens)
        col_fmts{i} = ['%-' num2str(col_lens(i)) 's'];
      end
      fmt = ['  ' strjoin(col_fmts, '   ')];
      for i = 1:size(strs, 1)
        lines{i} = sprintf(fmt, strs{i,:});
      end
      out = [strjoin(lines, sprintf('\n')) sprintf('\n')];
    end

  end

end
