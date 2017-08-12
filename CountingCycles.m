TotalCycleNumber=0;
fn = dir('Res*.mat');

for i = 1:length(fn)
    load(fn(i).name);
    TotalCycleNumber = TotalCycleNumber + length(res);
end

disp(TotalCycleNumber);