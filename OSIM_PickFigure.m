function out = OSIM_PickFigure()
close all;

f = figure('Position',[50,50,500,500],'Units','Normalized','Name','Pick figures');
p1 = uipanel(f,'Title','','Position',[0.05,0.5,0.45,0.45],'Units','Normalized');
p2 = uipanel(f,'Title','','Position',[0.5,0.5,0.45,0.45],'Units','Normalized');
ok = uicontrol('Parent',f,'Units','normalized','Style','pushbutton',...
    'Position',[0.4 0.25 0.2 0.1],'String','OK','Callback',...
    {@ok_Callback});
 
% h_bok = uicontrol('Parent',f,'Units','normalized','Style','pushbutton',...
%     'Position',[0.1667 0.07 0.25 0.12],'String','Export','Callback',{@ok_Callback});
%  
check(1) = uicontrol(p1,'Style','checkbox','String','Load behaviour over time',...
    'Units','normalized',...
    'Position',[.05 .0 .9 .15]);
set(check(1),'Units','pixels')
sizes = get(check(1),'Position');
ax1 = axes(p1,'Position',[0.15 0.25 0.7 0.7]);
fig1 = openfig(char('13hist.fig'), 'reuse','invisible');
B = copyobj(allchild(get(fig1, 'CurrentAxes')), ax1);
set(ax1,'xtick',[])
set(ax1,'xticklabel',[])
close(fig1)

check(2) = uicontrol(p2,'Style','checkbox','String','Load behaviour across trials',...
    'Units','normalized',...
    'Position',[.05 .0 .9 .15]);
set(check(2),'Units','pixels')
sizes = get(check(2),'Position');
ax2 = axes(p2,'Position',[0.15 0.25 0.7 0.7]);
fig2 = openfig(char('13trials.fig'), 'reuse','invisible');
B = copyobj(allchild(get(fig2, 'CurrentAxes')), ax2);
close(fig2)

uiwait(f)

    function ok_Callback(source, eventdata)
        
        % Check user checked at least one tooth and F/M
        checkFrame = 0;
        for i = 1:2
            checkVal(i) = get(check(i), 'Value');
            if checkVal(i) == 1
                checkFrame = 1;
            end
        end
        
        if checkFrame == 0
            errordlg('Please select at one least export', 'Invalid input');
            return;
        end
        
        out = [checkVal(1) checkVal(2)];
        
        close(f);
    end
end