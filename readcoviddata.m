function covid = readcoviddata(filename)

fid = fopen(filename);
fgetl(fid); %ignore header line


%reading each line in file
i = 0;
while ~feof(fid)
    i = i + 1;
    line = fgetl(fid);
    line = strsplit(line,',');
    
    %correcting for S Korea
    line{1} = line{1}(2:end-1);
    if strcmpi(line{1},'"Korea')
        line{1} = 'South Korea';
    end
    
    covid.country{i} = line{1};
    if length(line) == 8
        o = 0;
        covid.state{i} = 'n/a';
    elseif length(line) == 9
        covid.state{i} = line{2};
        o = 1;
    end
    covid.datestr{i} = line{2+o};
    covid.type{i} = line{3+o};
    covid.numcases(i) = str2double(line{4+o});
    covid.datenum(i) = datenum(covid.datestr{i},'yyyy-mm-dd');
end