%LOADPCD Load a point cloud from a PCD format file
%
% P = LOADPCD(FNAME) is a set of points loaded from the PCD format
% file FNAME.  
%
% For an unorganized point cloud the columns of P represent the 3D points,
% and the rows are: x, y, z, r, g, b, a depending on the FIELDS in the file.
%
% For an organized point cloud P is a 3-dimensional matrix (HxWxN) where the
% N planes are: x, y, z, r, g, b, a depending on the FIELDS in the file.  This
% format is useful since the planes z, r, g, b, a can be considered as images.
%
% Notes::
% - Only the x y z field format are currently supported
% - The file can be in ascii or binary format, binary_compressed is not
%   supported
%
% See also pclviewer, lspcd, loadpcd.
%
% Copyright (C) 2013, by Peter I. Corke

% TODO
% - handle binary_compressed


function out = loadpcd_auto(fname)

    verbose = true;
    
    fp = fopen(fname, 'r');
    
    
    while true
        line = fgetl(fp);
        
        if line(1) == '#'
            continue;
        end
        
        [field,remain] = strtok(line, ' \t');
        remain = strtrim(remain);
        
        switch field
            case 'VERSION'
                continue;
            case 'FIELDS'
                FIELDS = remain;
            case 'TYPE'
                TYPE = remain;
            case 'SIZE'
                sizes = str2num(remain);
            case 'WIDTH'
                width = str2num(remain);
            case 'HEIGHT'
                height = str2num(remain);
            case 'POINTS'
                npoints = str2num(remain);
            case 'COUNT'
                count = str2num(remain);
            case 'VIEWPOINT'
                viewpoint = str2num(remain);
            case 'DATA'
                mode = remain;
                break;
            otherwise
                warning('unknown field %s\n', field);
        end
    end
    
    % parse out details of the fields
    %  numFields    the number of fields
    %  sizes        vector of field sizes (in bytes)
    %  types        vector of type identifiers (I U F)
    %  fields       vector of field names (x y z rgb rgba etc)
    numFields = numel(sizes);
    types = cell2mat(regexp(TYPE,'\s+','split'));
    fields = regexp(FIELDS,'\s+','split');
    
    if verbose
        % the doco says height > 1 means organized, but some old files have
        % height = 1 and width > 1
        if height > 1 && width > 1
            organized = true;
            org = 'organized';
        else
            organized = false;
            org = 'unorganized';
        end
        fprintf('%s: %s, %s, <%s> %dx%d\n', ...
            fname, mode, org, FIELDS, width, height);
        fprintf('  %s; %s\n', TYPE, num2str(sizes));
    end   
    
    switch mode
        case 'ascii'
            if any(count > 1)
                error('can only handle 1 element per dimension');
            end
    
            format = '';
            for j=1:numFields
                switch types(j)
                    case 'I', typ = 'd';
                    case 'U', typ = 'u';
                    case 'F', typ = 'f';
                end
                format = [format '%' typ num2str(sizes(j)*8)];
            end
            c = textscan(fp, format, npoints);            
            out = [];             
            for j=1:length(c)
                if size(c{j},1) ~= npoints
                    error('incorrect number of points in file: was %d, should be %d', ...
                    size(c{j},1), npoints);
                end
                out.(fields{j}) = double(c{j});
            end
            
        case 'binary'
            format = '';

            if all(types == types(1)) && all(sizes == sizes(1))
                % simple case where all fields have the same length and type
                if any(count > 1)
                    error('can only handle 1 element per dimension');
                end                            
                
                % map IUF -> int, uint, float
                switch types(1)
                    case 'I'
                        fmt = 'int';
                    case 'U'
                        fmt = 'uint';
                    case 'F'
                        fmt = 'float';
                end
                
                format = [format '*' fmt num2str(sizes(1)*8)];
                points = fread(fp, [numFields npoints], format);
                
                out = [];             
                for j=1:size(points, 1)
                    out.(fields{j}) = points(j, :)';
                end                
                
            else
                
                % more complex case where fields have different length and type
                % code contributed by Will
                
                startPos_fp = ftell(fp);
                stride = sum(sizes.*count);
                
                % Just initialize the xyz portion for now
                points = zeros(length(sizes), npoints);
                
                for i=1:numFields
                    % map each field sequentially, using fread() skip functionality,
                    % essentially interleaved reading of the file
                    
                    % map IUF -> int, uint, float
                    switch types(i)
                        case 'I'
                            fmt = 'int';
                        case 'U'
                            fmt = 'uint';
                        case 'F'
                            fmt = 'float';
                    end
                    
                    format = ['*' fmt num2str(sizes(i)*8)];
                    fseek(fp, startPos_fp + sum(sizes(1:i-1).*count(1:i-1)), 'bof');
                    
                    if (fields{i} ~= '_')
                        data = fread(fp, [1 npoints], format, stride-sizes(i));
                    
                        out.(fields{i}) = double(data)';                                        
                    end
                    
                    %switch fields{i}
                    %    case 'x'
                    %        points(1,:) = data;
                    %    case 'y'
                    %        points(2,:) = data;
                    %    case 'z'
                    %        points(3,:) = data;
                    %    case {'rgb', 'rgba'}
                    %        points(4,:) = data;
                    %    case {'normal_x'}
                    %        points(4,:) = data;
                    %    case {'normal_y'}
                    %        points(5,:) = data;
                    %    case {'normal_z'}
                    %        points(6,:) = data;                            
                    %end
                end
                
            end
            
        case 'binary_compressed'
            % binary part of the file contains:
            %  compressed size of data (uint32)
            %  uncompressed size of data (uint32)
            %  compressed data
            %  junk
            compressed_size = fread(fp, 1, 'uint32');
            uncompressed_size = fread(fp, 1, 'uint32');
            compressed_data = fread(fp, compressed_size, 'uint8')';

            uncompressed_data = lzfd(compressed_data);
            if length(uncompressed_data) ~= uncompressed_size
                error('decompression error');
            end
            
            % the data is stored unpacked, that is one field for all points,
            % then the next field for all points, etc.
            
            start = 1;
            for i=1:numFields
                len = sizes(i)*npoints;
                switch types(1)
                    case 'I'
                        fmt = 'int32';
                    case 'U'
                        fmt = 'uint32';
                    case 'F'
                        fmt = 'single';
                end
                field = typecast(uncompressed_data(start:start+len-1), fmt);
                start = start + len;
                
                out.(fields{i}) = field; 
            end           
            
        otherwise
            error('unknown DATA mode: %s', mode);
    end   
               
    fclose(fp);
