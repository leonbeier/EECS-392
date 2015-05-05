%close all;
img = imread('mario.jpg');

blue_key = 100;
red_key = 210;

img_ycc = rgb2ycbcr(img);
y = img_ycc(:, :, 1);
cb = img_ycc(:, :, 2);
cr = img_ycc(:, :, 3);

figure();
subplot(2,2,1); imshow(img); title('Original');
subplot(2,2,2); imshow(y); title('Luma');
subplot(2,2,3); imshow(cb); title('Chroma B');
subplot(2,2,4); imshow(cr); title('Chroma R');

bw = zeros(size(y));
bw(cb >= (blue_key - 5) & cb <= (blue_key + 5) & ... 
    cr >= (red_key - 5) & cr <= (red_key + 5)) = 1;

figure(); imshow(bw); title('Result');

f = fopen('filter_input.txt', 'w');
fprintf(f, '%d\n%d\n', size(y));
fprintf(f, '%d\n%d\n%d\n', [y(1:end); cb(1:end); cr(1:end)]);
fclose(f); 