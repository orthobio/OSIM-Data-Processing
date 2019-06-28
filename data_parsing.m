function [F,M] = data_parsing(data,referenceFrame)

if strcmp(referenceFrame,'Center of Resistance')
    index = 173:length(data(1,:));
elseif strcmp(referenceFrame, 'Bracket')
    index = 89:172;
elseif strcmp(referenceFrame, 'Load Cell')
    index = 5:88;
end


data = data(:,index);
ind = ~isnan(data(:,1));
data = data(ind,:);

Fx = data(:,1:14);
Fy = data(:,15:28);
Fz = data(:,29:42);

for i = 2:length(Fz(:,1))
    if Fz(i,1) == Fz(i-1,1)
        repIndex = i;
    end
end

realIndx = [1:repIndex-1,repIndex+1:length(Fz(:,1))];
Fx = Fx(realIndx,:);
Fy = Fy(realIndx,:);
Fz = Fz(realIndx,:);

F(:,:,1) = Fx;
F(:,:,2) = Fy;
F(:,:,3) = Fz;

Mx = data(:,43:56);
My = data(:,57:70);
Mz = data(:,71:84);

Mx = Mx(realIndx,:);
My = My(realIndx,:);
Mz = Mz(realIndx,:);

M(:,:,1) = Mx;
M(:,:,2) = My;
M(:,:,3) = Mz;