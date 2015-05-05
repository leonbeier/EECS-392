f = fopen('filter_output.txt');

l = fgetl(f);
rows = str2double(l);

l = fgetl(f);
cols = str2double(l);

bw = zeros(rows, cols);

r = 1;
c = 1;

col = zeros(rows, 1);

while ~feof(f)
   col(r) = str2double(fgetl(f));
   if (r == rows)
       bw(:, c) = col;
       r = 0;
       c = c + 1;
   end
   r = r + 1;
end

imshow(bw);