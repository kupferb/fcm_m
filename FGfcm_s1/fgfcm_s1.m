function [center, U, obj_fcn] = fgfcm_s1(data, cluster_n,rg,options)
% Use a 3*3 window
data1=data;                                 %Preprocess data
data=[];                                    
data=reshape(data1,size(data1,1)*size(data1,2),1);
data2=padmatrix(data1,1);                    %Preprocess data
% for i=2:size(data1,1)+1,
%     for j=2:size(data1,2)+1,
% %         if(i==1 || j==1 ||i==size(data1,1) || j==size(data1,2))
% %             data_mean(i,j)=data1(i,j);
% %             continue;
% %         end
%         data_mean(i-1,j-1)=dm(i,j,data2);
%     end
% end
        
if nargin ~= 2 && nargin ~= 3 && nargin ~=4,
	error('Too many or too few input arguments!');
end
% 
data_n = size(data, 1);  
% in_n = size(data, 2);

% Change the following to set default options
default_options = [2;	% exponent for the partition matrix U
		100;	% max. number of iteration
		1e-5;	% min. amount of improvement
		0;      % info display during iteration 
        3;];	% scale factor

if nargin == 2,
	options = default_options;
    rg=6.0; %control the effects of the neighbors term
elseif nargin==3,
    options = default_options;   
else
	% If "options" is not fully specified, pad it with default values.
	if length(options) < 6,
		tmp = default_options;
		tmp(1:length(options)) = options;
		options = tmp;
	end
	% If some entries of "options" are nan's, replace them with defaults.
	nan_index = find(isnan(options)==1);
	options(nan_index) = default_options(nan_index);
	if options(1) <= 1,
		error('The exponent should be greater than 1!');
	end
end

expo = options(1);		    % Exponent for U
max_iter = options(2);		% Max. iteration
min_impro = options(3);		% Min. improvement
display = options(4);		% Display info or not
rs=options(5);
bitnum=8;                   % 8bit image
gln=2^bitnum;
obj_fcn = zeros(max_iter, 1);	% Array for objective function
lnai=zeros(data_n,1);           % Compute the local neighbor weighted image from original image
rc=[size(data1,1) size(data1,2)];

for i=1:data_n,
    lnwi(i)=round(lnwi_fun(i,data2,rc,rs,rg)*(gln-1));
end                             % Compute the local neighbor weighted image from original image

edges=linspace(0,2^bitnum,2^bitnum+1);      % Compute the histogram of the processed images,8 bit image
[N,~,bin]=histcounts(lnwi,edges);       
N=N';
data_N=(linspace(0,2^bitnum-1,2^bitnum))';% Compute the histogram of the processed images,8 bit image


data_n=size(N,1);
U = fgfcm_init(cluster_n, data_n);			% Initial fuzzy partition
% Main loop
for i = 1:max_iter,
	[U, center, obj_fcn(i)] = stepfgfcm(data_N,N, U, cluster_n,expo);
	if display, 
		fprintf('Iteration count = %d, obj. fcn = %f\n', i, obj_fcn(i));
	end
	% check termination condition
	if i > 1,
		if abs(obj_fcn(i) - obj_fcn(i-1)) < min_impro, break; end,
	end
end

iter_n = i;	% Actual number of iterations 
obj_fcn(iter_n+1:max_iter) = [];
U1=U;
U=[];
U=U1(:,bin);

   

function out=lnwi_fun(i,data2,rc,rs,rg)
 data=reshape(data2,size(data2,1)*size(data2,2),1);
 window=neighbor(rc,i);
 out=mean(data(window));
 
%  sigma=sqrt(sum((data(neigh1)-data(i)).^2)/8);
%  S=lsm(data(i),lc,neigh1,neigh2,rs,rg,data,sigma);
%  out=S'*data(neigh1)/sum(S);

function out=neighbor(rc,i) 
  out=[];
  r=rc(1);
  c=rc(2);
  %c1=floor(i/r)+1;
  r1=mod(i,r);
  if(r1==0),
      r1=r;
      c1=floor(i/r);
  else
      c1=floor(i/r)+1;        
  end
 temp=[-1 1;-1 0;1 -1;1 0;0 1;0 -1;1 1;-1 -1];
 temp(:,1)=temp(:,1)+r1+1;
 temp(:,2)=temp(:,2)+c1+1;
 temp=[temp;r1+1 c1+1];
%  if(r1==1 || c1==1 || r1==r || c1==c),   %Deal with boundary
%  nr=find(temp(:,1)==0 | temp(:,1)==r+1);
%  nc=find(temp(:,2)==0 | temp(:,2)==c+1);
%  rc=union(nc,nr);
%  temp(rc,:)=[];
%  end
 temp(:,2)=temp(:,2)-1;
 out=temp*[1;r+2];
 
 function out=lsm(lcv,lc,neigh1,neigh2,rs,rg,data,sigma)
  neigh2(:,1)=neigh2(:,1)-lc(1);
  neigh2(:,2)=neigh2(:,1)-lc(2);
  if sigma==0,
    p2=1/rg*ones(8,1);
  else
    p2=(data(neigh1)-lcv).^2/(rg*sigma^2);
  end
  out=exp(-((max(abs(neigh2'))/rs)'+p2));

     
     
  