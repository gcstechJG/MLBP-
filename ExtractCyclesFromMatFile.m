clear;
clc
% close all
fc = [];
PyrAmes = 1;
DBG = 0;


%% Instantiate CyclesExtraction class
obj = CyclesExtraction();

%% ABP cycle relative to PPG cycle: -1: ABP starts ahead of PPG cycle and finish within PPG Cycle
%                                                         0: ABP cycle starts within PPG Cycle and finish after PPG cycle
% Should be defined inside the CyclesExtraction class                        
relativeABPtoPPGPos = 0; 

%% Define some peak finding parameters that are related to physiological response of the blood pressure
% Ideally these paramenters should be the private member (private properties of CyclesExtraction Class) 
MIN_SBP = 80;           % minimum SBP is defined as 80 mmHg
MAX_DBP = 150;        % maximum SBP is defined as 150 mmHg
MIN_HR = 30;              % minimum heart rate we are tracking is 30 BPM
MIN_HR_IN_SAMPLES = floor((MIN_HR/60) * obj.m_samplingFrequency); % MIN_PEAK_DISTANCE is a samplingFrequency related number 
                                                                                                      % and need to be updated after the SignalPreparation is called.

%% Load Record Cluster File and all its Records
% (1) find the Record Cluster file
currentpath = pwd;
cd('C:\Users\jugao\Documents\GCSTechnologies\MyMatlabCode\ANN_Mimic2DataSet_ANNTraining');
[fn,pn] = uigetfile({'*.mat',' Select the Record Cluster file'}, ...
   'Pick files (Select "Cancle" to quit program)', ...
   'MultiSelect', 'off');
if(~iscell(fn))
    fn = {fn};
    pn = {pn};
end
% pn = 'C:\Users\jugao\Documents\GCSTechnologies\MyMatlabCode\BPEstimation\nnTestingGround\Res571';
% fn = 'fstestset.mat';
cd(currentpath);

fname = fullfile(pn, fn);
if isequal(fn,0)
    disp('User selected Cancel');
    return;
else
    disp(['User selected :', fname])
end

% (2) Set Record Cluster File
obj.SetClusterFileName(fname);
% (3) Find out number of Records and all the Record Names and update the sigObj class
myList = obj.GetRecList;
NoiseFloor = obj.getNoiseFloor(10); % Get 10 bit ADC noise floor, which is 0.0049
% Load each Record at a time and extrext Cycles from it
numRec = obj. m_NumRecords;
progressbar(['Number of Records are ', num2str(numRec)]);
h = gcf;
%set(h, 'HandleVisibility', 'Off');
set(h, 'position',        [0.6 0.05 0.24 0.0296]);
pause(2);

if(DBG)
    obj.DEBUG = 1;
else
    obj.DEBUG = 0;
end

