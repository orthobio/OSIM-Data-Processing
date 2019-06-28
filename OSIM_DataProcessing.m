function OSIM_DataProcessing()

close all

% user picks which figures to plot
plotTypes = OSIM_PickFigure;

% selecting data directory containing Excel files
selpath = uigetdir('','Select data directory');
[d,names] = dataGrabber(selpath);
[refndx,tf] = listdlg('PromptString','Select Excel files','ListString',names,'InitialValue',[1:length(names)]);
if tf == 0
    return
end

% picking what coordinate system to output plots for
d = d(refndx);
refFrames = {'Load Cell','Bracket','Center of Resistance'};
[refIndx,tf] = listdlg('PromptString','Select output reference frames','ListString',refFrames,'InitialValue',1,'SelectionMode','single');
if tf == 0
    return
end

% picking what teeth to output plots for
teethString = {'1-7','1-6','1-5','1-4','1-3','1-2','1-1','2-1','2-2','2-3','2-4','2-5','2-6','2-7'};
[teethIndx,tf] = listdlg('PromptString','Select teeth that you want plot(s) for','ListString',teethString);
if tf == 0
    return
end

% picking what loads to output loads for
coordString = {'F_x','F_y','F_z','M_x','M_y','M_z'};
[coordIndx,tf] = listdlg('PromptString','Select coordinates that you want plot(s) for','ListString',coordString);
if tf == 0
    return
end

fIndx = coordIndx(coordIndx<4);
mIndx = coordIndx(coordIndx>3);

openfig('13hist.fig','invisible');
openfig('13trials.fig','invisible');

% grabbing data from Excel files from selected directory
% loads are structured as: 
% Fx([data within trial] [tooth number] [trial number])

