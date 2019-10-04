function [ Strokes_Num,Attribute,Relation] = Strokes_Recognition( Sketch_Data,Relation_Distance )
%% Sketch_Recognition; 识别该sketch的Attribute和Relation：
Selext_Points_Num_of_Stroke=10;     
% Relation_Distance: 每一笔画与上一笔画的关系阈值：
% 1:start at the beginning of the previous stroke;
% 2:start at the end of the previous stroke;
% 3:start at the middle of the previous stroke;
% 0: the others;
raw_x=Sketch_Data(:,1);
raw_y=Sketch_Data(:,2);
raw_p=Sketch_Data(:,3);
zero_index=find(raw_p==0);
Strokes_Num=length(zero_index);                 % 笔画数
Points_Num_of_Stroke(1)=zero_index(1);          % 第一笔画的点数
for (i=2:Strokes_Num)
    Points_Num_of_Stroke(i)=zero_index(i)-zero_index(i-1);    % 其余笔画的点数
end
% NOTE:笔画点数要注意：绘制的草图中，每一笔画应尽量保证大于2*10+3，保证RNN数据有效；
for j=1:Points_Num_of_Stroke(1)                % 抽取x(1,j), y(1,j)，第1笔画第j个点横、纵坐标
    x_axis(1,j)=raw_x(j);
    y_axis(1,j)=raw_y(j);
end
for i=2:Strokes_Num;                           % 抽取x(i,j), y(i,j) ,i>=2， 表示第i笔画第j个点横、纵坐标
    for j=1:Points_Num_of_Stroke(i)
        x_axis(i,j)=raw_x(zero_index(i-1)+j);
        y_axis(i,j)=raw_y(zero_index(i-1)+j);
    end
end
%  将原始数据(x,y,p)转化为RNN用的数据格式(x,y,stroke_num)
for i=1:Strokes_Num
    %     if (Points_Num_of_Stroke(i)< (Selext_Points_Num_of_Stroke+1))
    %         fprintf('Stroke %d has NOT enough Points Data to Sample\nPlease Draw Again!\n',i);
    %     end
    for j=1:Selext_Points_Num_of_Stroke+1
        x(j,1,i)=x_axis(i,max(1,floor(Points_Num_of_Stroke(i)/(Selext_Points_Num_of_Stroke+1)*j)));       % 隔一点采样，尽可能使得样本能够表征数据特征
        x(j,2,i)=-y_axis(i,max(1,floor(Points_Num_of_Stroke(i)/(Selext_Points_Num_of_Stroke+1)*j)));      % 坐标系转换，Matlab采集为右上坐标系，RNN处理为右下坐标系
    end
end
% 将RNN用的数据格式转化为增量表示
for i=1:Strokes_Num
    for j=1:Selext_Points_Num_of_Stroke
        delta_x(j,1,i)=x(j+1,1,i)-x(j,1,i);
        delta_x(j,2,i)=x(j+1,2,i)-x(j,2,i);
    end
end
% 将向量长度归一化
for i=1:Strokes_Num
    for j=1:Selext_Points_Num_of_Stroke
        total=sqrt(delta_x(j,1,i).^2+delta_x(j,2,i).^2);
        delta_x(j,1,i)=delta_x(j,1,i)/total;
        delta_x(j,2,i)=delta_x(j,2,i)/total;
    end
end
delta_x=min(delta_x,1);     % 防止delta_x=NaN;
% Transform 2D sketch delta_x[Selext_Points_Num_of_Stroke,2,Strokes_Num] to 1D vector x_data[Strokes_Num,2*Selext_Points_Num_of_Stroke]
for i=1:Strokes_Num
    for k=1:2
        for j=1:Selext_Points_Num_of_Stroke
            x_data(i,(k-1)*Selext_Points_Num_of_Stroke+j)=delta_x(j,k,i);
        end
    end
end
%% 计算每一笔画与前一笔画的Relation： 1:start at the beginning of the previous stroke; 2:start at the end of the previous stroke; 3:start at the middle of the previous stroke; 0: the others;
Relation(1)=0;
for i=2:Strokes_Num
    if Distance(x_axis(i,1),y_axis(i,1),x_axis(i-1,1),y_axis(i-1,1))< Relation_Distance
        Relation(i)=1;
    else if Distance(x_axis(i,1),y_axis(i,1),x_axis(i-1,Points_Num_of_Stroke(i-1)),y_axis(i-1,Points_Num_of_Stroke(i-1)))<Relation_Distance
            Relation(i)=2;
        else
            x_middle_of_previous_point=(x_axis(i-1,1)+x_axis(i-1,Points_Num_of_Stroke(i-1)))/2;
            y_middle_of_previous_point=(y_axis(i-1,1)+y_axis(i-1,Points_Num_of_Stroke(i-1)))/2;
            if  Distance(x_axis(i,1),y_axis(i,1),x_middle_of_previous_point,y_middle_of_previous_point)<Relation_Distance
                Relation(i)=3;
            else
                Relation(i)=0;
            end
        end
    end
end

%%  COAD_Dataset：Sketch_Linear_Regression_Model参数： 10点序列，5类笔画：横，竖，撇，捺，圆
W=[ 1.2206557  -0.62640566 -0.96153045  0.0386782   0.32860368;
  0.98032707 -0.68759537 -1.2829942   0.37505838  0.61520416;
  0.9371336  -0.59244853 -1.5080198   0.47321317  0.6901219 ;
  1.0131924  -0.5493702  -1.5877125   0.6772602   0.44663164;
  1.0358329  -0.44794166 -1.5932149   0.9670691   0.03825669;
  1.1527013  -0.31465104 -1.5359793   1.064296   -0.36636275;
  1.3803127  -0.13181163 -1.5465448   1.112884   -0.814839  ;
  1.5329249   0.13168593 -1.6954956   1.1913608  -1.1604774 ;
  1.2096165   0.40435833 -1.8069031   1.1430367  -0.95010823;
  0.5463234   0.3660797  -1.2087119   0.8930899  -0.5967796 ;
 -1.5169619   0.3913402   0.4602425   1.0533276  -0.38794863;
 -1.4436436   0.3802164   0.21277899  0.5532513   0.2973972 ;
 -1.1357746   0.40481186  0.12548852  0.13348885  0.47198346;
 -0.97905886  0.5538354   0.1698079  -0.06901683  0.32443234;
 -1.1630445   0.7024562   0.32947037  0.30557308 -0.17445299;
 -1.1555604   0.81125927  0.49614188  0.5467726  -0.6986102 ;
 -1.0780329   0.9995908   0.52715844  0.5719492  -1.0206639 ;
 -0.8909617   1.2699472   0.3864162   0.43455687 -1.1999583 ;
 -0.5823076   1.5091174   0.09419326 -0.06614671 -0.9548568 ;
 -0.45687684  0.7129687   0.2986329   0.07735505 -0.63208175];
b=[-0.08479031 -0.66072845 -0.01341184 -0.8080321   1.5669633 ];
%% 计算每一个样本的输出，得出判断结果
for j=1:Strokes_Num     % 每一个样本计算其状态及观测输出o
    % 使用Sketch_Linear_Regression_Model: y=softmax(Wx+b)进行样本类型检测：
    o=x_data(j,:)*W+b;
    % 计算softmax函数值，据此选择结果
    p_output=mysoftmax(o);
    Attribute(j) = min(find(p_output==max(p_output)));
end

end

