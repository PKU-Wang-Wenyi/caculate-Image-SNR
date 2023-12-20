clear;close all ;
titlemsg='计算图像的信噪比SNR author：Wang Wenyi version：2023.12.20-2,采用噪声均值计算，信号计算结果为原始信号强度减去了噪声均值';
filedir='.\';
img_path_list = dir(strcat(filedir,'*.TIF'));
img_num = length(img_path_list);
fprintf('正在读取的图像为：\n');
if img_num > 0 %有满足条件的图像
    for j = 1:img_num %逐一读取图像
        image_name = img_path_list(j).name;% 图像名
        fprintf('第%d个：%s\n',j,strcat(filedir,image_name));
        aa=imreadstack([filedir,image_name]);
        [nx,ny,nz]=size(aa);
        figure;imshow(aa(:,:,1),[]);
        f = msgbox("请选择不包括信号区域的背景ROI！");
        h = imrect;
        position = getPosition(h);
        close all;delete(f);
        for i=1:nz
            noiseROI(:,:,i)=imcrop(aa(:,:,i),position);
            noisevars(i)=(std2(noiseROI(:,:,i)).^2);
            % noisevars(i)=(mean(noiseROI(:,:,i),"all"));
            %这里计算噪声的功率有两种方法，一种是噪声的方差一种是噪声的均值，根据下面的参考文献选取了第二种，根据需求可以切换输出模式
            %ref:https://mrimaster.com/technique%20SNR.html#:~:text=Calculate%20the%20image%20SNR%20using%20this%20formula%3A%20SNR,by%20the%20standard%20deviation%20value%20in%20the%20background.
        end
        figure;imshow(aa(:,:,1),[]);
        f = msgbox("请选择样本区域最薄的地方！请勿选择含有背景的重叠部分区域！");
        h = imrect;
        positions = getPosition(h);
        close all;delete(f);
        for i=1:nz
            signalROI(:,:,i)=imcrop(aa(:,:,i),positions);
            signalmean(i)=(mean(signalROI(:,:,i),"all"));
            %SNR(i)=real(10*log10(((signalmean(i)-noisevars(i)))/noisevars(i)));
            SNR(i)=real(10*log10(((signalmean(i)-noisevars(i)))/noisevars(i)));
        end
        SNR_mean=mean(SNR);
        signal=mean(signalmean);
        noise=mean(noisevars);
        clear signalROI noiseROI
        fp=fopen([filedir,image_name,'SNRresults.txt'], 'w');
        fprintf(fp,'%3s ', titlemsg);
        fprintf(fp,'\n');
        fprintf(fp,'%3s ', 'averaged SNR is : ',num2str(SNR_mean),' db');fprintf(fp,'\n');
        fprintf(fp,'%3s ', 'averaged signal power is : ',num2str(signal-noise),' ADU');fprintf(fp,'\n');
        fprintf(fp,'%3s ', 'averaged noise power is : ',num2str(noise),' ADU');fprintf(fp,'\n');

        for i=1:nz
            fprintf(fp,'%3s ', 'No. ',num2str(i),' SNR is : ',num2str(SNR(i)),' db');fprintf(fp,'\n');
            fprintf(fp,'%3s ', 'No. ',num2str(i),' signal power is : ',num2str(signalmean(i)-noisevars(i)),' ADU');fprintf(fp,'\n');
            fprintf(fp,'%3s ', 'No. ',num2str(i),' noise power is : ',num2str(noisevars(i)),' ADU');fprintf(fp,'\n');
        end
        fclose all;
    end
end

function f=imreadstack(imname)
info = imfinfo(imname);
num_images = numel(info);
f=zeros(info(1).Height,info(1).Width,num_images);

for k = 1:num_images
    f(:,:,k) =imread(imname, k);
end
end