function [recSetStat] = loadBatchRecordfile()
global mimicobj

mimicobj = Mimic();

[FileName,PathName,~] = uigetfile({'*.txt;*.bat'}); %PathName);
filepath = strcat(PathName,FileName);
mimicobj.setFileListName(filepath);
recSetStat = mimicobj.getRecordSetStat();

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