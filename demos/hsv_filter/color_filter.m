img = imread('mario.jpg');
figure(); imshow(img);

[rows, cols, depth] = size(img);

img_hsv = rgb2hsv(img);
hue = img_hsv(:, :, 1);
sat = img_hsv(:, :, 2);
val = img_hsv(:, :, 3);

%figure(); imshow(hue);
%figure(); imshow(sat);
%figure(); imshow(val);

h = zeros(rows, cols);
s = h;
v = h;

h(hue < .10 | hue > .95) = 1; % red
%h(hue > 0.55 & hue < 0.70) = 1; % blue
s(sat > 0.3 & sat < 0.9) = 1;
v(val > 0.4 & val < 0.9) = 1;

%figure(); imshow(h);
%figure(); imshow(s);
%figure(); imshow(v);

bw = h & s & v;
figure(); imshow(bw);