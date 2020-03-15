% bar graph driver

% clearvars
clearvars -except covid allcountries databycountry
close all
clc

%% settings

daysbefore = 3;
day0cases = 250;

% setting important dates
%Italy, France, Spain, USA
minorquarantine = [datenum(2020,3,7);datenum(2020,3,12);datenum(2020,3,10);datenum(2020,3,13)];
quarantinestart = [datenum(2020,3,9);datenum(2020,3,15);datenum(2020,3,15);NaN];

%Note- solid lines correspond to major efforts (Italy/Spain quarantine
%entire country, France closes all public places other than grocery stores)
% Dashed lines are more minor responses (US declares national emergency,
% Italy quarantines Lombardy, spain cancels all events w/ more than 1000
% people

%% pulling data

%data link https://docs.google.com/spreadsheets/d/1avGWWl1J19O_Zm0NGTGy2E-fOG05i4ljRfjl87P7FiA/edit?ts=5e5e9222#gid=0
covid_all = GetGoogleSpreadsheet('1avGWWl1J19O_Zm0NGTGy2E-fOG05i4ljRfjl87P7FiA');
T = cell2table(covid_all(2:end,:),'VariableNames',covid_all(1,:));
writetable(T,'CovidData_Newest.csv')

covid = readcoviddata('CovidData_Newest.csv');
[allcountries,databycountry] = resortdata(covid);

%% organizing bars

countries = {'Italy','France','Spain','US'};
for c = 1:length(countries)
    index = find(strcmpi(allcountries,countries{c}));
    data.cases{c} = databycountry{index}.cases;
    data.dates{c} = databycountry{index}.dates;
    data.day0(c) = find(data.cases{c} >= day0cases,1);
end
cases = [];
legendstr = {};

%figuring out size
maxlen = 0;
for c = 1:length(countries)
    clen = length(data.cases{c}) - data.day0(c) + daysbefore;
    if clen > maxlen
        maxlen = clen;
    end
end
cases = zeros(maxlen,length(countries));

%pulling data into bar graph matrix
for c = 1:length(data.day0)
    cdata = data.cases{c}(data.day0(c)-daysbefore:end);
%     cdates = data.dates{c}(data.day0(c)-5:end);
    cases(1:length(cdata),c) = cdata;
    legendstr{c} = [countries{c},' cases, Day 0 = ',datestr(data.dates{c}(data.day0(c)))];
end
    

%% plotting



fig = figure(); clf
ax = gca;
hold on

colors = [0.125    0.6940    0.1250; 0.8500    0.3250    0.0980; 0.4940    0.1840    0.5560; 0    0.4470    0.7410];

b = bar(ax,-daysbefore:size(cases,1)-1-daysbefore,cases);
for c = 1:size(colors,1)
    b(c).FaceColor = colors(c,:);
end

ylim(ax,[0,22000])

%plotting quarantine dates
ylims = ax.YLim;
offsets = [-0.3:0.2:0.3];
for c = 1:length(countries)
    cminordate = minorquarantine(c) - data.dates{c}(data.day0(c));
    cmajordate = quarantinestart(c) - data.dates{c}(data.day0(c));
    plot(ax,[cminordate,cminordate]+offsets(c),ylims,'color',colors(c,:),'linewidth',1,'linestyle','--')
    plot(ax,[cmajordate,cmajordate]+offsets(c),ylims,'color',colors(c,:),'linewidth',1,'linestyle','-')
end


%% getting decay scales

t = -daysbefore:19;
ft = fittype('a*exp(x./b)');
for c = 1:length(countries)
    cdata = cases(:,c);
    cdata(cdata == 0) = [];
    cdays = (0:length(cdata)-1) - daysbefore;
    cfit = fit(cdays',cdata,'exp1');
%     cfit = fit(cdays',cdata,fittype([num2str(day0cases),'.*exp(b.*x)']));
    decayscale(c) = 1./cfit.b;
    coeff(c) = cfit.a;
end

for c = 1:length(countries)
%     plot(t,coeff(c).*exp(t./decayscale(c)),'color',colors(c,:),'linestyle',':');
    plottext{c} = [countries{c},': \alpha = ',num2str(decayscale(c),'%3.2f')];
end
text(ax,-2,15000,'C = C_oe^{d/\alpha}','fontsize',14)
text(ax,-2,12000,plottext,'fontsize',14)
%population density
%USA- 90 /mi^2
%France- 119 /km^2
%Spain- 
%Italy- 


%% plot formatting
ylabel(ax,'Confirmed COVID-19 Cases')
ylim(ax,ylims)
xlabel(ax,['Days Since Exceeding ',num2str(day0cases),' Cases'])
set(ax,'fontsize',14,'xtick',-2:2:30)
grid on
legend(ax,b,legendstr,'location','northwest')
ax.YAxis.Exponent = 0;

%%
saveas(fig,'COVID19_CountryComparison','png')
