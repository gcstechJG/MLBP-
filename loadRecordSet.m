function [PhysioSetStat] = loadRecordSet()
%global mimicobj
dbstop if error;
%mimicobj = Mimic();

[FileNames,PathName,~] = uigetfile({'*.txt;*.bat'}); %PathName);
filepath = strcat(PathName,FileNames);
%PathName = 'C:\Users\gaoj\Box Sync\GCSTechnologies\Documents\MyMatlabCode\ANN_Mimic2DataSet_ANNTraining\test\';
%FileNames = {'MimicDB.txt', 'Challenge2009.txt', 'Challenge2010.txt', 'Challenge2015.txt', 'Mimic2DB.txt', 'Mimic2WDBMatched.txt', 'Mimic2WDB.txt'};
PhysioSetStat = [];
if(isa(FileNames, 'char'))
    numFiles = 1;
    FileNames = {FileNames};
else
    numFiles = length(FileNames);
end
for i = 1:numFiles
    filepath = fullfile(PathName, FileNames{i});
    fprintf(' ========= Processing Record Set from database: %s ========\n\n', FileNames{i}(1:end-4));
    mimicobj = Mimic();
    mimicobj.setFileListName(filepath);
    recSetStat = mimicobj.getRecordSetStat();
    assignin('base', [FileNames{i}(1:end-4), '_recSetStat'], recSetStat);
    save([FileNames{i}(1:end-4), '_recSetStat.mat'], 'recSetStat');
    PhysioSetStat = [PhysioSetStat; recSetStat];
end
assignin('base', 'PhysioSetStat' , PhysioSetStat);
save('PhysioSetStat.mat', 'PhysioSetStat');

% nFiles = mimicobj.getNumberOfFiles();
% fileSize = 0;
% totalLengthHours = 0;
% minLength = 0;
% maxLength = 0;
% %channel_desc = [];
% 
% for i = 1:nFiles
%     [siginfo, fs] = mimicobj.getRecordInfoRemote(i);
%     numSigChannels = length(siginfo);
%     numSamples_Ch = siginfo(1).LengthSamples;          % Assume all channels are the same as channel 1
%     numHours = numSamples_Ch / (fs(1)*60*60);          % Assume sample frequencies are the same
%     if(i == 1)
%         minLength =  numHours;
%         maxLength = numHours;
%     else
%         if(numHours < minLength)
%             minLength = numHours;
%         end
%         if(numHours > maxLength)
%             maxLength = numHours;
%         end
%     end
%     numBytes_Sig = 2;
%     recordSize = numSigChannels * numSamples_Ch * numBytes_Sig;
%     fileSize = fileSize + recordSize/(1000 *1000 * 1000); % in GB
%     totalLengthHours = totalLengthHours + numHours;
% end
% 
% recSetStat = [fileSize, totalLengthHours, minLength, maxLength]; 
% 
% 
% end