for ii = 1:numRec
    progressbar(ii/numRec);
            % (4) Actually load the Record and prepare the signals for processing
            fprintf('Loading and Extracting record %s.\n', obj.m_RecNameList(ii).name);
            obj.SignalPreparation(ii);
            % Update MIN_PEAK_DISTANCE after the record is loaded and the
            % sampleingFrequency is known
            MIN_HR_IN_SAMPLES = floor((MIN_HR/60) * obj.m_samplingFrequency);
            
            
            if(obj.m_ppgSignal == -1)
                disp('NoValidData, Try next Record');
                continue;
            end

            [ppgCycles, ~, ~, ppgValleyIdx, ~] = obj.extractCycle(obj.m_ppgSignal, obj.m_samplingFrequency, 'FOOT', 'off', []);
            if(isempty(ppgCycles))
                continue;
            end
            %pause(0.2);
            %sigObj

            %% The following code will eventually be part of the CycleExtraction class function after debugging
            % This section is redundant
            numppgCycles = size(ppgCycles, 2);
            ppgCsize = zeros(numppgCycles,1);
            for ppgValleyNum = 1:numppgCycles
                ppgCsize(ppgValleyNum) = size(ppgCycles{ppgValleyNum}, 1);
            end
            %end of redundant section
            %% abp signal should be synced with the ppgCycles
            %[abpCycles, abpPeakIdx, sbp, abpValleyIdx, dbp ]=extractCycle(abpSection, 125, 'FOOT', 'on', 0.1);
            [sbp, abpPeakIdx] = findpeaks(obj.m_abpSignal, 'MinPeakHeight', MIN_SBP, 'MinPeakDistance', MIN_HR_IN_SAMPLES);
            [ndbp, abpValleyIdx] = findpeaks(-obj.m_abpSignal,  'MinPeakHeight', -MAX_DBP, 'MinPeakDistance', MIN_HR_IN_SAMPLES);
            dbp = -ndbp;


            %% Extract valid ppg/abp pairs.
            % The PPG signal is defined between valley; the abp pairs are Peak/Valley
            % that fit into a ppg Valley interval, with abp valley (dbp) always ahead of abp
            % peak (sbp). Reject any ppg cycles has more or less than one abp valley
            % and abp valley

            %numPPGcycles = length(ppgValleyIdx) - 1;
            numPPGcycles = length(ppgCycles);
            numValidCycle = 0;
            
            for ppgValleyNum = 2:numPPGcycles
                %% Pruming the PPG Cycles off empty ones and the cycles with signal range < noise floor for 10 bit ADC
                 
                 %% No point of computeing the abp valley if the ppg cycle is null
                if(isempty(ppgCycles{ppgValleyNum-1}))      
                    continue;
                end
                
                %% If the signal range of the ppgCycle is so small that it
                % is less than the 10 bit ADC LSB, it is probably noise
                % anyway
                ppgSignalRange = max(ppgCycles{ppgValleyNum-1}) - min(ppgCycles{ppgValleyNum-1});
                if(ppgSignalRange < NoiseFloor)
                    continue;
                end
                
                %% Some sanity checks TBDebug drifiting between PPG and ABP index
                abpValleyInRangeIdx = find((abpValleyIdx > ppgValleyIdx(ppgValleyNum-1)) & ...
                    (abpValleyIdx < ppgValleyIdx(ppgValleyNum))) ;                       % abpValleyIdx in the range of [ppgValleyNo-1 : ppgValleyNo]
                abpPeakInRangeIdx = find((abpPeakIdx > ppgValleyIdx(ppgValleyNum-1)) & ...
                    (abpPeakIdx < ppgValleyIdx(ppgValleyNum)));                          % abpPeakIdx in the range of [ppgValleyNo-1 : ppgValleyNo]
                
                %% make sure there is only one ABP valley, one ABP peak within the PPG
                % cycle and that the ABP valley is ahead of ABP peak
                if(size(abpValleyInRangeIdx, 1) ~= 1 || size(abpPeakInRangeIdx, 1) ~= 1 ...      % condition 1: only one abp Valley and one Peak in the range [No-1 : No]
                        || abpValleyIdx(abpValleyInRangeIdx) >= abpPeakIdx(abpPeakInRangeIdx)) % condition 2: abp Valley ahead of abp Peak
                    continue;       % if the above two conditions are not meet, discard this ppg cycle  and looking for next ppg cycle
                end
                
                %% Boundary check 1: 
                % The very first valley and peak index is not used.
                if(abpValleyInRangeIdx == 1 || abpPeakInRangeIdx == 1)    %There is no abp valley (or peak) before this ppg Cycle, looking for the next ppg Cycle
                    continue;
                end

                %% Assume the abp Cycle happens before the ppg Cycle. Which means
                % the abp cycle valleys are always ahead of ppg valleys
                %%% TBD Here the check to make sure that if abp cycle are
                %%% always ahead or the same as the ppg Cycle.
                abpStartIdx = abpValleyInRangeIdx + relativeABPtoPPGPos;
                abpEndIdx = abpValleyInRangeIdx + relativeABPtoPPGPos + 1;
                
                %% Boundary check 2 (JG June 3rd 2017): Added froo RCyclees371
                %  Make sure that abpStartIdx and abpEndIdx are less than
                %  length(abpValletIdx) 
                if(abpStartIdx >= length( abpValleyIdx))
                    continue;
                end
                % CONSTRUCT the abp and ppg Cycle Indexes
                abpCycleIdx = abpValleyIdx(abpStartIdx) : abpValleyIdx(abpEndIdx);
                ppgCycleIdx = ppgValleyIdx(ppgValleyNum-1) : ppgValleyIdx(ppgValleyNum);
                
                %% This is a condition to make sure that the ABP and PPG are roughly the same length so that they are more likely corresponds to the same beat
                CycleTolerance = floor(obj.getCycleTolerance * obj.m_samplingFrequency);
                if(abs(length(abpCycleIdx) - length(ppgCycleIdx)) >= CycleTolerance)     
                    continue;
                end
                
                %% Now start extract ABP/PPG?SBP/DBP
                %if(~isempty(ppgCycles{ppgValleyNum-1}))
                    numValidCycle = numValidCycle + 1;
                    disp(ppgValleyNum-1);
                    % Case 2: ABP Cycle is within the PPG Cycle: Constructing results
                    obj.m_results(numValidCycle).offset = ppgValleyIdx(ppgValleyNum-1) - abpValleyIdx(abpValleyInRangeIdx + relativeABPtoPPGPos);
                    obj.m_results(numValidCycle).ppgCycle = ppgCycles{ppgValleyNum-1};                       %res(numValidCycle).ppgCycle = ppgCycles{ii-1};
                    obj.m_results(numValidCycle).abpCycle = obj.m_abpSignal(abpCycleIdx);    % extract the same portion of the abp signal. This might need change to the portion of abp signal that is from valley to valley, before the current PPG cycle
                    obj.m_results(numValidCycle).abpSBP = sbp(abpPeakInRangeIdx + relativeABPtoPPGPos);             % res(numValidCycle).abpSBP = sbp(abpPeakInRangeIdx-1);
                    obj.m_results(numValidCycle).abpDBP = dbp(abpValleyInRangeIdx + relativeABPtoPPGPos);      % res(numValidCycle).abpDBP = dbp(abpValleyInRangeIdx-1);
                    obj.m_results(numValidCycle).index = ppgValleyNum-1;                                               %res(numValidCycle).index = ii-1;
                    % Jun Gao: October 23, 2015
                    % add sampling frequency to the result so that the feature extraction class would be able to extract phase base on correct sampling frequency
                    obj.m_results(numValidCycle).samplingFrequency = obj.m_samplingFrequency;
                    
                    
                    ppg = ppgCycles{ppgValleyNum-1};
                    abp = obj.m_results(numValidCycle).abpCycle;
                    ptt(numValidCycle) = obj.m_results(numValidCycle).offset/obj.m_samplingFrequency;
                    
                    if(obj.DEBUG)        % sigObj.DEBUG)
                        
                        if (relativeABPtoPPGPos == -1)
                            % Case 1: plotIdx for cases where ABP cycle is ahead of PPG cycle
                            startpos = abpValleyIdx(abpValleyInRangeIdx-1);
                            endpos = ppgValleyIdx(ppgValleyNum);
                        elseif (relativeABPtoPPGPos == 0)
                            
                            % Case 2: ABP cycle is within the PPG cycle
                            startpos = ppgValleyIdx(ppgValleyNum - 1);
                            endpos = abpValleyIdx(abpValleyInRangeIdx +1);
                        end
                        
                        
                        % Case 3: general cases
                        %                         startpos = min(ppgValleyIdx(ppgValleyNum - 1), abpValleyIdx(abpValleyInRangeIdx-1));
                        %                         endpos = max(ppgValleyIdx(ppgValleyNum), abpValleyIdx(abpValleyInRangeIdx +1));
                        
                        plotIdx = [startpos endpos];
                        
                        if(isempty(fc))
                            fc = figure(randi([1000 5000], 1));
                            set(fc, 'position',[610   80   780   830]);
                        end
                        figure(fc);
                        if(PyrAmes)
                            ax(1) = subplot(211);
                        else
                            ax(1) = subplot(311);
                        end
                        plot(ppgCycleIdx, ppg),
                        grid on;  title(['Rec name: ', obj.m_recName,  '. PPG Cycle ', num2str(ppgValleyNum-1)]);
                        xlabel(['Total = ', num2str(length(ppgCycleIdx)), ' samples']);
                        xlim(plotIdx);
                        if(PyrAmes)
                            ax(2) = subplot(212);
                        else
                            ax(2) = subplot(312);
                        end
                        plot(abpCycleIdx, abp),
                        grid on;
                        title('ABP Cycle');
                        xlabel(['Rec #', num2str(ii),  ' out of ', num2str(obj.m_NumRecords), ...
                            ' records. Total = ', num2str(length(abpCycleIdx)), ' samples']);
                        xlim(plotIdx);
                        linkaxes(ax,'x');
                        if(~PyrAmes)
                            subplot(313)
                            % ptt(numValidCycle) = obj.m_results(numValidCycle).offset/obj.m_samplingFrequency;
                            plot(numValidCycle,ptt(numValidCycle), ':*'); grid on; hold on;
                            title(['PTT Calculated from PPG and ABP offset. ABP-PPG = ',  num2str(relativeABPtoPPGPos)]);
                            xlabel('abp-ppb Cycles');
                            ylabel('second');
                        end
                        drawnow;
                    end
                    %end
            end
            
            %% Output results as a column vector
            % If there are results in the obj and there are at least 2
            % good cycles
            if(~isempty(obj.m_results) & length(obj.m_results) >=2)
                res = obj.m_results;
                res = res(:);
                % setup directories if not already
                if(~exist('CyclesDB', 'dir'))
                    mkdir('CyclesDB');
                end
                if(~exist('PTTDB', 'dir'))
                    mkdir('PTTDB');
                end
                % save the results
                resFileToSave = ['CyclesDB/', obj.m_recName, '.mat'];
                pttFileToSave = ['PTTDB/ptt_', obj.getRecName, '.mat'];

                save(resFileToSave, 'res');
                save(pttFileToSave, 'obj', 'ptt');
                
            end
            
            if(obj.DEBUG)
                for i = 1:numValidCycle
                    sbpq(i) = obj.m_results(i).abpSBP;
                    dbpq(i) = obj.m_results(i).abpDBP;
                end
                recName = obj.m_RecNameList(ii).name;
                if(PyrAmes)
                     plotboth(sbpq, dbpq, 'SDB mmHg', 'DBP mmHg');
                else
                    plotmulti(3, sbpq, dbpq, ptt, 'SDB mmHg', 'DBP mmHg', 'PTT ms');
                end
                set(gcf, 'name', recName);
            end
            
            obj.ResetRecordProperties;
end