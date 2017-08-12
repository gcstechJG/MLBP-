%clear all;
clear;
clc;
close all;

basepath = 'C:\Users\jugao\Documents\bloodpressureestimationml';

mimicobj = Mimic(); % construct the object of Mimic class
mimicobj.setFileListName(strcat(basepath,'\mimicdb.txt')); % Set record list filename and path

% do this to download records from Physionet WFDB and save to a results.mat file
mimicobj.setTimeBlockSize(60*5); % 5 min blocks from each file
mimicobj.saveDataToMat();

dummy = 1;
