%% Initialization

%close all;
%clear all;
clc;
clear;
close all;
havestABP = 1;
havestPPG = 0;

nFeatures = 25 + 2;
fObj = SigCycleToFeatureSet();
%DEBUG = true;
DEBUG = 0;

%% Load Individual record
datapath = 'C:\Users\jugao\Documents\bloodpressureestimationml\DataFiles\CyclesExtraction\PyrAmes CycleDB';
programPath = 'C:\Users\jugao\Documents\bloodpressureestimationml';
%cd('C:\Users\gaoj\Box Sync\GCS Technologies\Documents\My Matlab code\BPEstimation\ppg_ABP_Cycle_Extraction\RecordsDB');
cd(datapath);
[fn,pn] = uigetfile({'*.mat',' Select the PPG-ABP Record file'}, ...
    'Pick multiple MAT files (Select "Cancle" to quit program)', ...
    'MultiSelect', 'on');
if(~iscell(fn))
    fn = {fn};
    pn = {pn};
end

if isequal(cell2mat(fn),0)
    disp('User selected Cancel');
    return;
else
    fname = fullfile(pn, fn);
    fname = {fname};
    nMatRec = size(fname{1}, 2);
    fprintf('User selected %d MAT files : The First one is ... ...\n ==> "%s"\n', nMatRec, cell2mat(fname{1,1}(1)));
end


progressbar(['Number of Record is ', num2str(nMatRec)]);
h = gcf;
set(h, 'position',        [0.6 0.05 0.24 0.0296]);
pause(2);

for iRec = 1:nMatRec
    progressbar(iRec/nMatRec);
    if (iscell(fname))
        load(fname{1}{iRec});
    else
        load(fname);
    end
    % Code added to pass through samplingFrequency from
    % Class CyclesExtraction() to Class SigCycleToFeatureSet()
    if(isfield(res, 'samplingFrequency'))
        fObj.m_SamplingFrequency = res.samplingFrequency;
    else
        fObj.m_SamplingFrequency = 125;
    end
    
    %fprintf(' ===> Record Name = %d, out of %d records.\n', iRec, nMatRec);
    numCycle = length(res);
    
    if(numCycle == 1 && isempty(res.ppgCycle))  % the res only has one record and  empty ppg
        continue;
    end
    
    %featureSet = [];
    %% featureSet : Jun Gao added abp feature set on May 29, 2017
    %ppgfeatureSet = zeros(nFeatures, numCycle);
    %abpfeatureSet = zeros(nFeatures, numCycle);
    ppgSet = struct('ppg', []);
    abpSet = struct('abp', []);
    %%
    nPass = 0;
    nFailed = 0;
    
    %% Extract featureSet from one Record
    progressbar(['Number of Cycles is ', num2str(numCycle)]);
    pause(1);
    try
        for iI = 1:numCycle
            progressbar(iI/numCycle);
            ppg = res(iI).ppgCycle;
            abp = res(iI).abpCycle; 
            if(isempty(abp) || isempty(ppg))
                continue;
            end
            abpSBP = res(iI).abpSBP;
            abpDBP = res(iI).abpDBP;

            %% extract features from either ppg cycle (havestPPG) or both (havestABP)
            DEBUG = 0;
            [ppg, featP, passP] = featuresFromCycle(fObj, ppg, DEBUG);
            %% add one more qualification that rule out some of the wired multipeak ppgs
            if(passP)
                [pks, loc, w, p] = findpeaks(ppg, 'MinPeakDistance',6, 'MinPeakHeight',0.1, 'MinPeakWidth', 3);
                if(length(pks)>1)
                    passP = 0;
                end
            end
            [abp, featA, passA] = featuresFromABPCycle(fObj, abp, DEBUG);
%             if(abp(1) > 20)
%                 keyboard;
%             end
            %% add one more qualification that rule out some of the wired multipeak ppgs
            if(passA)
                [pks, loc, w, p] = findpeaks(abp, 'MinPeakDistance',6, 'MinPeakHeight',0.1, 'MinPeakWidth', 3);
                if(length(pks)>1)
                    passA = 0;
                end
            end
                       
            %% Only extract features from abp cycles if both ppg and abp cycles passes the Gaussian Model qualification
            if(havestABP)
                qualified = passA && passP;
                feat = featA;
            else
                qualified = passP;
                feat = featP;
            end
            
            
            if(qualified == 1)
                DEBUG = 1;
                if(DEBUG)
                    plotCycle(ppg, abp, abs(res(iI).offset), 20001);
                end
                %    featureSet = [featureSet feat];
                %fprintf('---> Passed at %d. \n',  iI);
                nPass = nPass + 1;
                feat = [feat; abpSBP; abpDBP]; %#ok<AGROW>
                featureSet(:,nPass) = feat;
                ppgSet(nPass).ppg = ppg;
                DEBUG = 0;
            else
                %fprintf('\n***< Failed at %d. The failed code is %d.\n\n',  iI, pass);
                nFailed = nFailed + 1;
                %            featureSet(:,iI) = [];
            end
            
%             if(DEBUG)
%                 if(qualified == 1)
%                     figure(gcf); %set(gcf, 'position', [220    65   750   930]);
%                     xlabel(['Record Number is ', num2str(iI), '. Numbers of qualified Records = ', ...
%                         num2str(nPass), '.']);
%                 else
%                     figure(gcf);  %set(gcf, 'position', [1050     70         750         930]);
%                     xlabel(['Record Number is ', num2str(iI), '. Numbers of disqualified Records = ', ...
%                         num2str(nFailed), ]);
%                 end
%                 ylabel(fn{iRec}, 'interpreter', 'none');
%             end
        end
    catch ME
        warning('Problem ocuring during execution. Saving whatever is done so far');
        fprintf('iRec =  %d. \t, NumCycle=  %d. \t Rec Name is %s.\n', iRec, iI, fn{iRec}(1:end-4));
        if(nPass > 0)
            featureSet = featureSet(:, 1:nPass);
            fObj.addFeatureSetToCollection(iRec, featureSet, fn{iRec}(4:end-4));
        end
        disp(ME);
        fprintf('===========  stack ==============\n');
        for m = 1:length(ME.stack)
            disp(ME.stack(m));
        end
        fprintf('=========== failed for the above reson ====\n\n\n');
    end
    
    if(nPass > 0)
        featureSet = featureSet(:, 1:nPass);
        ppgSet = ppgSet(:, 1:nPass);
        fObj.addFeatureSetToCollection(iRec, featureSet, ppgSet',  fn{iRec}(4:end-4));
    end
    fnm = fname{1}{iRec};
    fprintf('\t%s,  nPass = %d, out of %d number of Cycles, Passrate = %2.2f.\n\n',fnm(end-10:end), nPass, numCycle, nPass/numCycle);
end


%% Ssave featureSet.mat fObj.obj.m_featureSetCollection;
cd('C:\Users\jugao\Documents\bloodpressureestimationml\DataFiles\CyclesExtraction\PyrAmes CycleDB\FeatureDB');
save WaveParameterObj.mat fObj;
FSet = [];
numSubject = size(fObj.m_featureSetCollection, 2);
for jJ =  1:numSubject
    fSet = fObj.m_featureSetCollection(jJ).FeatureSet;
    FSet = [FSet fSet];
end
if(~isempty(FSet))
    if(~exist('featureSet.mat', 'file'))
        save('featureSet.mat', 'FSet');
    else
        save('featureSet.mat', 'FSet', '-append');
    end
end
h = msgbox('Operation Completed', 'Success');

