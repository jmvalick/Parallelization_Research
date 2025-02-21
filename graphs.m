close all;

% Read the Excel file into MATLAB
data = readmatrix('results.xlsx');

% Extract horizontal and vertical axis labels
horizontal_axis = data(1, 2:9);  % First row, excluding the first element
vertical_axis = data(2:9, 1);  % First column, excluding the first element

% Extract runtime data
runtime_data_CPU = data(2:9, 2:9); % The rest of the matrix
runtime_data_GPU = data(13:20, 2:9); % The rest of the matrix

% Create a color plot
horiz_label = 'Samples Per Pixel';
vert_label = 'Resolution (Pixels)';

figure;
s = pcolor(horizontal_axis,vertical_axis, runtime_data_CPU);
colorbar("FontSize",15);
colormap hsv;
set(gca,'ColorScale','log');
s.FaceColor = 'interp';
%set(s,'edgecolor','none')
set(gca,'CLim',[0.01 1000]);
ax=gca;
ax.XTick = horizontal_axis(2:2:end);
ax.XTickLabel = string(horizontal_axis(2:2:end));
ax.YTick = vertical_axis(2:2:end);
ax.YTickLabel = string(vertical_axis(2:2:end));
xlabel(horiz_label, "FontSize",15);
ylabel(vert_label, "FontSize",15);
title('CPU Runtime (seconds)', "FontSize",15);

figure;
s = pcolor(horizontal_axis,vertical_axis, runtime_data_GPU);
colorbar("FontSize",15);
colormap hsv;
set(gca,'ColorScale','log');
s.FaceColor = 'interp';
%set(s,'edgecolor','none')
set(gca,'CLim',[0.01 1000]);
ax=gca;
ax.XTick = horizontal_axis(2:2:end);
ax.XTickLabel = string(horizontal_axis(2:2:end));
ax.YTick = vertical_axis(2:2:end);
ax.YTickLabel = string(vertical_axis(2:2:end));
xlabel(horiz_label, "FontSize",15);
ylabel(vert_label, "FontSize",15);
title('GPU Runtime (seconds)', "FontSize",15);


factor = runtime_data_CPU./runtime_data_GPU;

figure;
s = pcolor(horizontal_axis,vertical_axis, factor);
colorbar("FontSize",15);
colormap hsv;
%set(gca,'ColorScale','log');
s.FaceColor = 'interp';
%set(s,'edgecolor','none')
ax=gca;
ax.XTick = horizontal_axis(2:2:end);
ax.XTickLabel = string(horizontal_axis(2:2:end));
ax.YTick = vertical_axis(2:2:end);
ax.YTickLabel = string(vertical_axis(2:2:end));
xlabel(horiz_label, "FontSize",15);
ylabel(vert_label, "FontSize",15);
title('Speedup (CPU Time/GPU Time)', "FontSize",15);