for i = 1:length(d)
    [avgnum,avgtxt] = xlsread(strcat(selpath,'\',d(i).name),2);
    [F,M] = data_parsing(avgnum,refFrames(refIndx));
    
    Fx(:,:,i) = F(:,teethIndx,1);
    Fy(:,:,i) = F(:,teethIndx,2);
    Fz(:,:,i) = F(:,teethIndx,3);
    
    Mx(:,:,i) = M(:,teethIndx,1);
    My(:,:,i) = M(:,teethIndx,2);
    Mz(:,:,i) = M(:,teethIndx,3);
end
poses =avgnum(:,2);
poses = poses(~isnan(poses));
numFrames = max(avgnum(:,4)) + 2;
neFlag = false;
if isnan(avgnum(end,3))
    neFlag = true;
end

F = [];

F{1} = Fx;
F{2} = Fy;
F{3} = Fz;
F{4} = Mx;
F{5} = My;
F{6} = Mz;

% creating and saving history plots
if plotTypes(1)
    figures = OSIM_HistoryPlot(F,teethIndx,refIndx,coordIndx,poses,numFrames,neFlag);
    for j = 1:length(figures)
        set(0, 'CurrentFigure', figures(j))
        h1 = get(gca,'title');
        titleStr = h1.String;
        savefig(figures(j), strcat(selpath,'/',titleStr,'_hist'));
        saveas(figures(j), strcat(selpath,'/',titleStr,'_hist','.tif'));
    end
end

% creating and saving trial plots
if plotTypes(2)
    trial_figures = OSIM_TrialPlot(F,teethIndx,refIndx,coordIndx);
    for j = 1:length(trial_figures)
        set(0, 'CurrentFigure',trial_figures(j))
        h2 = get(gca,'title');
        titleStr = h2.String;
        savefig(trial_figures(j), strcat(selpath,'/',titleStr,'_trials'));
        saveas(trial_figures(j), strcat(selpath,'/',titleStr,'_trials','.tif'));
    end
end

% saving a text file report that summarizes the mean peak loads, standard
% deviation of peak loads, and peak loads for each trial

report = OSIM_ReportGenerator(F,teethIndx,refIndx,coordIndx);

fid = fopen(strcat(selpath,'\','report.txt'),'wt');
fprintf(fid,report);
fclose(fid);

end

function reportString = OSIM_ReportGenerator(F,teethIndx,refIndx,coordIndx)

coordKey = {'F_x','F_y','F_z','M_x','M_y','M_z'};
refKey = {'Load Cell','Bracket','COR'};
toothKey = {'1-7','1-6','1-5','1-4','1-3','1-2','1-1','2-1','2-2','2-3','2-4','2-5','2-6','2-7'};

reportString = '';

for p = (coordIndx)
    for j = 1:length(teethIndx)
        maxF = [];
        if p < 4
            unitStr = 'N';
        else
            unitStr = 'Nmm';
        end
        for i = 1:length(F{p}(end,1,:))
            hold on
            [maxF(i), index] = max(abs(F{p}(:,j,i)));
            maxF(i) = maxF(i) * sign(F{p}(index,j,i));
            
            reportString = [reportString newline toothKey{teethIndx(j)},' trial ',num2str(i) ' has a maximum ', coordKey{p}, ' of '...
            ,num2str(maxF(i)),' ', unitStr,' (',refKey{refIndx},')'];
        end
        stdF = std(maxF);
        reportString = [reportString newline toothKey{teethIndx(j)}, ' has a maximum ', coordKey{p}, ' of '...
            ,num2str(mean(maxF)),'±',num2str(stdF), ' ', unitStr,' (',refKey{refIndx},')'];
    end
end

end

function [d, names] = dataGrabber(selpath)
originDir = pwd;
cd(selpath)
d = dir('*xlsx');
dd = zeros(length(d),1);
[~, reindex] = sort( str2double( regexp( {d.name}, '\d+', 'match', 'once' )));
d = d(reindex) ;

ind = [];
names = strings();

for i = 1:length(d)
    if strcmp(d(i).name(1:2),'~$')==0   %removing backup excel files
        ind = [ind,i];
        names = [names,d(i).name];
    end
end
names = names(2:end);
d = d(ind);
cd(originDir)
end

function figures = OSIM_TrialPlot(F,teethIndx,refIndx,coordIndx)

coordKey = {'F_x','F_y','F_z','M_x','M_y','M_z'};
refKey = {'Load Cell','Bracket','COR'};
toothKey = {'1-7','1-6','1-5','1-4','1-3','1-2','1-1','2-1','2-2','2-3','2-4','2-5','2-6','2-7'};

figNum = 1;
figures(figNum) = figure;

for p = 1:length(coordIndx)
    for j = 1:length(teethIndx)
        clf(figNum);
        for i = 1:length(F{coordIndx(p)}(end,1,:))
            hold on
            [maxF, index] = max(abs(F{coordIndx(p)}(:,j,i)));
            maxF = maxF * sign(F{coordIndx(p)}(index,j,i));
            plot(i,maxF,'ko');
        end
        xlabel('Trial Number')
        if p < 4
            ylabel('Force [N]');
        else 
            ylabel('Moment [Nmm]');
        end
        title([toothKey{teethIndx(j)},' ',coordKey{coordIndx(p)},' in ',refKey{refIndx},' frame']);
        lims = ylim;
        realMin = floor(lims(1));
        realMax = ceil(lims(2));
        ylim([realMin realMax]);
        figures(figNum) = gcf;
        figNum = figNum + 1;
        figure(figNum)
    end
end

end

function figures = OSIM_HistoryPlot(F,teethIndx,refIndx,coordIndx,poses,numKeyframes,neFlag)

xlabel_string = {'N'};

dupIndex = [];

for i = 2:length(poses)
    if poses(i) == poses(i-1)
        dupIndex = [dupIndex, i];
    end
end

poses(dupIndex) = [];
sampsBetween = (length(poses)-numKeyframes)/(numKeyframes-1);
changeIndx = [sampsBetween+1:sampsBetween+1:length(poses)-1];

for i = 1:numKeyframes-2
    xlabel_string = horzcat(xlabel_string, num2str(i));
end

if neFlag
    xlabel_string = horzcat(xlabel_string, 'N');
else
    xlabel_string = horzcat(xlabel_string, num2str(numKeyframes-1));
end

coordKey = {'F_x','F_y','F_z','M_x','M_y','M_z'};
refKey = {'Load Cell','Bracket','COR'};
toothKey = {'1-7','1-6','1-5','1-4','1-3','1-2','1-1','2-1','2-2','2-3','2-4','2-5','2-6','2-7'};
markerSym = {'ks','kd','kx','ko','k+'};

figNum = 1;
figures(figNum) = figure;

for k = 1:length(coordIndx)
    for j = 1:length(teethIndx)
        for i = 1:length(F{coordIndx(k)}(1,:,1))
            meanValue = mean(F{coordIndx(k)}(:,(j),:),3);
            sDeviation = std(F{coordIndx(k)}(:,(j),:),0,3);
        end
        figure(figNum);
        clf(figNum);
        
        errorbar(0:changeIndx(1)-1,meanValue(1:changeIndx(1)),sDeviation(1:changeIndx(1)),char(markerSym(1)))
        hold on
        if length(changeIndx) > 1
            for q = 1:length(changeIndx)-1
                if q == length(changeIndx)-1
                    errorbar(changeIndx(q):changeIndx(q+1),meanValue(changeIndx(q)+1:changeIndx(q+1)+1),sDeviation(changeIndx(q)+1:changeIndx(q+1)+1),char(markerSym(q+1)));
                else
                    errorbar(changeIndx(q):changeIndx(q+1)-1,meanValue(changeIndx(q)+1:changeIndx(q+1)),sDeviation(changeIndx(q)+1:changeIndx(q+1)),char(markerSym(q+1)));
                end
            end
        end
        
        %errorbar(0:length(meanValue)-1,meanValue,sDeviation,'k.');
        xlim([0,length(meanValue)-1]);
        xticks([0,0.5*(length(meanValue)-1),length(meanValue)-1]);
        xticklabels(xlabel_string);
        xlabel('Keyframe')
        ylabel('Force [N]');
        title([toothKey{teethIndx(j)},' ',coordKey{coordIndx(k)},' in ',refKey{refIndx},' frame']);
        lims = ylim;
        realMin = floor(lims(1));
        realMax = ceil(lims(2));
        ylim([realMin realMax]);
        figures(figNum) = gcf;
        figNum = figNum + 1;
    end
end
end