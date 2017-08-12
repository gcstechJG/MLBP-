%function [TotalCycleNumber] = CounTCycles()
%% Creat a video object
myVideoObj = VideoWriter('Res_PPGABP.avi');
myVideoObj.FrameRate = 1;
myVideoObj.Quality = 50;
open(myVideoObj);

fn = dir('Res571.mat');
load(fn.name);

loops = length(res);
loops = 20;
M(loops) = struct('cdata',[],'colormap',[]);


fc = figure(randi([1000 5000], 1));
set(gcf, 'position',[610   184   956   889]);
for i = 1:loops
    ppg = res(i).ppgCycle;
    abp = res(i).abpCycle;
    gap = abs(res(i).offset);
    
    ax(1) = subplot(211);
    plot(gap+1:gap+length(ppg), ppg), grid on; title(['PPG Cycle : ', num2str(i)]);
    xlabel('Samples (125 sample / sec)');
    xlim([1 gap+length(ppg)]);
    ax(2) = subplot(212);
    plot(abp), grid on; title(['ABP cycles : ', num2str(i)]);
    ylabel('Nlood Pressure (mmHg)');
    xlabel('Samples (125 sample / sec)');
    xlim([1 gap+length(ppg)]);
    %linkaxes(ax,'x');

    drawnow;
    M(i) = getframe(gcf);
end
writeVideo(myVideoObj, M);
close(myVideoObj);
%end
