classdef ExcelProcess < handle
    %EXCELPROCESS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        m_TimeRange = [];
        m_HeartRateRange = [];
        m_PhaseRange = [];
        
    end
    
    methods
        function [epobj] = ExcelProcess()
            
        end
        
        function [fullpath] = loadExcelFile(epobj,timerange,hrrange,phaserange,PathName)
            
            fls = ls(strcat(PathName,'A*.xlsx'));
            if(length(fls)==0)
                return;
            end
            
            % load the excel file
            fullpath = strcat(PathName,fls(1,:));
            
            % read time
            [~,timetext,~] = xlsread(fullpath,timerange);
            timetextconverted = char(timetext);
            ntime = size(timetextconverted,1);
            epobj.m_TimeRange = zeros(ntime,1);
            for i=1:1:size(timetextconverted,1)
                P = sscanf(timetextconverted(i,:),'%d:%d:%d');
                epobj.m_TimeRange(i) = P(1)*3600 + P(2)*60 + P(3);
            end
            
            epobj.m_HeartRateRange = xlsread(fullpath,hrrange);
            epobj.m_PhaseRange = xlsread(fullpath,phaserange);
            
        end
        
        function [timevalue,hrvalue,phasevalue] = getData(epobj,currentpos,halfwidth)
            
            nPoints = size(epobj.m_TimeRange,1);
            
            if((currentpos<epobj.m_TimeRange(1))||(currentpos>epobj.m_TimeRange(end)))
                timevalue = 'Out of Range';
                hrvalue = 'Out of Range';
                phasevalue = 'Out of Range';
                return;
            end
            
            % find corresponding values from excel file
            diffdata = abs(epobj.m_TimeRange-currentpos);
            [~,idx] = min(diffdata);
            
            
            % return five values, center is the one we want, and two before
            % and two after
            if((idx<3)||(idx>nPoints-2))
                timevalue = strcat({' - , - <<< '},num2str(epobj.m_TimeRange(idx)),' >>> - ',' - ');
                hrvalue = strcat({' - , - <<< '},num2str(epobj.m_HeartRateRange(idx)),' >>> - ',' - ');
            else
                m2 = num2str(epobj.m_TimeRange(idx-2));
                m1 = num2str(epobj.m_TimeRange(idx-1));
                cen = num2str(epobj.m_TimeRange(idx));
                p1 = num2str(epobj.m_TimeRange(idx+1));
                p2 = num2str(epobj.m_TimeRange(idx+2));
                timevalue = strcat(m2,' , ',m1,{' , << '},cen,{' >> , '},p1,' , ',p2);
                
                m2 = num2str(epobj.m_HeartRateRange(idx-2)/60);
                m1 = num2str(epobj.m_HeartRateRange(idx-1)/60);
                cen = num2str(epobj.m_HeartRateRange(idx)/60);
                p1 = num2str(epobj.m_HeartRateRange(idx+1)/60);
                p2 = num2str(epobj.m_HeartRateRange(idx+2)/60);
                hrvalue = strcat(m2,' , ',m1,{' , << '},cen,{' >> , '},p1,' , ',p2);
            end
            
            
            % find phase range
            indexstart = currentpos-halfwidth;
            indexstop = currentpos + halfwidth + 1;
            if((indexstart<epobj.m_TimeRange(1))||(indexstop>epobj.m_TimeRange(end)))
               phasevalue = 'Out of Range';
               return;
            end
            
            diffdata = abs(epobj.m_TimeRange-indexstart);
            [~,startidx] = min(diffdata);
            diffdata = abs(epobj.m_TimeRange-indexstop);
            [~,stopidx] = min(diffdata);
            phasestart = epobj.m_PhaseRange(startidx);
            phasestop = epobj.m_PhaseRange(stopidx);
            phasevalue = strcat(num2str(phasestart),{' to '},num2str(phasestop));
            
            
            
        end
        
        
    end
end

